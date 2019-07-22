-- FUNCTION: w_adl_delegue.set_admin_parcellaire_express_10(boolean, character varying, character varying, integer)

-- DROP FUNCTION w_adl_delegue.set_admin_parcellaire_express_10(boolean, character varying, character varying, integer);

CREATE OR REPLACE FUNCTION w_adl_delegue.set_admin_parcellaire_express_10(
	covadis boolean DEFAULT false,
	emprise character varying DEFAULT NULL::character varying,
	millesime character varying DEFAULT NULL::character varying,
	projection integer DEFAULT 2154)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$/*
[ADMIN - BDTOPO] - Administration d´un millesime du PARCELLAIRE EXPRESS V1 une fois son import réalisé

Taches réalisées :
---- A. Déplacement et Renomage des tables
---- B. Optimisation des tables non géographiques
---- B.1 Suppression du champs gid créée et de la séquence correspondante
---- B.2 Ajout de la clef primaire
---- B.3 Ajout des index attributaires non existants
---- C. Optimisation de toutes les tables
---- C.1 Suppression du champs gid créée et de la séquence correspondante
---- C.2 Vérification du nom du champs géométrique
---- C.3 Correction des erreurs sur la géométrie
---- C.4 Ajout des contraintes
---- C.4.1 Ajout des contraintes sur le champs géométrie
---- C.4.2 CHECK (geometrytype(geom)
---- C.5 Ajout de la clef primaire
---- C.5.1 Suppression de l´ancienne si existante
---- C.5.2 Création de la clé primaire selon IGN
---- C.6 Ajout des index spatiaux
---- C.7 Ajout des index attributaires non existants

---- Les commentaires sont renvoyés à une autre fonction

Tables concernées :
	arrondissement
	batiment
	borne_limite_propriete
	borne_parcelle
	commune
	feuille
	localisant
	parcelle
	subdivision_fiscale

amélioration à faire :
---- A Create Schema : verification que le schéma n'existe pas et le crééer
---- C.5.2 Ajout de la clef primaire sauf si doublon d?identifiant notamment n_troncon_cours_eau_bdt
erreur : 
ALTER TABLE r_bdtopo_2018.n_toponymie_bati_bdt_000_2018 ADD CONSTRAINT n_toponymie_bati_bdt_000_2018_pkey PRIMARY KEY;
Sur la fonction en cours de travail : Détail :Key (cleabs_de_l_objet)=(CONSSURF0000002000088919) is duplicated..

dernière MAJ : 22/07/2019
*/

declare
nom_schema 					character varying;		-- Schéma du référentiel en text
nom_table 					character varying;		-- nom de la table en text
req 						text;
veriftable 					character varying;
tb_toutestables				character varying[];	-- Toutes les tables
nb_toutestables 			integer;				-- Nombre de tables --> normalement XX
attribut 					character varying; 		-- Liste des attributs de la table
typegeometrie 				text; 					-- "GeometryType" de la table

BEGIN
IF covadis is true
	THEN
		nom_schema:='r_parcellaire_express_' || millesime;
	ELSE
		nom_schema:='public';
END IF;

---- A. Déplacement et Renomage des tables
IF covadis is false
	THEN
		req := '
			CREATE SCHEMA ' || nom_schema || ';
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
		
		FOR i_table IN 1..nb_toutestables LOOP
			nom_table:=tb_toutestables[i_table];
			SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename = nom_table INTO veriftable;
			IF LEFT(veriftable,length (nom_table)) = nom_table
			then
			req := '
				ALTER TABLE public.' || nom_table || ' RENAME TO n_' || nom_table || '_pepci_' || emprise || '_' || millesime || ';
				ALTER TABLE public.n_' || nom_table || '_pepci_' || emprise || '_' || millesime || ' SET SCHEMA ' || nom_schema || ';	
			';
			RAISE NOTICE '%', req;
			EXECUTE(req);

			ELSE
			req :='La table ' || nom_schema || '.' || nom_table || ' n est pas présente';
			RAISE NOTICE '%', req;

			END IF;
		END LOOP; 
	ELSE
		req := 'Le schéma ' || nom_schema || ' existe déjà et les tables sont déjà renomées !';
		RAISE NOTICE '%', req;
	END IF;

