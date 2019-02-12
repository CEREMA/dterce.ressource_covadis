CREATE OR REPLACE FUNCTION r_admin_express.set_adm_adminexpress_2(
    nom_schema character varying,
    emprise character,
    millesime character)
  RETURNS text AS
$BODY$/*
[ADMIN - ADMIN_EXPRESS V2] - Mise en place des taches d'administration pour un millesime d'ADMIN EXPRESS® de l'IGN selon le millesime et l'emprise :

Taches réalisées :
A - Re-nommage des tables

B. Optimisation de base sur l'ensemble des fichiers
B.1 Vérification du nom du champs géométrie
B.2 Suppression des champs inutiles
B.3 Correction des erreurs sur la géométrie
B.4 Contraintes géométriques de la table
B.5 Ajout des index spatiaux et cluster
B.6 Ajout des index attributaires non existants
B.7 clés primaires sur le champs id

C. Travail à la Table
C.1 n_adm_exp_arrondissement_dpt_ddd_aaaa
C.2 n_adm_exp_chef_lieu_ddd_aaaa
C.3 n_adm_exp_commune_ddd_aaaa
C.4 n_adm_exp_departement_ddd_aaaa
C.5 n_adm_exp_epci_ddd_aaaa
C.6 n_adm_exp_region_ddd_aaaa


Tables concernées :
amélioration à faire : option nommage COG en paramètre

dernière MAJ : 11/02/2019
*/
DECLARE
---- déclaration variables  --
object 		text; 			-- Liste des objets pour executer une boucle
req		text;			-- requête à passer	
attribut 	text; 			-- Liste des attributs de la table

BEGIN
---- A - Re-nommage des tables :
---- A.1 - Nom non conforme :
req :='
	ALTER TABLE IF EXISTS ' || nom_schema || '."ARRONDISSEMENT_DEPARTEMENTAL" RENAME TO n_adm_exp_arrondissement_dpt_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '.arrondissement_depertemental RENAME TO n_adm_exp_arrondissement_dpt_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '."CHEF_LIEU" RENAME TO n_adm_exp_chef_lieu_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '.chef_lieu RENAME TO n_adm_exp_chef_lieu_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '."COMMUNE" RENAME TO n_adm_exp_commune_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '.commune RENAME TO n_adm_exp_commune_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '."DEPARTEMENT" RENAME TO n_adm_exp_departement_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '.departement RENAME TO n_adm_exp_departement_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '."EPCI" RENAME TO n_adm_exp_epci_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '.epci RENAME TO n_adm_exp_epci_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '."REGION" RENAME TO n_adm_exp_region_'  || emprise || '_'  || millesime  || ';
	ALTER TABLE IF EXISTS ' || nom_schema || '.region RENAME TO n_adm_exp_region_'  || emprise || '_'  || millesime  || ';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- B. Optimisation de base sur l'ensemble des fichiers
FOR object IN 
SELECT tablename::text from pg_tables where (schemaname LIKE nom_schema) AND left(tablename,10) = 'n_adm_exp_' AND right(tablename,9) = '_' || emprise || '_' || millesime
LOOP

---- B.1 Vérification du nom du champs géométrie si un seul champs géométrique dans la table
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
				';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- B.3 Correction des erreurs sur la géométrie
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

---- B.4 Contraintes géométriques de la table
---- B.4.1 Ajout des contraintes sur le champs géométrie: 
	req := '
				ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_dims_geom CHECK (ST_NDims(geom)=2);
				ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)=2154);
				';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- B.4.2 CHECK (geometrytype(geom) :
	SELECT type FROM public.geometry_columns WHERE f_table_schema = nom_schema AND f_table_name = object INTO attribut;
		IF 	attribut = 'POLYGON' 			THEN 	req := 'ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POLYGON''::text OR geom IS NULL);';
			ELSEIF attribut = 'MULTIPOLYGON' 	THEN 	req := 'ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text OR geom IS NULL);';
			ELSEIF attribut = 'LINESTRING' 		THEN 	req := 'ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''LINESTRING''::text OR geom IS NULL);';
			ELSEIF attribut = 'MULTILINESTRING' 	THEN 	req := 'ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTILINESTRING''::text OR geom IS NULL);';
			ELSEIF attribut = 'POINT' 		THEN	req := 'ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POINT''::text OR geom IS NULL);';
			ELSEIF attribut = 'MULTIPOINT' 		THEN 	req := 'ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOINT''::text OR geom IS NULL);';
			ELSE 						req := 'SELECT current_time;';
		END IF;
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
				DROP INDEX IF EXISTS ' || nom_schema || '.' || object || '_' || attribut || '_idx;
				CREATE INDEX ' || object || '_' || attribut || '_idx ON ' || nom_schema || '.' || object || ' USING btree (' || attribut || ') TABLESPACE index;
			';
			RAISE NOTICE '%', req;
			EXECUTE(req);
	END LOOP;

