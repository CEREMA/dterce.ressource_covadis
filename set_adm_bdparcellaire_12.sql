CREATE OR REPLACE FUNCTION w_adl_delegue.set_adm_bdparcellaire_12(source_schema text)
  RETURNS void AS
$BODY$
 
/*
[ADMIN - BDPARCELLAIRE] - Mise en place des taches d'administration pour l'ensemble des départements de la BDParcellaire® de l'IGN classée dans un répertoire ad'hoc :

Taches réalisées :
- pas le nommage COVADIS car réalisé lors du script d'import,
- Mise en place des contraintes (2 dimensions, EPSG2154, Géométrie type),
- Création des index attributaires
- Création de l'index géométrique et du cluster sur celui-ci
- Commentaires sur les tables et sur les champs.

Tables concernées :
- n_arrondissement_bdp_ddd_aaaa --> Arrondissement municipal
- n_batiment_bdp_ddd_aaaa --> Bâtiment
- n_commune_bdp_ddd_aaaa --> Commune
- n_divcad_bdp_ddd_aaaa --> Division Cadastrale
- n_localisant_bdp_ddd_aaaa --> Localisant
- n_parcelle_bdp_ddd_aaaa --> Parcelle cadastrale

amélioration à faire : option nommage COVADIS en paramètre

dernière MAJ : 28/08/2018
*/

DECLARE
  r record; 		---- enregistrements retournés dans une requete
  object text;		---- objets retournés dans une requete
  req text;		---- requête à passer	
BEGIN


---- A. Optimisation de la base
---- A.1 Suppression du champs gid créée et de la séquence correspondante
FOR object IN
	SELECT tablename::text from pg_tables where (schemaname LIKE source_schema AND 
	(tablename LIKE 'n_batiment_%' OR tablename LIKE 'n_commune_%' OR tablename LIKE 'n_divcad_%' OR tablename LIKE 'n_localisant_%' OR tablename LIKE 'n_parcelle_%' OR tablename LIKE 'n_arrondissement_%' ))
	LOOP 
		req := '
		ALTER TABLE ' || source_schema || '.' || object || ' DROP COLUMN IF EXISTS gid;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP; 
 
---- A.2 Ajout des contraintes :
---- Contraintes sur le type de géométrie et index spatiaux
-- 2D
FOR r IN SELECT tablename, schemaname from pg_tables where (schemaname LIKE $1)
LOOP 
	EXECUTE('ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_dims_geom CHECK (ST_NDims(geom)=2);');
END LOOP; 

-- Lambert93 (2154)
FOR r IN SELECT tablename, schemaname from pg_tables where (schemaname LIKE $1)
LOOP 
	EXECUTE('ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)=2154);');
END LOOP;

-- 'MULTIPOLYGON'
FOR r IN SELECT tablename, schemaname from pg_tables where (schemaname LIKE $1) AND (tablename LIKE 'n_arrondissement_%' OR tablename LIKE 'n_batiment_%' OR tablename LIKE 'n_commune_%' OR tablename LIKE 'n_divcad_%' OR tablename LIKE 'n_parcelle_%' OR tablename LIKE 'n_arrondissement_%')
LOOP 
	EXECUTE('ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text OR geom IS NULL);');
END LOOP;

-- 'POINT'
FOR r IN SELECT tablename, schemaname from pg_tables where (schemaname LIKE $1) AND tablename LIKE 'n_localisant_%'
LOOP 
	EXECUTE('ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POINT''::text OR geom IS NULL);');
END LOOP;

---- A.3 Ajout des index spatiaux
    FOR object IN SELECT tablename FROM pg_tables WHERE schemaname = source_schema -- AND tablename NOT LIKE 'n_bdc_%'-- and other conditions, if needed
    LOOP
        req := '
	CREATE INDEX ' || object || '_geom_gist ON ' || source_schema || '.' || object || ' USING gist (geom) TABLESPACE index;
        ALTER TABLE ' || source_schema || '.' || object || ' CLUSTER ON ' || object || '_geom_gist;
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
    END LOOP;

