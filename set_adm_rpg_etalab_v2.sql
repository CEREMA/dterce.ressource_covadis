CREATE OR REPLACE FUNCTION r_rpg.set_adm_rpg_etalab_v2(
	nom_schema character varying,
	emprise character,
	millesime character)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$/*
[ADMIN - RPG V2 ETALAB] - Administration d'un millesime du RPG Etalab une fois son import réalisé et les couches mises à la COVADIS

Taches réalisées :
B Optimisation de base sur l'ensemble des fichiers
B.1 Verification du nom du champs géométrie si un seul champs géométrique dans la table
B.2 Suppression des champs inutiles et des séquences correspondantes
champs gid (shp2pgsql) / champs ogc_fid (ogr2ogr) / id_0 (glisser/déplacer de QGIS)
B.3 Correction des erreurs sur le nouveau champs
selon cette méthode : http://www.geoinformations.developpement-durable.gouv.fr/verification-et-corrections-des-geometries-a3522.html
B.4 Optimisation de la table : Ajout des contraintes sur le nouveau champs géomètrie: 
B.5 Ajout des index spatiaux et cluster
B.6 Ajout des index attributaires non existants

C. Travail à la Table
C.1 n_ilots_anonymes_ddd_aaaa
C.2 n_parcelles_graphiques_ddd_aaaa
---- pour chaque table : 
C.x.1 Clé primaire :
C.x.2 Commentaires Table
C.x.3 Commentaires colonnes

amélioration à faire :
---- A - Renomage des tables : Vérifier si le nom est conforme COVADIS, si non, le renommer

dernière MAJ : 09/02/2019
*/
declare

object text;							-- Liste des objets pour executer une boucle
attribut text;							-- Liste des attributs de la table
req text;								-- contenu de la requête à passer
nom_table character varying; 			-- nom de la table en text

begin

---- A - Renomage des tables :
---- Vérifier si le nom est bon, si non, le renommer

---- B. Optimisation de base sur l'ensemble des fichiers
 for object in select
	tablename::text
from
	pg_tables
where
	(schemaname like nom_schema)
	and (
		tablename = 'n_parcelles_graphiques_' || emprise || '_' || millesime
		OR tablename = 'n_ilots_anonymes_' || emprise || '_' || millesime
	)
	loop

---- B.1 Verification du nom du champs géométrie si un seul champs géométrique dans la table
	SELECT f_geometry_column FROM public.geometry_columns WHERE f_table_schema =nom_schema AND f_table_name = object AND (
		select count(f_geometry_column) FROM public.geometry_columns WHERE f_table_schema =nom_schema AND f_table_name = object
		) = 1
	INTO attribut;
		IF attribut = 'geom'
		THEN
			req := '
				La table ' || nom_schema || '.' || object || ' à un nom de géométrie conforme
			';
		RAISE NOTICE '%', req;
		ELSE
			req :='
				ALTER TABLE ' || nom_schema || '.' || object || ' RENAME ' || attribut  || ' TO geom;

			 ';
			RAISE NOTICE '%', req;
			EXECUTE(req);
		END IF;
	
---- B.2 Suppression des champs inutiles et des séquences correspondantes
---- champs gid (shp2pgsql) / champs ogc_fid (ogr2ogr) / id_0 (glisser/déplacer de QGIS)
	req := '
				ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS gid;
				ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS ogc_fid;
				ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS id_0;
				ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS id; ---- pas de champs id dans ce référentiel
				';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- B.3 Correction des erreurs sur le nouveau champs
---- selon cette méthode : http://www.geoinformations.developpement-durable.gouv.fr/verification-et-corrections-des-geometries-a3522.html
	req := '
				UPDATE ' || nom_schema || '.' || object || ' SET geom=
					CASE 
						WHEN GeometryType(geom) = ''POLYGON'' 		OR GeometryType(geom) = ''MULTIPOLYGON'' THEN
								ST_Multi(ST_Simplify(ST_Multi(ST_CollectionExtract(ST_ForceCollection(ST_MakeValid(geom)),3)),0))
						WHEN GeometryType(geom) = ''LINESTRING'' 	OR GeometryType(geom) = ''MULTILINESTRING'' THEN
								ST_Multi(ST_Simplify(ST_Multi(ST_CollectionExtract(ST_ForceCollection(ST_MakeValid(geom)),2)),0))
						WHEN GeometryType(geom) = ''POINT'' 		OR GeometryType(geom) = ''MULTIPOINT'' THEN
								ST_Multi(ST_Simplify(ST_Multi(ST_CollectionExtract(ST_ForceCollection(ST_MakeValid(geom)),1)),0))
						ELSE ST_MakeValid(geom)
					END
				WHERE NOT ST_Isvalid(geom);
				';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- B.4 Optimisation de la table