---- B. Optimisation des tables non géographiques
---- Référencement des tables à traiter
tb_toutestables := array['borne_parcelle'];
nb_toutestables := array_length(tb_toutestables, 1);
FOR i_table IN 1..nb_toutestables LOOP
	nom_table:='n_' || tb_toutestables[i_table] || '_pepci_' || emprise || '_' || millesime;
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = nom_table INTO veriftable;
	IF LEFT(veriftable,length (nom_table)) = nom_table
	then
---- B.1 Suppression du champs gid créée et de la séquence correspondante
	req := '
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS gid;
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS ogc_fid;
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS id_0;
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
---- B.2 Ajout de la clef primaire
---- B.2.1 Suppression de l'ancienne si existante
		select t1.conname from pg_constraint as t1, pg_class as t2
		where t2.relname = nom_table and t1.contype = 'p' and t1.conrelid = t2.oid
		into attribut;
		IF attribut is NULL
		THEN
			req := '
				La table ' || nom_schema || '.' || nom_table || ' n´a pas de clé primaire.
			';
		RAISE NOTICE '%', req;
		ELSE
			req :='
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT ' || attribut  || ';
			 ';
			RAISE NOTICE '%', req;
			EXECUTE(req);
		END IF;

---- B.2.2 Création de la clé primaire selon IGN
			select left(nom_table,10) into attribut;
			IF attribut = 'n_commune_'
			then
				req := '
					--ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_pkey PRIMARY KEY (code_insee);
					SELECT version();
					';		
			else
				IF attribut = 'n_localisa' OR attribut = 'n_parcelle' --OR attribut = 'n_subdivis'
				then
					req := '
						--ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_pkey PRIMARY KEY (idu);
						SELECT version();
						';
				else
					req := 'SELECT version();';
				end if;	
			end if;
			RAISE NOTICE '%', req;
			EXECUTE(req);
---- B.3 Ajout des index attributaires non existants
			FOR attribut IN
				SELECT COLUMN_NAME
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_NAME = nom_table
					AND COLUMN_NAME != 'geom' AND COLUMN_NAME != 'the_geom'
			LOOP
					req := '
						DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || attribut || '_idx;
						CREATE INDEX ' || nom_table || '_' || attribut || '_idx ON ' || nom_schema || '.' || nom_table || ' USING brin (' || attribut || ') TABLESPACE index;
					';
					RAISE NOTICE '%', req;
					EXECUTE(req);
			END LOOP;				
---- B.99 Fin de la boucle
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n est pas présente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 

---- C. Optimisation de toutes les tables
---- Référencement des tables à traiter
tb_toutestables := array['arrondissement'];
--DEBUG tb_toutestables := array[
--	'arrondissement',
--	'batiment',
--	'borne_limite_propriete',
--  'borne_parcelle'
--	'commune',
--	'feuille',
--	'localisant',
--	'parcelle',
--	'subdivision_fiscale'
--		];
nb_toutestables := array_length(tb_toutestables, 1);
FOR i_table IN 1..nb_toutestables LOOP
	nom_table:='n_' || tb_toutestables[i_table] || '_pepci_' || emprise || '_' || millesime;
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = nom_table INTO veriftable;
	IF LEFT(veriftable,length (nom_table)) = nom_table
	then