---- B.7 clés primaires sur le champs id
			
	req := '
			ALTER TABLE ' || nom_schema || '.' || object || ' DROP CONSTRAINT IF EXISTS ' || object || '_pkey;
			ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT ' || object || '_id_pkey PRIMARY KEY (id);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

END LOOP;

---- C. Travail à la Table
----------------------------------------
---- C.1 n_adm_exp_arrondissement_dpt_ddd_aaaa
----------------------------------------
---- Métadonnées :
req := '
-- Table
	COMMENT ON TABLE '||nom_schema||'.n_adm_exp_arrondissement_dpt_'|| emprise ||'_'|| millesime ||' IS ''Arrondissement départementaux de la base ADMIN Express de l’IGN de '|| millesime ||''';
-- Colonnes
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_arrondissement_dpt_'|| emprise ||'_'|| millesime ||'.id IS ''Identifiant unique de l’arrondissement'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_arrondissement_dpt_'|| emprise ||'_'|| millesime ||'.insee_arr IS ''Numéro INSEE de l’arrondissement'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_arrondissement_dpt_'|| emprise ||'_'|| millesime ||'.insee_dep IS ''Numéro INSEE du département auquel appartient l’arrondissement'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_arrondissement_dpt_'|| emprise ||'_'|| millesime ||'.insee_reg IS ''Numéro INSEE de la région contenant l’arrondissement'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_arrondissement_dpt_'|| emprise ||'_'|| millesime ||'.geom IS ''Surfacique 2D'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

----------------------------------------
---- C.2 n_adm_exp_chef_lieu_ddd_aaaa
----------------------------------------
---- Métadonnées :
req := '
-- Table
	COMMENT ON TABLE '||nom_schema||'.n_adm_exp_chef_lieu_'|| emprise ||'_'|| millesime ||' IS ''Chef-lieu de la base ADMIN Express de l’IGN de '|| millesime ||' :
  
Centre de  la  zone  d’habitat  dans  laquelle  se  trouve  la  mairie  de  la  commune.  
Dans certains cas, le chef-lieu n’est pas dans la commune.'';
-- Colonnes
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_chef_lieu_'|| emprise ||'_'|| millesime ||'.id IS ''Identifiant unique du chef-lieu de commune'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_chef_lieu_'|| emprise ||'_'|| millesime ||'.nom_chf IS ''Dénomination du chef-lieu de commune, parfois différente de la dénomination de la commune'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_chef_lieu_'|| emprise ||'_'|| millesime ||'.statut IS ''Statut du chef-lieu : Capitale d’état / Préfecture de région / Préfecture / Sous-préfecture / Commune simple'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_chef_lieu_'|| emprise ||'_'|| millesime ||'.insee_com IS ''Numéro INSEE de la commune.
Il s’agit de la valeur de l’attribut INSEE_COM de la commune à se rapporte le chef-lieu'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_chef_lieu_'|| emprise ||'_'|| millesime ||'.geom IS ''Surfacique 2D'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

----------------------------------------
---- C.3 n_adm_exp_commune_ddd_aaaa
----------------------------------------
---- Métadonnées :
req := '
-- Table
	COMMENT ON TABLE '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||' IS ''Commune de la base ADMIN Express de l’IGN de '|| millesime ||' :

	Plus petite subdivision administrative du territoire, administrée par un maire, des adjoints et un conseil municipal'';
-- Colonnes
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.id IS ''Identifiant de la commune'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.nom_com IS ''Nom de la commune'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.nom_com_m IS ''Nom de la commune en majuscules'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.insee_com IS ''Numéro INSEE de la commune'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.statut IS ''Statut administratif'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.population IS ''Population de la commune'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.insee_arr IS ''Numéro INSEE de l’arrondissement'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.nom_dep IS ''Nom du département'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.insee_dep IS ''Numéro INSEE du département'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.nom_reg IS ''Nom de la région'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.insee_reg IS ''Numéro INSEE de la région'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.code_epci IS ''Code de l’EPCI'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_commune_'|| emprise ||'_'|| millesime ||'.geom IS ''Surfacique 2D'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

