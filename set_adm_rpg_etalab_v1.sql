CREATE OR REPLACE FUNCTION r_rpg.set_adm_rpg_etalab_v1(
	nom_schema character varying,
	emprise character,
	millesime character)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$/*
[ADMIN - RPG V1 ETALAB] - Administration d'un millesime du RPG Etalab une fois son import réalisé et les couches mises à la COVADIS

Taches réalisées :
A. Renomage des tables

B. Optimisation de base sur l'ensemble des fichiers :
B.1 Suppression des champs inutiles et des séquences correspondantes
B.2 Ajout des index attributaires non existants

C. Travail à la Table
C.1 n_ilots_anonymes_ddd_aaaa
C.1.1 Verification du nom du champs géométrie
C.1.2 Correction des erreurs sur le champs géométrique
C.1.3 Optimisation de la table
C.1.4 Ajout des index spatiaux et cluster
C.1.5 Clé primaire sur num_ilot
C.1.6 Commentaires de la Table
C.1.7 Commentaires des colonnes
C.2 n_ilots_anonymes_groupe_culture_ddd_aaaa
C.2.1 Clé primaire sur id
C.2.2 Commentaires de la Table
C.2.3 Commentaires des colonnes

amélioration à faire :
---- A - Renomage des tables : Vérifier si le nom est conforme COVADIS, si non, le renommer

dernière MAJ : 19/03/2019
*/
declare

object text;							-- Liste des objets pour executer une boucle
attribut text;							-- Liste des attributs de la table
req text;								-- contenu de la requête à passer
nom_table character varying; 			-- nom de la table en text

begin

---- A. Renomage des tables :
---- Vérifier si le nom est bon, si non, le renommer
	req := '
			ALTER TABLE ' || nom_schema || '."ILOTS-ANONYMES-GROUPES-CULTURE_' || emprise || '_' || millesime || '"
				RENAME TO n_ilots_anonymes_groupe_culture_' || emprise || '_' || millesime || ';
			ALTER TABLE ' || nom_schema || '.n_ilots_anonymes_groupe_culture_' || emprise || '_' || millesime || '
				RENAME "NUM_ILOT" TO num_ilot;
			ALTER TABLE ' || nom_schema || '.n_ilots_anonymes_groupe_culture_' || emprise || '_' || millesime || '
				RENAME "CODE_GROUPE_CULTURE" TO code_groupe_culture;
			ALTER TABLE ' || nom_schema || '.n_ilots_anonymes_groupe_culture_' || emprise || '_' || millesime || '
				RENAME "SURFACE_GROUPE_CULTURE" TO surface_groupe_culture;
			ALTER TABLE ' || nom_schema || '.n_ilots_anonymes_groupe_culture_' || emprise || '_' || millesime || '
				RENAME "NOM_GROUPE_CULTURE" TO nom_groupe_culture;
					';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- B. Optimisation de base sur l'ensemble des fichiers :
 for object in select
	tablename::text
from
	pg_tables
where
	(schemaname like nom_schema)
	and (
		tablename = 'n_ilots_anonymes_groupe_culture_' || emprise || '_' || millesime
		OR tablename = 'n_ilots_anonymes_' || emprise || '_' || millesime
	)
	loop

---- B.1 Suppression des champs inutiles et des séquences correspondantes
---- champs gid (shp2pgsql) / champs ogc_fid (ogr2ogr) / id_0 (glisser/déplacer de QGIS)
		req := '
					ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS gid;
					ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS ogc_fid;
					ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS id_0;
					ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS id;
					';
		RAISE NOTICE '%', req;
		EXECUTE(req);

---- B.2 Ajout des index attributaires non existants
	FOR attribut IN
		SELECT COLUMN_NAME
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = object
			AND COLUMN_NAME != 'geom' AND COLUMN_NAME != 'the_geom'
	LOOP
			req := '
				DROP INDEX IF EXISTS ' || nom_schema || '.' || object || '_' || attribut || '_idx;
				CREATE INDEX ' || object || '_' || attribut || '_idx ON ' || nom_schema || '.' || object || ' USING btree (' || attribut || ') TABLESPACE index;
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

---- C.1.1 Verification du nom du champs géométrie si un seul champs géométrique dans la table
	SELECT f_geometry_column FROM public.geometry_columns WHERE f_table_schema =nom_schema AND f_table_name = nom_table AND (
		select count(f_geometry_column) FROM public.geometry_columns WHERE f_table_schema =nom_schema AND f_table_name = nom_table
		) = 1
	INTO attribut;
		IF attribut = 'geom'
		THEN
			req := '
				La table ' || nom_schema || '.' || nom_table || ' à un nom de géométrie conforme
			';
		RAISE NOTICE '%', req;
		ELSE
			req :='
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' RENAME ' || attribut  || ' TO geom;

			 ';
			RAISE NOTICE '%', req;
			EXECUTE(req);
		END IF;

---- C.1.2 Correction des erreurs sur le champs géométrique
---- selon cette méthode : http://www.geoinformations.developpement-durable.gouv.fr/verification-et-corrections-des-geometries-a3522.html
	req := '
				UPDATE ' || nom_schema || '.' || nom_table || ' SET geom=
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