---- C.1 Suppression du champs gid créée et de la séquence correspondante
	req := '
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS gid;
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS ogc_fid;
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS id_0;
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
---- C.2 Vérification du nom du champs géométrique
		SELECT f_geometry_column FROM public.geometry_columns WHERE f_table_schema = nom_schema AND f_table_name = nom_table AND (
		select count(f_geometry_column) FROM public.geometry_columns WHERE f_table_schema = nom_schema AND f_table_name = nom_table
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
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' RENAME ' || attribut  || ' TO geom;
			 ';
			RAISE NOTICE '%', req;
			EXECUTE(req);
		END IF;
---- C.3 Correction des erreurs sur la géométrie
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
---- C.4 Ajout des contraintes
---- C.4.1 Ajout des contraintes sur le champs géométrie
	req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_dims_geom;
		ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_dims_geom CHECK (ST_NDims(geom)=2);
		ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_srid_geom;
		ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)= ' || projection || ');
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- C.4.2 CHECK (geometrytype(geom)
---- C.4.2.1 Création de la table pour lister les géométries disponible
	req := '
		CREATE TABLE public.a_supprimer AS (
			SELECT GeometryType(geom) AS geomtype
			FROM ' || nom_schema || '.' || nom_table || ' group by geomtype
		);
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);

---- C.4.2.2 CHECK (geometrytype(geom)
	SELECT type FROM public.geometry_columns WHERE f_table_schema = nom_schema AND f_table_name = nom_table INTO attribut;
		IF attribut = 'GEOMETRY' then SELECT geomtype FROM public.a_supprimer LIMIT 1 INTO typegeometrie;
					IF 	typegeometrie = 'POLYGON' 			THEN req := '
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POLYGON''::text);-- OR geom IS NULL);
							';
					ELSEIF typegeometrie = 'MULTIPOLYGON' 	THEN req := '
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text);-- OR geom IS NULL);
							';
					ELSEIF typegeometrie = 'LINESTRING' 		THEN req := '
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''LINESTRING''::text);-- OR geom IS NULL);
							';
					ELSEIF typegeometrie = 'MULTILINESTRING' 	THEN req := '
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTILINESTRING''::text);-- OR geom IS NULL);
							';
					ELSEIF typegeometrie = 'POINT' 		THEN req := '
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POINT''::text);-- OR geom IS NULL);
							';
					ELSEIF typegeometrie = 'MULTIPOINT' 		THEN req := '
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
								ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOINT''::text);-- OR geom IS NULL);
							';
					else req := 'La valeur attribut est <<' || attribut || '>> et la valeur typegeometrie est <<' || typegeometrie || '>> ';
				END IF;	
			ELSIF attribut = 'POLYGON' 			THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POLYGON''::text);-- OR geom IS NULL);
					';
			ELSIF attribut = 'MULTIPOLYGON' 	THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text);-- OR geom IS NULL);
					';
			ELSIF attribut = 'LINESTRING' 		THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''LINESTRING''::text);-- OR geom IS NULL);
					';
			ELSIF attribut = 'MULTILINESTRING' 	THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTILINESTRING''::text);-- OR geom IS NULL);
					';
			ELSIF attribut = 'POINT' 		THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POINT''::text);-- OR geom IS NULL);
					';
			ELSIF attribut = 'MULTIPOINT' 		THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOINT''::text);-- OR geom IS NULL);
					';
		else req := 'La valeur attribut est <<' || attribut || '>> ';
		END IF;
		RAISE NOTICE '%', req;
		EXECUTE(req);
---- C.4.2.3
		req := '
			DROP TABLE public.a_supprimer;
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
---- C.5 Ajout de la clef primaire
---- C.5.1 Suppression de l'ancienne si existante
		select t1.conname from pg_constraint as t1, pg_class as t2
		where t2.relname = nom_table and t1.contype = 'p' and t1.conrelid = t2.oid
		into attribut;
		IF attribut is NULL
		THEN
			req := '
				La table ' || nom_schema || '.' || nom_table || ' n´a pas de clé primaire.
			';
		RAISE NOTICE '%', req;
		ELSE
			req :='
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT ' || attribut  || ';
			 ';
			RAISE NOTICE '%', req;
			EXECUTE(req);
		END IF;