---- A.4 Ajout des index attributaires
---- A.4.0 Arrondissement
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_arrondisement_%' ORDER by table_name
  LOOP
	        req := '
	        CREATE INDEX ' || object || '_code_arr_idx ON ' || source_schema || '.' || object || ' USING btree (code_arr) TABLESPACE index;
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- A.4.1 Batiment
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_batiment_%' ORDER by table_name
  LOOP
	        req := '
	        CREATE INDEX ' || object || '_type_idx ON ' || source_schema || '.' || object || ' USING btree (type) TABLESPACE index;
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- A.4.2 Commune
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_commune_%' ORDER by table_name
  LOOP
	        req := '
	        CREATE INDEX ' || object || '_code_insee_idx ON ' || source_schema || '.' || object || ' USING btree (code_insee) TABLESPACE index;
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- A.4.3 DivCad
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_divcad_%' ORDER by table_name
  LOOP
	        req := '
	        CREATE INDEX ' || object || '_feuille_idx ON ' || source_schema || '.' || object || ' USING btree (feuille) TABLESPACE index;
	        CREATE INDEX ' || object || '_section_idx ON ' || source_schema || '.' || object || ' USING btree (section) TABLESPACE index;
	        CREATE INDEX ' || object || '_code_com_idx ON ' || source_schema || '.' || object || ' USING btree (code_com) TABLESPACE index;
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- A.4.4 Localisant
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_localisant_%' ORDER by table_name
  LOOP
	        req := '
	        CREATE INDEX ' || object || '_numero_idx ON ' || source_schema || '.' || object || ' USING btree (numero) TABLESPACE index;
	        CREATE INDEX ' || object || '_feuille_idx ON ' || source_schema || '.' || object || ' USING btree (feuille) TABLESPACE index;
	        CREATE INDEX ' || object || '_section_idx ON ' || source_schema || '.' || object || ' USING btree (section) TABLESPACE index;
	        CREATE INDEX ' || object || '_code_com_idx ON ' || source_schema || '.' || object || ' USING btree (code_com) TABLESPACE index;
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- A.4.5 Parcelle = localisant mais mis à part si besoin de modifier
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_parcelle_%' ORDER by table_name
  LOOP
	        req := '
	        CREATE INDEX ' || object || '_numero_idx ON ' || source_schema || '.' || object || ' USING btree (numero) TABLESPACE index;
	        CREATE INDEX ' || object || '_feuille_idx ON ' || source_schema || '.' || object || ' USING btree (feuille) TABLESPACE index;
	        CREATE INDEX ' || object || '_section_idx ON ' || source_schema || '.' || object || ' USING btree (section) TABLESPACE index;
	        CREATE INDEX ' || object || '_code_com_idx ON ' || source_schema || '.' || object || ' USING btree (code_com) TABLESPACE index;
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
  END LOOP;

---- B. COMMENTAIRES DES TABLES
---- B.0 Arrondissement
FOR r IN 
	SELECT table_name, substr(table_name, 23, 2)::text as depart, substr(table_name, 26, 4)::text as millesim
	FROM information_schema.TABLES
	WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_arrondissement_%' ORDER by table_name
	LOOP 
		req := '
		COMMENT ON TABLE ' || source_schema || '.' || r.table_name || ' IS ''Arrondissements municipaux de la BDPARCELLAIRE® pour le millésime ' || r.millesim || ' et le département ' ||  r.depart || '.'';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- B.1 Batiment
FOR r IN 
	SELECT table_name, substr(table_name, 17, 2)::text as depart, substr(table_name, 20, 4)::text as millesim
	FROM information_schema.TABLES
	WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_batiment_%' ORDER by table_name
	LOOP 
		req := '
		COMMENT ON TABLE ' || source_schema || '.' || r.table_name || ' IS ''Bâtiments de la BDPARCELLAIRE® pour le millésime ' || r.millesim || ' et le département ' ||  r.depart || '.'';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- B.2 Commune
FOR r IN 
	SELECT table_name, substr(table_name, 16, 2)::text as depart, substr(table_name, 19, 4)::text as millesim
	FROM information_schema.TABLES
	WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_commune_%' ORDER by table_name
	LOOP 
		req := '
		COMMENT ON TABLE ' || source_schema || '.' || r.table_name || ' IS ''Communes de la BDPARCELLAIRE® pour le millésime ' || r.millesim || ' et le département ' ||  r.depart || '.'';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
	
---- B.3 DivCad
FOR r IN 
	SELECT table_name, substr(table_name, 15, 2)::text as depart, substr(table_name, 18, 4)::text as millesim
	FROM information_schema.TABLES
	WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_divcad_%' ORDER by table_name
	LOOP 
		req := '
		COMMENT ON TABLE ' || source_schema || '.' || r.table_name || ' IS ''Divisions cadastrales de la BDPARCELLAIRE® pour le millésime ' || r.millesim || ' et le département ' ||  r.depart || '.'';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- B.4 Localisant
FOR r IN 
	SELECT table_name, substr(table_name, 19, 2)::text as depart, substr(table_name, 22, 4)::text as millesim
	FROM information_schema.TABLES
	WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_localisant_%' ORDER by table_name
	LOOP 
		req := '
		COMMENT ON TABLE ' || source_schema || '.' || r.table_name || ' IS ''Localisants de la BDPARCELLAIRE® pour le millésime ' || r.millesim || ' et le département ' ||  r.depart || '.'';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- B.5 Parcelle