---- Ajout des contraintes sur le nouveau champs géomètrie: 
	req := '
				ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_dims_geom CHECK (ST_NDims(geom)=2);
				ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)=2154);
				ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text OR geom IS NULL);
				';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- B.5 Ajout des index spatiaux et cluster
	req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || object || '_geom_gist;
			CREATE INDEX ' || object || '_geom_gist ON ' || nom_schema || '.' || object || ' USING gist (geom) TABLESPACE index;
		    ALTER TABLE ' || nom_schema || '.' || object || ' CLUSTER ON ' || object || '_geom_gist;
			';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- B.6 Ajout des index attributaires non existants
	FOR attribut IN
		SELECT attnum
			FROM pg_class as c, pg_attribute as a, pg_namespace as n
			WHERE n.nspname = nom_schema
				AND c.relname = object
				AND a.attrelid = c.oid
				AND n.oid = c.relnamespace
				AND attnum > 0
				AND relhasindex IS FALSE
			ORDER BY attnum
	LOOP
			req := '
				CREATE INDEX ' || object || '_' || attribut || '_idx ON ' ||nom_schema|| '.' || object || ' USING btree (' || attribut || ') TABLESPACE index;
			';
			RAISE NOTICE '%', req;
			EXECUTE(req);
	END LOOP;
				
END LOOP;

---- C. Travail à la Table
----------------------------------------
---- C.1 n_ilots_anonymes_ddd_aaaa
----------------------------------------
	nom_table := 'n_ilots_anonymes_' || emprise || '_' || millesime;
---- C.1.1 Clé primaire :
		req := '
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' 
    				ADD CONSTRAINT ' || nom_table || '_id_ilot_pkey PRIMARY KEY (id_ilot);
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
---- C.1.2 Commentaires Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Ilôts anonymes du Registre Parcellaire Graphiques de ' || millesime || '.
Ces surfaces déclarées suivent la notion d’îlot de culture, qui correspond à un groupe de parcelles contiguës, cultivées par le même agriculteur.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- C.1.3 Commentaires colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id_ilot IS ''Identifiant unique de l’îlot.
L’ID_ILOT est conservé d’une édition à l’autre du RPG pour les éditions postérieures à 2015 lorsque la géométrie de l’îlot reste identique.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.geom IS ''Champs géometrique en Lambert93'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);

----------------------------------------------
---- C.2 n_parcelles_graphiques_ddd_aaaa ----
----------------------------------------------
	nom_table := 'n_parcelles_graphiques_' || emprise || '_' || millesime;
---- C.2.1 clé primaire
		req := '
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || 'id_parcel_pkey PRIMARY KEY (id_parcel);
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
---- C.2.2 Commentaires Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Parcelles graphiques anonymes du Registre Parcellaire Graphiques de ' || millesime || '.

Une parcelle graphique est la représentation surfacique d’une parcelle déclarée par un agriculteur (dans le cadre de la PAC)
.Commune de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- C.2.3 Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id_parcel IS ''Identifiant de la parcelle.
L’ID_PARCEL est conservé d’une édition à l’autre du RPG pour les éditions postérieures à 2015 lorsque la géométrie de la parcelle n’est pas modifiée.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.surf_parc IS ''Surface en hectares à deux décimales de la parcelle cultivée.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_cultu IS ''Code culture principale.
Les valeurs sont présentées avec leur signification en Annexe A (Exemple : BTH).'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_group IS ''Code groupe de la culture principale.
Les valeurs sont présentées avec leur signification, ainsi que leur correspondance avec les codes cultures des cultures principales, en Annexe A.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.culture_d1 IS ''Code culture dérobée 1.
Code culture  dérobée  (culture intercalée  entre  2  moissons  de  culture principale) sur la parcelle.
L’attribut n’est rempli que s’il existe une culture dérobée sur la parcelle.
Dans ce cas, les valeurs sont présentées avec leur signification en Annexe B(Exemple : DVN), sinon l’attribut reste vide.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.culture_d2 IS ''Code culture dérobée 2.
Code culture  dérobée  (culture intercalée  entre  2  moissons  de  culture principale) sur la parcelle.
L’attribut n’est rempli que s’il existe une culture dérobée sur la parcelle.
Dans ce cas, les valeurs sont présentées avec leur signification en Annexe B(Exemple : DVN), sinon l’attribut reste vide.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.geom IS ''Champs géometrique en Lambert93'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);

Return current_time;
END;
$BODY$;

ALTER FUNCTION r_rpg.set_adm_rpg_etalab_v2(character varying, character, character)
    OWNER TO postgres;

COMMENT ON FUNCTION r_rpg.set_adm_rpg_etalab_v2(character varying, character, character)
    IS '[ADMIN - RPG V2 ETALAB] - Administration d''un millesime du RPG Etalab une fois son import réalisé et les couches mises à la COVADIS

B Optimisation de base sur l''ensemble des fichiers
B.1 Verification du nom du champs géométrie si un seul champs géométrique dans la table
B.2 Suppression des champs inutiles et des séquences correspondantes
champs gid (shp2pgsql) / champs ogc_fid (ogr2ogr) / id_0 (glisser/déplacer de QGIS)
B.3 Correction des erreurs sur le nouveau champs
selon cette méthode : http://www.geoinformations.developpement-durable.gouv.fr/verification-et-corrections-des-geometries-a3522.html
B.4 Optimisation de la table : Ajout des contraintes sur le nouveau champs géomètrie: 
B.5 Ajout des index spatiaux et cluster
B.6 Ajout des index attributaires non existants

C. Travail à la Table
C.1 n_ilots_anonymes_ddd_aaaa
C.2 n_parcelles_graphiques_ddd_aaaa
---- pour chaque table : 
C.x.1 Clé primaire :
C.x.2 Commentaire Table
C.x.3 Commentaire colonnes

amélioration à faire :
---- A - Renomage des tables :
---- Vérifier si le nom est bon, si non, le renommer

dernière MAJ : 09/02/2019';