----------------------------------------
---- C.4 n_adm_exp_departement_ddd_aaaa
----------------------------------------
---- Métadonnées :
req := '
-- Table
	COMMENT ON TABLE '||nom_schema||'.n_adm_exp_departement_'|| emprise ||'_'|| millesime ||'  IS ''Département au sens INSEE de la base ADMIN Express de l’IGN de '|| millesime ||''';
-- Colonnes
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_departement_'|| emprise ||'_'|| millesime ||'.id IS ''Identifiant du département'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_departement_'|| emprise ||'_'|| millesime ||'.nom_dep IS ''Nom du département'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_departement_'|| emprise ||'_'|| millesime ||'.insee_dep IS ''Numéro INSEE du département'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_departement_'|| emprise ||'_'|| millesime ||'.insee_reg IS ''Numéro INSEE de la région'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_departement_'|| emprise ||'_'|| millesime ||'.geom IS ''Surfacique 2D'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

----------------------------------------
---- C.5 n_adm_exp_epci_ddd_aaaa
----------------------------------------
---- Métadonnées :
req := '
-- Table
	COMMENT ON TABLE '||nom_schema||'.n_adm_exp_epci_'|| emprise ||'_'|| millesime ||'  IS ''EPCI de la base ADMIN Express de l’IGN de '|| millesime ||' :
	  Les établissements publics de coopération intercommunale sont  des  
	regroupements   de   communes   ayant   pour   objet   l’élaboration
	de projets communs de développement au sein de périmètres de  solidarité.
	Ils sont soumis à des règles communes, homogènes et comparables à celles
	de collectivités locales'';
-- Colonnes
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_epci_'|| emprise ||'_'|| millesime ||'.id IS ''Identifiant de l’EPCI'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_epci_'|| emprise ||'_'|| millesime ||'.code_epci IS ''Code de l’EPCI'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_epci_'|| emprise ||'_'|| millesime ||'.nom_epci IS ''Nom de l’EPCI'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_epci_'|| emprise ||'_'|| millesime ||'.type_epci IS ''Type de l’EPCI'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_epci_'|| emprise ||'_'|| millesime ||'.geom IS ''Surfacique 2D'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

----------------------------------------
---- C.6 n_adm_exp_region_ddd_aaaa
----------------------------------------
---- Métadonnées :
req := '
-- Table
	COMMENT ON TABLE '||nom_schema||'.n_adm_exp_region_'|| emprise ||'_'|| millesime ||' IS ''Région au sens INSEE de la base ADMIN Express de l’IGN de '|| millesime ||''';
-- Colonnes
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_region_'|| emprise ||'_'|| millesime ||'.id IS ''Identifiant de la région'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_region_'|| emprise ||'_'|| millesime ||'.nom_reg IS ''Nom de la région'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_region_'|| emprise ||'_'|| millesime ||'.insee_reg IS ''Numéro INSEE de la région'';
	COMMENT ON COLUMN '||nom_schema||'.n_adm_exp_region_'|| emprise ||'_'|| millesime ||'.geom IS ''Surfacique 2D'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

RETURN current_time;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION r_admin_express.set_adm_adminexpress_2(character varying, character, character)
  OWNER TO postgres;
COMMENT ON FUNCTION r_admin_express.set_adm_adminexpress_2(character varying, character, character) IS '[ADMIN - ADMIN_EXPRESS V2] - Mise en place des taches d''administration pour un millesime d''ADMIN EXPRESS® de l''IGN selon le millesime et l''emprise :

Taches réalisées :
A - Re-nommage des tables

B. Optimisation de base sur l''ensemble des fichiers
B.1 Vérification du nom du champs géométrie
B.2 Suppression des champs inutiles
B.3 Correction des erreurs sur la géométrie
B.4 Contraintes géométriques de la table
B.5 Ajout des index spatiaux et cluster
B.6 Ajout des index attributaires non existants
B.7 clés primaires sur le champs id

C. Travail à la Table
C.1 n_adm_exp_arrondissement_dpt_ddd_aaaa
C.2 n_adm_exp_chef_lieu_ddd_aaaa
C.3 n_adm_exp_commune_ddd_aaaa
C.4 n_adm_exp_departement_ddd_aaaa
C.5 n_adm_exp_epci_ddd_aaaa
C.6 n_adm_exp_region_ddd_aaaa


Tables concernées :
amélioration à faire : option nommage COG en paramètre

dernière MAJ : 11/02/2019';