---- C.5.2 Création de la clé primaire selon IGN
			select left(nom_table,10) into attribut;
			IF attribut = 'n_commune_'
			then
				req := '
					--ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_pkey PRIMARY KEY (code_insee);
					SELECT version();
					';		
			else
				IF attribut = 'n_localisa' OR attribut = 'n_parcelle' --OR attribut = 'n_subdivis'
				then
					req := '
						--ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_pkey PRIMARY KEY (idu);
						SELECT version();
						';
				else
					req := 'SELECT version();';
				end if;	
			end if;
			RAISE NOTICE '%', req;
			EXECUTE(req);
---- C.6 Ajout des index spatiaux
			req := '
				DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_geom_gist;
				CREATE INDEX ' || nom_table || '_geom_gist ON ' || nom_schema || '.' || nom_table || ' USING gist (geom) TABLESPACE index;
        		ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' CLUSTER ON ' || nom_table || '_geom_gist;
			';
			RAISE NOTICE '%', req;
			EXECUTE(req);
---- C.7 Ajout des index attributaires non existants
			FOR attribut IN
				SELECT COLUMN_NAME
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_NAME = nom_table
					AND COLUMN_NAME != 'geom' AND COLUMN_NAME != 'the_geom'
			LOOP
					req := '
						DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || attribut || '_idx;
						CREATE INDEX ' || nom_table || '_' || attribut || '_idx ON ' || nom_schema || '.' || nom_table || ' USING brin (' || attribut || ') TABLESPACE index;
					';
					RAISE NOTICE '%', req;
					EXECUTE(req);
			END LOOP;				
---- C.99 Fin de la boucle
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n est pas présente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 	

RETURN current_time;
END; 
$BODY$;

ALTER FUNCTION w_adl_delegue.set_admin_parcellaire_express_10(boolean, character varying, character varying, integer)
    OWNER TO postgres;

COMMENT ON FUNCTION w_adl_delegue.set_admin_parcellaire_express_10(boolean, character varying, character varying, integer)
    IS '[ADMIN - PARCELLAIRE EXPRESS V1] - Administration d´un millesime du PARCELLAIRE EXPRESS V1 une fois son import réalisé

Taches réalisées :
---- A. Déplacement et Renomage des tables
---- B. Optimisation des tables non géographiques
---- B.1 Suppression du champs gid créée et de la séquence correspondante
---- B.2 Ajout de la clef primaire
---- B.3 Ajout des index attributaires non existants
---- C. Optimisation de toutes les tables
---- C.1 Suppression du champs gid créée et de la séquence correspondante
---- C.2 Vérification du nom du champs géométrique
---- C.3 Correction des erreurs sur la géométrie
---- C.4 Ajout des contraintes
---- C.4.1 Ajout des contraintes sur le champs géométrie
---- C.4.2 CHECK (geometrytype(geom)
---- C.5 Ajout de la clef primaire
---- C.5.1 Suppression de l´ancienne si existante
---- C.5.2 Création de la clé primaire selon IGN
---- C.6 Ajout des index spatiaux
---- C.7 Ajout des index attributaires non existants

---- Les commentaires sont renvoyés à une autre fonction

Tables concernées :
	arrondissement
	batiment
	borne_limite_propriete
	borne_parcelle
	commune
	feuille
	localisant
	parcelle
	subdivision_fiscale

amélioration à faire :
---- A Create Schema : verification que le schéma n''existe pas et le crééer
---- C.5.2 Ajout de la clef primaire sauf si doublon d?identifiant notamment n_troncon_cours_eau_bdt
erreur : 
ALTER TABLE r_bdtopo_2018.n_toponymie_bati_bdt_000_2018 ADD CONSTRAINT n_toponymie_bati_bdt_000_2018_pkey PRIMARY KEY;
Sur la fonction en cours de travail : Détail :Key (cleabs_de_l_objet)=(CONSSURF0000002000088919) is duplicated..

dernière MAJ : 22/07/2019';