FOR r IN 
	SELECT table_name, substr(table_name, 17, 2)::text as depart, substr(table_name, 20, 4)::text as millesim
	FROM information_schema.TABLES
	WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_parcelle_%' ORDER by table_name
	LOOP 
		req := '
		COMMENT ON TABLE ' || source_schema || '.' || r.table_name || ' IS ''Parcelles de la de la BDPARCELLAIRE® pour le millésime ' || r.millesim || ' et le département ' ||  r.depart || '.'';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- C. COMMENTAIRES DES ATTRIBUTS
---- C.0 Arrondissement
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_arrondissement_%' ORDER by table_name
  LOOP
	        req := '
	        COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_insee IS ''Code INSEE commune'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.nom_arr IS '' Nom de l’arrondissement (exemple : Paris 1er arrondissement )'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_arr IS ''Code arrondissement'';
	        COMMENT ON COLUMN ' || source_schema || '.' || object || '.geom IS ''Géométrie en multipolygones et Lambert93'';
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;
	
---- C.1 Batiment
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_batiment_%' ORDER by table_name
  LOOP
	        req := '
	        COMMENT ON COLUMN ' || source_schema || '.' || object || '.type IS ''Type du bâtiment'';
	        COMMENT ON COLUMN ' || source_schema || '.' || object || '.geom IS ''Géométrie en multipolygones et Lambert93'';
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- C.2 Commune
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_commune_%' ORDER by table_name
  LOOP
		req := '
	        COMMENT ON COLUMN ' || source_schema || '.' || object || '.nom_com IS ''Nom de la commune'';
	        COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_dep IS ''Code du département'';
	        COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_insee IS ''Numéro INSEE de la commune'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.geom IS ''Géométrie en multipolygones et Lambert93'';
	        ';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- C.3 DivCad
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_divcad_%' ORDER by table_name
  LOOP
		req := '
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.feuille IS ''Numéro de la feuille cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.section IS ''Numéro de la section cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_dep IS ''Code du département'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.nom_com IS ''Nom de la commune'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_com IS ''Code de la commune'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.com_abs IS ''Ancien code de la commune en cas de fusion de communes'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.echelle IS ''Dénominateur de l’échelle principale du plan cadastral'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.edition IS ''Numéro d’édition de la division cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_arr IS ''Code de l’arrondissement'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.geom IS ''Géométrie en multipolygones et Lambert93'';
		';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- C.4 Localisant
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_localisant_%' ORDER by table_name
  LOOP
		req := '
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.numero IS ''Numéro de la parcelle cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.feuille IS ''Numéro de la feuille cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.section IS ''Numéro de la section cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_dep IS ''Code du département'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.nom_com IS ''Nom de la commune'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_com IS ''Code de la commune'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.com_abs IS ''Ancien code de la commune en cas de fusion de communes'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_arr IS ''Code de l’arrondissement'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.geom IS ''Géométrie en Point et Lambert93'';
		';
	        EXECUTE(req);
		RAISE NOTICE '%', req;
    END LOOP;

---- C.5 Parcelle
  FOR object IN
    SELECT table_name::text FROM information_schema.TABLES WHERE table_schema = source_schema and table_type='BASE TABLE' AND table_name LIKE 'n_parcelle_%' ORDER by table_name
  LOOP
		req := '
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.numero IS ''Numéro de la parcelle cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.feuille IS ''Numéro de la feuille cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.section IS ''Numéro de la section cadastrale'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_dep IS ''Code du département'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.nom_com IS ''Nom de la commune'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_com IS ''Code de la commune'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.com_abs IS ''Ancien code de la commune en cas de fusion de communes'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.code_arr IS ''Code de l’arrondissement'';
		COMMENT ON COLUMN ' || source_schema || '.' || object || '.geom IS ''Géométrie en multipolygones et Lambert93'';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
  END LOOP;

---- D. Ouverture des droits

---- E. VACUUM FULL sur toutes les tables du schéma
---- Impossible dans une fonction
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMENT ON FUNCTION w_adl_delegue.set_adm_bdparcellaire_12(text) IS '[ADMIN - BDPARCELLAIRE] - Mise en place des taches d''administration pour l''ensemble des départements de la BDParcellaire® version 1.2 de l''IGN classée dans un répertoire ad''hoc :

Taches réalisées :
- pas le nommage COVADIS car réalisé lors du script d''import,
- Mise en place des contraintes (2 dimensions, EPSG2154, Géométrie type),
- Création des index attributaires
- Création de l''index géométrique et du cluster sur celui-ci
- Commentaires sur les tables et sur les champs.

Tables concernées :
- n_arrondissement_bdp_ddd_aaaa --> Arrondissement municipal
- n_batiment_bdp_ddd_aaaa --> Bâtiment
- n_commune_bdp_ddd_aaaa --> Commune
- n_divcad_bdp_ddd_aaaa --> Division Cadastrale
- n_localisant_bdp_ddd_aaaa --> Localisant
- n_parcelle_bdp_ddd_aaaa --> Parcelle cadastrale

amélioration à faire : option nommage COVADIS en paramètre

dernière MAJ : 28/08/2018';