---- C.1.3 Optimisation de la table
---- Ajout des contraintes sur le nouveau champs géomètrie: 
	req := '
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_dims_geom;
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_dims_geom CHECK (ST_NDims(geom)=2);
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_srid_geom;
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)=2154);
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text OR geom IS NULL);
				';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- C.1.4 Ajout des index spatiaux et cluster
	req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_geom_gist;
			CREATE INDEX ' || nom_table || '_geom_gist ON ' || nom_schema || '.' || nom_table || ' USING gist (geom) TABLESPACE index;
		    ALTER TABLE ' || nom_schema || '.' || nom_table || ' CLUSTER ON ' || nom_table || '_geom_gist;
			';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- C.1.5 Clé primaire sur num_ilot :
		req := '
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS ' || nom_table || '_num_ilot_pkey;
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_num_ilot_pkey PRIMARY KEY (num_ilot);
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
		
---- C.1.6 Commentaires de la Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Ilôts anonymes du Registre Parcellaire Graphiques de ' || millesime || '.
Ces surfaces déclarées suivent la notion d’îlot de culture, qui correspond à un groupe de parcelles contiguës, cultivées par le même agriculteur.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	
---- C.1.7 Commentaires des colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.num_ilot IS '' Identifiant de l’îlot, unique sur l’ensemble des données, obtenu par la concaténation du numéro de département sur 3 caractères (001, 055, 972, …) et d’un entier séparés par un tiret.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commune IS ''Numéro INSEE de la commune de localisation de l’îlot'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.forme_juri IS ''Forme juridique de l’exploitation selon la nomenclature ASP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.surf_decla IS ''Surface déclarée de l’exploitation en hectares avec deux décimales.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.dep_rattac IS ''Département de la Direction Départementale de l’Agriculture et de la Forêt (DDAF) auprès de laquelle est faite la déclaration Politique Agricole Commune (PAC) de l’exploitation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.surf_graph IS ''Surface de l’îlot en hectares avec deux décimales.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.surf_cultu IS ''Surface du groupe de cultures majoritaire sur l’îlot, en hectares avec deux décimales.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_cultu IS ''Code du groupe de cultures majoritaire sur l’îlot. Chaque code correspond à un nom de groupe de cultures (voir Annexe B).'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_cultu IS ''Nom du groupe de cultures majoritaire sur l’îlot. Chaque nom correspond à un code de groupe de cultures (voir Annexe B).'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.geom IS ''Champs géometrique en Lambert93'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);

------------------------------------------------------
---- C.2 n_ilots_anonymes_groupe_culture_ddd_aaaa ----
------------------------------------------------------
nom_table := 'n_ilots_anonymes_groupe_culture_' || emprise || '_' || millesime;
---- C.2.1 Clé primaire sur id
		req := '
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD COLUMN id serial;
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_id PRIMARY KEY (id);
				CREATE INDEX ' || nom_table || '_id_idx ON ' || nom_schema || '.' || nom_table || ' USING btree (id) TABLESPACE index;
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
	
---- C.2.2 Commentaires de la Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Cultures de l’îlot regroupées du Registre Parcellaire Graphiques de ' || millesime || '.
		Un même îlot peut avoir plusieurs groupes de cultures.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	
---- C.2.3 Commentaires des colonnes
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.num_ilot IS '' Identifiant de l’îlot, unique sur l’ensemble des données, obtenu par la concaténation du numéro de département sur 3 caractères (001, 055, 972, …) et d’un entier séparés par un tiret.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_groupe_culture IS ''Code du groupe de cultures. Chaque code correspond à un nom de groupe de cultures (voir Annexe B).'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.surface_groupe_culture IS ''Surface du groupe de cultures, en hectares avec deux décimales.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.surf_decla IS ''Surface du ????, en hectares avec deux décimales.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_groupe_culture IS ''Nom du groupe de cultures. Chaque nom correspond à un code de groupe de cultures (voir Annexe B).'' 
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);

Return current_time;
END;
$BODY$;

ALTER FUNCTION r_rpg.set_adm_rpg_etalab_v1(character varying, character, character)
    OWNER TO postgres;

COMMENT ON FUNCTION r_rpg.set_adm_rpg_etalab_v1(character varying, character, character)
    IS '
Taches réalisées :
A. Renomage des tables

B. Optimisation de base sur l''ensemble des fichiers :
B.1 Suppression des champs inutiles et des séquences correspondantes
B.2 Ajout des index attributaires non existants

C. Travail à la Table
C.1 n_ilots_anonymes_ddd_aaaa
C.1.1 Verification du nom du champs géométrie
C.1.2 Correction des erreurs sur le champs géométrique
C.1.3 Optimisation de la table
C.1.4 Ajout des index spatiaux et cluster
C.1.5 Clé primaire sur num_ilot
C.1.6 Commentaires de la Table
C.1.7 Commentaires des colonnes
C.2 n_ilots_anonymes_groupe_culture_ddd_aaaa
C.2.1 Clé primaire sur id
C.2.2 Commentaires de la Table
C.2.3 Commentaires des colonnes

amélioration à faire :
---- A - Renomage des tables : Vérifier si le nom est conforme COVADIS, si non, le renommer

dernière MAJ : 19/03/2019';
