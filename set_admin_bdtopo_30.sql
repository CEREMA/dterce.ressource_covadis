--CREATE SCHEMA w_adl_delegue;
--> Finish time	Sat May 18 09:55:41 CEST 2019

CREATE OR REPLACE FUNCTION w_adl_delegue.set_adm_bdtopo_30(
    emprise character varying,
    millesime character varying,
    projection integer DEFAULT 2154)
  RETURNS void AS
$BODY$
/*
[ADMIN - BDTOPO] - Administration d�un millesime de la BDTOPO 30 une fois son import r�alis�

Taches r�alis�es :
---- A. D�placement et Renomage des tables
---- B. Optimisation de toutes les tables
---- B.1 Suppression du champs gid cr��e et de la s�quence correspondante
---- B.2 V�rification du nom du champs g�om�trique
---- B.3 Correction des erreurs sur la g�om�trie
---- B.4 Ajout des contraintes
---- B.4.1 Ajout des contraintes sur le champs g�om�trie
---- B.4.2 CHECK (geometrytype(geom)
---- B.5 Ajout de la clef primaire
---- B.5.1 Suppression de l�ancienne si existante
---- B.5.1 Cr�ation de la cl� primaire selon IGN
---- B.6 Ajout des index spatiaux
---- B.7 Ajout des index attributaires non existants

---- Les commentaires sont renvoy�s � une autre fonction
---- La correction du champs g�om�trique est effectu� par une autre fonction : set_admin_bdtopo_30_option_geom()

Tables concern�es :
	adresse
	aerodrome
	arrondissement
	bassin_versant_topographique
	batiment
	canalisation
	cimetiere
	collectivite_territoriale
	commune
	construction_lineaire	
	construction_ponctuelle	
	construction_surfacique	
	cours_d_eau
	departement	
	detail_hydrographique	
	detail_orographique	
	epci	
	equipement_de_transport	
	lieu_dit_non_habite	
	ligne_electrique	
	limite_terre_mer	
	noeud_hydrographique	
	non_communication	
	parc_ou_reserve	
	piste_d_aerodrome	
	plan_d_eau
	point_du_reseau	
	poste_de_transformation	
	pylone	
	region	
	reservoir	
	route_numerotee_ou_nommee		
	surface_hydrographique	
	terrain_de_sport	
	toponymie_bati	
	toponymie_hydrographie	
	toponymie_lieux_nommes	
	toponymie_services_et_activites	
	toponymie_transport	
	toponymie_zones_reglementees	
	transport_par_cable	
	troncon_de_route	
	troncon_de_voie_ferree	
	troncon_hydrographique	
	voie_ferree_nommee	
	zone_d_activite_ou_d_interet	
	zone_d_estran	
	zone_d_habitation	
	zone_de_vegetation	


am�lioration � faire :
---- B.5.1 Ajout de la clef primaire sauf si doublon d�identifiant notamment n_troncon_cours_eau_bdt
erreur : 
ALTER TABLE r_bdtopo_2018.n_toponymie_bati_bdt_000_2018 ADD CONSTRAINT n_toponymie_bati_bdt_000_2018_pkey PRIMARY KEY;
Sur la fonction en cours de travail : D�tail :Key (cleabs_de_l_objet)=(CONSSURF0000002000088919) is duplicated..

derni�re MAJ : 30/05/2019
*/

declare
nom_schema 					character varying;		-- Sch�ma du r�f�rentiel en text
nom_table 					character varying;		-- nom de la table en text
req 						text;
veriftable 					character varying;
tb_toutestables				character varying[];	-- Toutes les tables
nb_toutestables 			integer;				-- Nombre de tables --> normalement XX
attribut 					character varying; 		-- Liste des attributs de la table
typegeometrie 				character varying; 		-- "GeometryType" de la table

BEGIN
nom_schema:='r_bdtopo_' || millesime;

---- R�f�rencement des tables � traiter
tb_toutestables := array[
	'adresse',
	'aerodrome',
	'arrondissement',
	'bassin_versant_topographique',
	'batiment',
	'canalisation',
	'cimetiere',
	'collectivite_territoriale',
	'commune',
	'construction_lineaire',
	'construction_ponctuelle',
	'construction_surfacique',
	'cours_d_eau',
	'departement',
	'detail_hydrographique',
	'detail_orographique',
	'epci',
	'equipement_de_transport',
	'lieu_dit_non_habite',
	'ligne_electrique',
	'limite_terre_mer',
	'noeud_hydrographique',	
	'non_communication',
	'parc_ou_reserve',
	'piste_d_aerodrome',
	'plan_d_eau',
	'point_du_reseau',
	'poste_de_transformation',
	'pylone',
	'region',
	'reservoir',
	'route_numerotee_ou_nommee',
	'surface_hydrographique',
	'terrain_de_sport',
	'toponymie_bati',
	'toponymie_hydrographie',
	'toponymie_lieux_nommes',
	'toponymie_services_et_activites',
	'toponymie_transport',
	'toponymie_zones_reglementees',
	'transport_par_cable',
	'troncon_de_route',
	'troncon_de_voie_ferree',
	'troncon_hydrographique',
	'voie_ferree_nommee',
	'zone_d_activite_ou_d_interet',
	'zone_d_estran',
	'zone_d_habitation',	
	'zone_de_vegetation'
		];
nb_toutestables := array_length(tb_toutestables, 1);
/*
---- A. D�placement et Renomage des tables
req := '
		CREATE SCHEMA ' || nom_schema || ';
';
EXECUTE(req);
RAISE NOTICE '%', req;

FOR i_table IN 1..nb_toutestables LOOP
	nom_table:=tb_toutestables[i_table];
	SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename = nom_table INTO veriftable;
	IF LEFT(veriftable,length (nom_table)) = nom_table
	then
	req := '
		ALTER TABLE public.' || nom_table || ' RENAME TO n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ';
		ALTER TABLE public.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' SET SCHEMA ' || nom_schema || ';	
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 
*/
---- B. Optimisation de toutes les tables
FOR i_table IN 1..nb_toutestables LOOP
	nom_table:='n_' || tb_toutestables[i_table] || '_bdt_' || emprise || '_' || millesime;
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = nom_table INTO veriftable;
	IF LEFT(veriftable,length (nom_table)) = nom_table
	then
---- B.1 Suppression du champs gid cr��e et de la s�quence correspondante
	req := '
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS gid;
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS ogc_fid;
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP COLUMN IF EXISTS id_0;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
---- B.2 V�rification du nom du champs g�om�trique
		SELECT f_geometry_column FROM public.geometry_columns WHERE f_table_schema = nom_schema AND f_table_name = nom_table AND (
		select count(f_geometry_column) FROM public.geometry_columns WHERE f_table_schema = nom_schema AND f_table_name = nom_table
		) = 1
		INTO attribut;
		IF attribut = 'geom'
		THEN
			req := '
				La table ' || nom_schema || '.' || nom_table || ' � un nom de g�om�trie conforme
			';
		RAISE NOTICE '%', req;
		ELSE
			req :='
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' RENAME ' || attribut  || ' TO geom;
			 ';
			RAISE NOTICE '%', req;
			EXECUTE(req);
		END IF;
---- B.3 Correction des erreurs sur la g�om�trie
---- selon cette m�thode : http://www.geoinformations.developpement-durable.gouv.fr/verification-et-corrections-des-geometries-a3522.html
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
---- B.4 Ajout des contraintes
---- B.4.1 Ajout des contraintes sur le champs g�om�trie
	req := '
		ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_dims_geom;
		ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_dims_geom CHECK (ST_NDims(geom)=2);
		ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_srid_geom;
		ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)=' || projection || ');
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- B.4.2 CHECK (geometrytype(geom)
	SELECT type FROM public.geometry_columns WHERE f_table_schema = nom_schema AND f_table_name = nom_table INTO attribut;
		IF 	attribut = 'POLYGON' 			THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POLYGON''::text);-- OR geom IS NULL);
					';
			ELSEIF attribut = 'MULTIPOLYGON' 	THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text);-- OR geom IS NULL);
					';
			ELSEIF attribut = 'LINESTRING' 		THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''LINESTRING''::text);-- OR geom IS NULL);
					';
			ELSEIF attribut = 'MULTILINESTRING' 	THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTILINESTRING''::text);-- OR geom IS NULL);
					';
			ELSEIF attribut = 'POINT' 		THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POINT''::text);-- OR geom IS NULL);
					';
			ELSEIF attribut = 'MULTIPOINT' 		THEN req := '
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS enforce_geotype_geom;
						ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOINT''::text);-- OR geom IS NULL);
					';
			ELSEIF attribut = 'GEOMETRY' then SELECT GeometryType(geom) AS "GeometryType" FROM r_bdtopo_2018.n_adresse_bdt_000_2018 group by "GeometryType" INTO typegeometrie;
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
					else req := 'La valeur typegeometrie est <<' || typegeometrie || '>> ';
			END IF;
		req := 'La valeur attribut est <<' || attribut || '>> ';
		END IF;
		RAISE NOTICE '%', req;
		EXECUTE(req);
---- B.5 Ajout de la clef primaire
---- B.5.1 Suppression de l'ancienne si existante
		select t1.conname from pg_constraint as t1, pg_class as t2
		where t2.relname = nom_table and t1.contype = 'p' and t1.conrelid = t2.oid
		into attribut;
		IF attribut is NULL
		THEN
			req := '
				La table ' || nom_schema || '.' || nom_table || ' n�a pas de cl� primaire.
			';
		RAISE NOTICE '%', req;
		ELSE
			req :='
				ALTER TABLE ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT ' || attribut  || ';
			 ';
			RAISE NOTICE '%', req;
			EXECUTE(req);
		END IF;
---- B.5.1 Cr�ation de la cl� primaire selon IGN
			select left(nom_table,12) into attribut;
			IF attribut != 'n_toponymie_'
			then
				req := '
					--ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_pkey PRIMARY KEY (cleabs);
					select current_time;
				';		
			else
				req := '
					ALTER TABLE ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_pkey PRIMARY KEY (cleabs_de_l_objet);
				';					
			end if;
			RAISE NOTICE '%', req;
			EXECUTE(req);
---- B.6 Ajout des index spatiaux
			req := '
				DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_geom_gist;
				CREATE INDEX ' || nom_table || '_geom_gist ON ' || nom_schema || '.' || nom_table || ' USING gist (geom) TABLESPACE index;
        		ALTER TABLE ' || nom_schema || '.' || nom_table || ' CLUSTER ON ' || nom_table || '_geom_gist;
			';
			RAISE NOTICE '%', req;
			EXECUTE(req);
---- B.7 Ajout des index attributaires non existants
			FOR attribut IN
				SELECT COLUMN_NAME
					FROM INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_NAME = nom_table
					AND COLUMN_NAME != 'geom' AND COLUMN_NAME != 'the_geom'
			LOOP
					req := '
						DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || attribut || '_idx;
						CREATE INDEX ' || nom_table || '_' || attribut || '_idx ON ' || nom_schema || '.' || nom_table || ' USING btree (' || attribut || ') TABLESPACE index;
					';
					RAISE NOTICE '%', req;
					EXECUTE(req);
			END LOOP;				
---- B.99 Fin de la boucle
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 	
/*

----------------------------
---- B.5 Travail � la Table
----------------------------

---- B.5.A_RESEAU_ROUTIER
---- B.5.A_1 ROUTE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_route_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_route_bdt_')) = 'n_route_bdt_'
	THEN
---- Index
	nom_table := 'n_route_bdt';
	tb_index := array['id',
			'nature',
			'importance',
			'cl_admin',
			'gestion',
			'franchisst',
			'largeur',
			'nb_voies',
			'pos_sol',
			'sens',
			'inseecom_d',
			'inseecom_g',
			'etat'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de voie de communication de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Voie de communication destin�e aux automobiles, aux pi�tons, aux cycles ou aux animaux, homog�ne pour l�ensemble des attributs et des relations qui la concerne.
Le tron�on de route peut �tre rev�tu ou non rev�tu (pas de rev�tement de surface ou rev�tement de surface fortement d�grad�).
Dans le cas d�un tron�on de route rev�tu, on repr�sente uniquement la chauss�e, d�limit�e par les bas-c�t�s ou les trottoirs (cf. Mod�lisation g�om�trique).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.ALIAS_D IS ''D�nomination ancienne ou autre nom voie droite.  Une voie est un ensemble de tron�ons de route associ�s � un m�me nom. Une voie est  identifi�e par son nom dans une commune donn�e.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.ALIAS_G IS ''D�nomination ancienne ou autre nom voie gauche.  Une voie est un ensemble de tron�ons de route associ�s � un m�me nom. Une voie est  identifi�e par son nom dans une commune donn�e.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.BORNEDEB_D IS ''Borne d�but droite.  Num�ro de borne � droite du tron�on en son sommet initial.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.BORNEDEB_G IS ''Borne fin gauche.  Num�ro de borne � gauche du tron�on en son sommet final.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.BORNEFIN_D IS ''Borne droite de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.BORNEFIN_G IS ''Borne fin droite.  Num�ro de borne � droite du tron�on en son sommet final.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CL_ADMIN IS ''Attribut permettant de pr�ciser le statut d''''une route'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CODEPOST_D IS ''Code postal du c�t� droit de la voie  Code postal de la commune � droite du tron�on par rapport � son sens de num�risation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CODEPOST_G IS ''Code postal du c�t� gauche de la voie  Code postal de la commune � gauche du tron�on par rapport � son sens de  num�risation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CODEVOIE_D IS ''Identifiant du cot� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CODEVOIE_G IS ''Identifiant droite.  Identifiant de la voie associ�e au c�t� droit du tron�on.  Identifiant de la voie associ�e au c�t� gauche du tron�on.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.ETAT IS ''Indique si le tron�on est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.FICTIF IS ''Indique la nature fictive ou r�elle du tron�on - V'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.FRANCHISST IS ''Franchissement.  Cet attribut informe sur le niveau de l''''objet par rapport � la surface du sol.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.GESTION IS ''D�finit le gestionnaire administratif d''''une route. Toutes les routes class�es poss�dent un  Gestionnaire.  Il existe diff�rentes cat�gories de routes pour lesquelles le gestionnaire diff�re.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.ID IS ''Cet identifiant est unique. Il est stable d''''une �dition � l''''autre. Il permet aussi d''''�tablir un  lien entre le ponctuel de la classe � ADRESSE � des produits BD ADRESSE� et POINT  ADRESSE�'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.IMPORTANCE IS ''Cet attribut mat�rialise une hi�rarchisation du r�seau routier fond�e, non  pas sur un crit�re administratif, mais sur l''''importance des tron�ons de route pour le trafic  routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.INSEECOM_D IS ''INSEE Commune droite.  Num�ro d''''INSEE de la commune � droite du tron�on par rapport � son sens de  num�risation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.INSEECOM_G IS ''Num�ro INSEE de la commune � droite de la voie  Num�ro d''''INSEE de la commune � gauche du tron�on par rapport � son sens de  num�risation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.IT_EUROP IS ''Itin�raire europ�en.  Num�ro de route europ�enne : une route europ�enne emprunte en g�n�ral le r�seau  autoroutier ou national.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.IT_VERT IS ''Itin�raire vert.  Indique l''''appartenance ou non d''''un tron�on routier au r�seau vert.  Le r�seau vert, compos� de p�les verts et de liaisons vertes, couvre l''''ensemble du  territoire fran�ais.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.LARGEUR IS ''Largeur de chauss�e.  Largeur de chauss�e (d''''accotement � accotement) exprim�e en m�tres.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.MISE_SERV IS ''Date de mise en service.  D�finit la date pr�vue ou la date effective de mise en service d''''un tron�on de route.  Cet attribut n''''est rempli que pour les tron�ons en construction, il est � �NR� dans les autres cas.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NATURE IS ''Attribut permettant de distinguer diff�rentes natures de tron�on de route.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NB_VOIES IS ''Nombre de voies.  Nombre total de voies d''''une route, d''''une rue ou d''''une chauss�e de route � chauss�es s�par�es.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NOM_ITI IS ''Nom de l''''itin�raire ou "Valeur non renseign�e"'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NOM_VOIE_D IS ''Une voie est un ensemble de tron�ons de route associ�s � un m�me nom. Une voie est  identifi�e par son nom dans une commune donn�e.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NOM_VOIE_G IS ''Nom voie � gauche. Le nom de voie est celui qui sert � l''''adressage.  Une voie est un ensemble de tron�ons de route associ�s � un m�me nom. Une voie est  identifi�e par son nom dans une commune donn�e.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NUMERO IS ''Num�ro de la voie (D50,N106�) (NR pour Non renseign�'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.POS_SOL IS ''Position par rapport au sol.  Donne le niveau de l''''objet par rapport � la surface du sol (valeur n�gative pour un objet  souterrain, nulle pour un objet au sol et positive pour un objet en sursol).'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.PREC_ALTI IS ''Pr�cision g�om�trique altim�trique.  Attribut pr�cisant la pr�cision g�om�trique en altim�trie de la donn�e.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.PREC_PLANI IS ''Pr�cision g�om�trique planim�trique.  Attribut pr�cisant la pr�cision g�om�trique en planim�trie de la donn�e.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.SENS IS ''Sens de circulation autoris�e pour les automobiles sur les voies.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.TYP_ADRES IS ''Type d''''adressage.  Renseigne sur le type d''''adressage du tron�on.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.Z_FIN IS ''Altitude finale : c''''est l''''altitude du sommet final du tron�on.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.Z_INI IS ''c''''est l''''altitude du sommet initial du tron�on.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.A_RESEAU_ROUTIER
---- B.5.A_2 CHEMIN
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_chemin_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_chemin_bdt_')) = 'n_chemin_bdt_'
	THEN
---- Index
	nom_table := 'n_chemin_bdt';
	tb_index := array['id',
			'prec_plani',
			'prec_alti',
			'nature',
			'franchisst',
			'nom_iti',
			'pos_sol'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Voie de communication terrestre non ferr�e destin�e aux pi�tons, aux cycles ou aux animaux, de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Voie de communication terrestre non ferr�e destin�e aux pi�tons, aux cycles ou aux animaux, ou route sommairement rev�tue (pas de rev�tement de surface ou rev�tement de surface fortement d�grad�).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_iti IS ''Nom d�itin�raire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.A_RESEAU_ROUTIER
---- B.5.A_3 ROUTE_NOMMEE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_route_nommee_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_route_nommee_bdt_')) = 'n_route_nommee_bdt_'
	THEN
---- Index
	nom_table := 'n_route_nommee_bdt';
	tb_index := array['id',
			'nature',
			'importance',
			'cl_admin',
			'gestion',
			'franchisst',
			'largeur',
			'nb_voies',
			'pos_sol',
			'sens',
			'inseecom_d',
			'inseecom_g',
			'etat'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS '' Portion de voie de communication destin�e aux automobiles, aux pi�tons, qui poss�dent r�ellement un nom de rue de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
1.  Portion de voie de communication destin�e aux automobiles, aux pi�tons, aux cycles ou aux animaux, homog�ne pour l�ensemble des attributs et des relations qui la concerne, et qui poss�dent r�ellement un nom de rue droit ou un nom de rue gauche (d�o� le nom de la classe ROUTE_NOMMEE). 
2.  Le  tron�on  de  route  peut  �tre  rev�tu  ou  non  rev�tu  (pas  de  rev�tement  de surface ou rev�tement de surface fortement d�grad�). Dans le cas d�un tron�on de route rev�tu, on repr�sente uniquement la chauss�e, d�limit�e par les bas-c�t�s ou les trottoirs (cf. Mod�lisation g�om�trique). '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.numero IS ''Num�ro de la voie (D50, N106�)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_g IS ''Nom du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_d IS ''Nom du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.cl_admin IS ''Classement administratif'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.gestion IS ''Gestionnaire de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.mise_serv IS ''Date de mise en service'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_vert IS ''Appartenance � un itin�raire vert'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_europ IS ''Num�ro de l�itin�raire europ�en'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.fictif IS ''Indique la nature fictive ou r�el du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.largeur IS ''Largeur de la chauss�e'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_iti IS ''Nom d�itin�raire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.sens IS ''Sens de circulation de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_g IS ''Num�ro Insee de la commune � gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_d IS ''Num�ro Insee de la commune � droite de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_g IS ''Identifiant du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_d IS ''Identifiant du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.typ_adres IS ''Type d�adressage de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_g IS ''Borne gauche de d�but de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_d IS ''Borne droite de d�but de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_g IS ''Borne gauche de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_d IS ''Borne droite de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.etat IS ''Indique si le tron�on est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_g IS ''Ancien ou autre nom utilis� c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_d IS ''Ancien ou autre nom utilis� c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_g IS ''Code postal du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_d IS ''Code postal du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.A_RESEAU_ROUTIER
---- B.5.A_4 ROUTE_PRIMAIRE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_route_primaire_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_route_primaire_bdt_')) = 'n_route_primaire_bdt_'
	THEN
---- Index
	nom_table := 'n_route_primaire_bdt';
	tb_index := array['id',
			'nature',
			'importance',
			'cl_admin',
			'gestion',
			'franchisst',
			'largeur',
			'nb_voies',
			'pos_sol',
			'sens',
			'inseecom_d',
			'inseecom_g',
			'etat'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de voie de communication primaire destin�e aux automobiles, aux pi�tons ou aux cycles, la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Portion de voie de communication destin�e aux automobiles, aux pi�tons ou aux cycles, homog�ne pour l�ensemble des attributs et des relations qui la concerne. 
Cette  classe  est  un  sous-ensemble  de  la  classe  ROUTE,  et  comprend uniquement les tron�ons de route d�importance 1 ou 2. 
Cela  permet  de  n�utiliser  ou  de  n�afficher  que  le  r�seau  dit  principal, pour des raisons de faciliter de manipulation ou de lisibilit� � l��cran suivant l��chelle.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.numero IS ''Num�ro de la voie (D50, N106�)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_g IS ''Nom du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_d IS ''Nom du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.cl_admin IS ''Classement administratif'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.gestion IS ''Gestionnaire de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.mise_serv IS ''Date de mise en service'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_vert IS ''Appartenance � un itin�raire vert'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_europ IS ''Num�ro de l�itin�raire europ�en'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.fictif IS ''Indique la nature fictive ou r�el du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.largeur IS ''Largeur de la chauss�e'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_iti IS ''Nom d�itin�raire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.sens IS ''Sens de circulation de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_g IS ''Num�ro Insee de la commune � gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_d IS ''Num�ro Insee de la commune � droite de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_g IS ''Identifiant du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_d IS ''Identifiant du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.typ_adres IS ''Type d�adressage de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_g IS ''Borne gauche de d�but de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_d IS ''Borne droite de d�but de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_g IS ''Borne gauche de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_d IS ''Borne droite de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.etat IS ''Indique si le tron�on est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_g IS ''Ancien ou autre nom utilis� c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_d IS ''Ancien ou autre nom utilis� c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_g IS ''Code postal du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_d IS ''Code postal du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.A_RESEAU_ROUTIER
---- B.5.A_5 ROUTE_SECONDAIRE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_route_secondaire_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_route_secondaire_bdt_')) = 'n_route_secondaire_bdt_'
	THEN
---- Index
	nom_table := 'n_route_secondaire_bdt';
	tb_index := array['id',
			'nature',
			'importance',
			'cl_admin',
			'gestion',
			'franchisst',
			'largeur',
			'nb_voies',
			'pos_sol',
			'sens',
			'inseecom_d',
			'inseecom_g',
			'etat'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de voie de communication primaire destin�e aux automobiles, aux pi�tons ou aux cycles, la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Portion de voie de communication destin�e aux automobiles, aux pi�tons ou aux cycles, homog�ne pour l�ensemble des attributs et des relations qui la concerne. 
Cette  classe  est  un  sous-ensemble  de  la  classe  ROUTE,  et  comprend uniquement les tron�ons de route d�importance 1 ou 2. 
Cela  permet  de  n�utiliser  ou  de  n�afficher  que  le  r�seau  dit  principal, pour des raisons de faciliter de manipulation ou de lisibilit� � l��cran suivant l��chelle.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.numero IS ''Num�ro de la voie (D50, N106�)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_g IS ''Nom du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_d IS ''Nom du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.cl_admin IS ''Classement administratif'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.gestion IS ''Gestionnaire de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.mise_serv IS ''Date de mise en service'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_vert IS ''Appartenance � un itin�raire vert'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_europ IS ''Num�ro de l�itin�raire europ�en'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.fictif IS ''Indique la nature fictive ou r�el du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.largeur IS ''Largeur de la chauss�e'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_iti IS ''Nom d�itin�raire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.sens IS ''Sens de circulation de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_g IS ''Num�ro Insee de la commune � gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_d IS ''Num�ro Insee de la commune � droite de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_g IS ''Identifiant du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_d IS ''Identifiant du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.typ_adres IS ''Type d�adressage de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_g IS ''Borne gauche de d�but de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_d IS ''Borne droite de d�but de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_g IS ''Borne gauche de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_d IS ''Borne droite de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.etat IS ''Indique si le tron�on est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_g IS ''Ancien ou autre nom utilis� c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_d IS ''Ancien ou autre nom utilis� c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_g IS ''Code postal du c�t� gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_d IS ''Code postal du c�t� droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.A_RESEAU_ROUTIER
---- B.5.A_6 SURFACE_ROUTE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_surface_route_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_surface_route_bdt_')) = 'n_surface_route_bdt_'
	THEN
---- Index
	nom_table := 'n_surface_route_bdt';
	tb_index := array['id',
			'nature'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Partie de la chauss�e d�une route caract�ris�e par une largeur exceptionnelle de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Zone � trafic non structur�.
S�lection : Toutes les zones rev�tues pour le roulage ou le parcage des automobiles, et faisant plus  de  50 m  de  large  sont  incluses  (environ  �  ha  pour  les  parkings).  Les  zones  rev�tues  de moins de 50 m de large sont exclues (pour les zones de moins de 50 m de large r�serv�es � la circulation automobile, voir classe ROUTE). 
Mod�lisation g�om�trique : Contours de la chauss�e, au sol. La surface peut �tre trou�e.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la surface_route.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_moyen IS ''Altitude moyenne des points composants la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;
---- B.5.A_RESEAU_ROUTIER
---- B.5.A_7 TOPONYME_COMMUNICATION
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_toponyme_communication_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_toponyme_communication_bdt_')) = 'n_toponyme_communication_bdt_'
	THEN
---- Index
	nom_table := 'n_toponyme_communication_bdt';
	tb_index := array['id',
			'origin_nom',
			'nom',
			'importance',
			'nature'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.n_toponyme_communication_bdt_' || emprise || '_' || millesime || ' IS ''Objet nomm� du th�me routier de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Tous les noms li�s � un r�seau routier.
Mod�lisation g�om�trique : Centre du lieu nomm�. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la surface_route.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.B_VOIES_FERREES_ET_AUTRES
---- B.5.B_1 AIRE_TRIAGE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_aire_triage_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_aire_triage_bdt_')) = 'n_aire_triage_bdt_'
	THEN
--- Index
	nom_table := 'n_aire_triage_bdt';
	tb_index := array['id'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Aire de triage, faisceau de voies de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Surface qui englobe l�ensemble des tron�ons de voies, voies de garage, aiguillages permettant le tri des wagons et la composition des trains.
S�lection  :  Les  faisceaux  de  voies  de  moins  de  25  m  de  large  sont  exclus  (voir  la  classe TRON�ON_VOIE_FERREE). 
Mod�lisation  g�om�trique  :  Contour  du  faisceau,  en  s�appuyant  sur  les  voies  les  plus 
ext�rieures, au sol. � l�int�rieur d�un faisceau de voies, un espace sans voie de plus de 25 m de 
large est mod�lis� par un trou dans la surface.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de l�aire de triage.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.B_VOIES_FERREES_ET_AUTRES
---- B.5.B_2 GARE 
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_gare_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_gare_bdt_')) = 'n_gare_bdt_'
	THEN
--- Index
	nom_table := 'n_gare_bdt';
	tb_index := array['id'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS '' Gares ferroviaires de voyageurs de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
B�timent  servant  �  l�accueil,  �  l�embarquement  et  au  d�barquement  des voyageurs en train. 
Remarque :  Ces  b�timents  sont  �galement  pr�sents  dans  la  classe  des b�timents fonctionnels BATI_REMARQUABLE (cat�gorie transport, nature gare).
Mod�lisation g�om�trique : Voir chapitre sur la mod�lisation des b�timents en g�n�ral � 8.1.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de l�aire de triage.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.B_VOIES_FERREES_ET_AUTRES
---- B.5.B_3 TOPONYME_FERRE 
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_toponyme_ferre_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_toponyme_ferre_bdt_')) = 'n_toponyme_ferre_bdt_'
	THEN
--- Index
	nom_table := 'n_toponyme_ferre_bdt';
	tb_index := array['id',
			'importance',
			'nature'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Objet nomm� du th�me ferr� de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Tous les noms li�s au r�seau ferr� et dont le nom figure sur la carte au 1 : 25 000 en service. 
Mod�lisation g�om�trique : Centre du lieu nomm�. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du toponyme.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.B_VOIES_FERREES_ET_AUTRES
---- B.5.B_4 TRANSPORT_CABLE 
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_transport_cable_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_transport_cable_bdt_')) = 'n_transport_cable_bdt_'
	THEN
--- Index
	nom_table := 'n_transport_cable_bdt';
	tb_index := array['id',
			'nature'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Moyen de transport constitu� d�un ou de plusieurs c�bles porteurs de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Tous les noms li�s au r�seau ferr� et dont le nom figure sur la carte au 1 : 25 000 en service. 
Mod�lisation g�om�trique : Centre du lieu nomm�. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Type de voies ferr�es selon leur fonction et leur �tat'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale de l�objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale de l�objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.B_VOIES_FERREES_ET_AUTRES
---- B.5.B_5 TRONCON_VOIE_FERREE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_troncon_voie_ferree_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_troncon_voie_ferree_bdt_')) = 'n_troncon_voie_ferree_bdt_'
	THEN
--- Index
	nom_table := 'n_troncon_voie_ferree_bdt';
	tb_index := array['id',
			'nature',
			'electrifie',
			'franchisst',
			'nb_voies',
			'pos_sol',
			'etat'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de voie ferr�e homog�ne de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Portion de voie ferr�e homog�ne pour l�ensemble des attributs qui la concernent. 
Dans le cas d�une ligne compos�e de deux � quatre voies parall�les, l�ensemble des voies est mod�lis� par un seul objet.
S�lection : Voir les diff�rentes valeurs de l�attribut NATURE. 
 
Mod�lisation g�om�trique : A l�axe de la ou de l�ensemble des voies de la ligne, au sol. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Type de voies ferr�es selon leur fonction et leur �tat'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.electrifie IS ''�nergie servant � la propulsion des locomotives'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.largeur IS ''Largeur de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.etat IS ''Indique si le tron�on est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.C_TRANSPORT_ENERGIE 
---- B.5.C_1 CONDUITE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_conduite_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_conduite_bdt_')) = 'n_conduite_bdt_'
	THEN
--- Index
	nom_table := 'n_conduite_bdt';
	tb_index := array['id',
			'pos_sol'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Conduite utilis� pour le transport de mati�re premi�re de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Conduite (autre que canalisation d�eau) ou tapis roulant utilis�s pour le transport de mati�re premi�re (gaz, hydrocarbure, minerai, etc.) ou canalisation de nature inconnue.
S�lection : Conduites a�riennes issues de restitution, et conduites souterraines qui figurent sur la carte au 1 : 25 000. 
 
Mod�lisation g�om�trique : � l�axe.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.C_TRANSPORT_ENERGIE 
---- B.5.C_2 LIGNE_ELECTRIQUE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_ligne_electrique_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_ligne_electrique_bdt_')) = 'n_ligne_electrique_bdt_'
	THEN
--- Index
	nom_table := 'n_ligne_electrique_bdt';
	tb_index := array['id',
			'voltage'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Conduite utilis� pour le transport de mati�re premi�re de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Conduite (autre que canalisation d�eau) ou tapis roulant utilis�s pour le transport de mati�re premi�re (gaz, hydrocarbure, minerai, etc.) ou canalisation de nature inconnue.
S�lection : Conduites a�riennes issues de restitution, et conduites souterraines qui figurent sur la carte au 1 : 25 000. 
 
Mod�lisation g�om�trique : � l�axe.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on de la ligne �lectrique.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.voltage IS ''Tension de la ligne �lectrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.C_TRANSPORT_ENERGIE 
---- B.5.C_3 POSTE_TRANSFORMATION 
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_poste_transformation_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_poste_transformation_bdt_')) = 'n_poste_transformation_bdt_'
	THEN
--- Index
	nom_table := 'n_poste_transformation_bdt';
	tb_index := array['id'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Poste de transformation �lectrique de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Enceinte � l�int�rieur de laquelle le courant transport� par une ligne �lectrique est transform�.
S�lection  :  Tous  les  postes  de  transformation  situ�s  sur  le  r�seau  de  lignes  �  haute  ou  tr�s haute tension. 
 
Mod�lisation  g�om�trique  :  Contour  du  poste,  au  sol  lorsque  le  poste  est  d�limit�  par  un grillage, ou en haut des b�timents lorsque ceux-ci constituent la limite du poste.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du poste de transformation .
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.C_TRANSPORT_ENERGIE 
---- B.5.C.4 PYLONE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pylone_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pylone_bdt_')) = 'n_pylone_bdt_'
	THEN
--- Index
	nom_table := 'n_pylone_bdt';
	tb_index := array['id'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Support de ligne �lectrique. Pyl�ne, portique de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Les pyl�nes et portiques soutenant des lignes de 63 KV et plus. 
 
Mod�lisation g�om�trique : � l�axe et en haut du pyl�ne. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du poste de transformation .
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.D_HYDROGRAPHIE 
---- B.5.D.1 CANALISATION_EAU 
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_canalisation_eau_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_canalisation_eau_bdt_')) = 'n_canalisation_eau_bdt_'
	THEN
--- Index
	nom_table := 'n_canalisation_eau_bdt';
	tb_index := array['id',
			'pos_sol'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Canalisation d�eau de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Uniquement  les  canalisations  a�riennes  et  celles  qui  figurent  sur  la  carte  au 1 : 25 000 en service. 
 
Mod�lisation g�om�trique : � l�axe et sur le dessus de la canalisation.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la canalisation.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.D_HYDROGRAPHIE 
---- B.5.D.2 HYDRONYME
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_hydronyme_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_hydronyme_bdt_')) = 'n_hydronyme_bdt_'
	THEN
--- Index
	nom_table := 'n_hydronyme_bdt';
	tb_index := array['id',
			'origin_nom',
			'importance',
			'nature'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Nom se rapportant � un d�tail hydrographique de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Tous les d�tails hydrographiques dont le nom figure sur la carte au 1 : 25 000. 
 
Mod�lisation g�om�trique : Centre du d�tail nomm�.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du toponyme.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.D_HYDROGRAPHIE 
---- B.5.D.3 POINT_EAU
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_point_eau_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_point_eau_bdt_')) = 'n_point_eau_bdt_'
	THEN
--- Index
	nom_table := 'n_point_eau_bdt';
	tb_index := array['id',
			'nature'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Source, point de production d�eau ou point de stockage d�eau de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Source (capt�e ou non), point de production d�eau (pompage, forage, puits,�) ou point de stockage d�eau de petite dimension (citerne, abreuvoir, lavoir, bassin).
S�lection  :  Tous  les  points  d�eau  mentionn�s  sur  la  carte  au  1 : 25 000,  sauf  ceux  dont  la disparition  est  attest�e  par  l�examen  des  photographies  a�riennes  ou  d�autres  sources d�information. 
Les abreuvoirs, les puits et les lavoirs sont g�n�ralement exclus. 
 
Mod�lisation g�om�trique : Au centre. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du toponyme.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du point d�eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.D_HYDROGRAPHIE 
---- B.5.D.4 RESERVOIR_EAU
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_reservoir_eau_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_reservoir_eau_bdt_')) = 'n_reservoir_eau_bdt_'
	THEN
--- Index
	nom_table := 'n_reservoir_eau_bdt';
	tb_index := array['id',
			'nature',
			'hauteur'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''R�servoir d�eau de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Tous les r�servoirs de plus de 10 m de diam�tre sont inclus, sauf les r�servoirs d�eau non couverts (classe SURFACE_EAU), les citernes (classe POINT_EAU), et les bassins (classe SURFACE_EAU). 
 
Mod�lisation g�om�trique : Contour ext�rieur du r�servoir, � l�altitude de ce contour. 
Un  groupe  de  petits  r�servoirs  (<10  m)  peut  �tre  mod�lis�  par  l�enveloppe  convexe  de l�ensemble. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du r�servoir.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du r�servoir d�eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du r�servoir d�eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du r�servoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du r�servoir d�eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du r�servoir d�eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.D_HYDROGRAPHIE 
---- B.5.D.5 SURFACE_EAU
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_surface_eau_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_surface_eau_bdt_')) = 'n_surface_eau_bdt_'
	THEN
--- Index
	nom_table := 'n_surface_eau_bdt';
	tb_index := array['id',
			'nature',
			'regime'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Surface d�eau terrestre, naturelle ou artificielle de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Toutes les surfaces d�eau de plus de 20 m de long sont incluses, ainsi que les cours d�eau de plus de 7,5 m de large. Les cours d�eau de plus de 5 m de large sont ajout�s lorsqu�ils sont situ�s entre deux surfaces d�eau, ou en prolongation d�une surface d�eau vers la source. 
 
Tous les bassins ma�onn�s de plus de 10 m sont inclus. Les zones inondables p�riph�riques (zone p�riph�rique d�un lac de barrage, d�un �tang � niveau variable) de plus de 20 m de large sont incluses (attribut REGIME = Intermittent). 
 
 
Mod�lisation g�om�trique : La mod�lisation est fonction de la valeur de l�attribut REGIME : 
�  Pour l�hydrographie permanente : contours de la surface, au niveau de l�eau apparent sur les photographies a�riennes de r�f�rence. 
�  Pour  l�hydrographie  temporaire  :  contours  de  la  surface  marqu�e  de  mani�re  permanente par la pr�sence r�p�t�e de l�eau. 
 
Contrainte de mod�lisation : 
Une surface d�eau inscrite dans la continuit� d�un cours d�eau est toujours doubl�e d�un objet de classe TRONCON_COURS_EAU et d�attribut FICTIF = Oui. 
Dans  leur  partie  aval,  les  surfaces  d�eau  repr�sentant  des  cours  d�eau  sont  repr�sent�es  au moins jusqu�� la laisse des plus hautes mers.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la surface d�eau.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.regime IS ''R�gime des eaux'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_moyen IS ''Altitude moyenne des points composants la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.D_HYDROGRAPHIE 
---- B.5.D.6 TRONCON_COURS_EAU
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_troncon_cours_eau_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_troncon_cours_eau_bdt_')) = 'n_troncon_cours_eau_bdt_'
	THEN
--- Index
	nom_table := 'n_troncon_cours_eau_bdt';
	tb_index := array['id',
			'artif',
			'fictif',
			'franchisst',
			'pos_sol',
			'regime'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de cours d�eau, r�el ou fictif, permanent ou temporaire de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : 
Le r�seau hydrographique compos� des objets TRONCON_COURS_EAU est d�crit de mani�re continue. 
La continuit� du r�seau n�est toutefois pas toujours assur�e dans les cas suivants : 
�  arriv�e d�un cours d�eau en ville ; 
�  infiltration d�un cours d�eau (ex. perte en terrain calcaire) ; 
�  arriv�e d�un petit ruisseau temporaire dans une large plaine o� son trac� se perd ; 
�  zones de marais o� les connexions et interruptions du r�seau restent indicatives. 
 
Tous les cours d�eau permanents, naturels ou artificiels, sont inclus. 
 
Les cours d�eau temporaires naturels sont inclus, � l�exception des tron�ons de moins de 100 m situ�s aux extr�mit�s amont du r�seau. 
 
Les  cours  d�eau  temporaires  artificiels  ou  artificialis�s  sont  s�lectionn�s  en  fonction  de  leur importance et de l�environnement (les tron�ons longeant une voie de communication sont exclus, ainsi que les foss�s). 
 
Les talwegs qui ne sont pas marqu�s par la pr�sence r�guli�re de l�eau sont exclus. 
 
Tous les cours d�eau nomm�s de plus de 7,5 m de large (�ventuellement 5 m de large dans les cas  expliqu�s  au  chapitre  7.5.1  D�finition)  sont  inclus  (TRONCON_COURS_EAU  d�attribut FICTIF = Oui superpos� � un objet de classe SURFACE_EAU) 
 
Foss�  :  Les  gros  foss�s  de  plus  de  2  m  de  large  sont  inclus  lorsqu�ils  coulent  de  mani�re permanente.  Les  foss�s  dont  le  d�bit  n�est  pas  permanent  sont  s�lectionn�s  en  fonction  de l�environnement. Ils sont g�n�ralement exclus lorsqu�ils longent une voie de communication.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.artif IS ''Artificiel'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.fictif IS ''Indique la nature fictive ou r�el du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du cours d eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.regime IS ''R�gime des eaux'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tron�on'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.D_HYDROGRAPHIE 
---- B.5.D.7 TRONCON_LAISSE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_troncon_laisse_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_troncon_laisse_bdt_')) = 'n_troncon_laisse_bdt_'
	THEN
--- Index
	nom_table := 'n_troncon_laisse_bdt';
	tb_index := array['id',
			'nature'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Limite de l�estran de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Laisse des plus hautes mers et laisse des plus basses mers. 
 
Avertissement :  la  laisse  des  plus  basses  mers  est  issue  �  l�origine  de  cartes  du  SHOM (Service Hydrographique et Oc�anographique de la Marine). Cette laisse n�est pas mise � jour, elle ne doit en aucun cas �tre utilis�e pour la navigation. Les utilisateurs qui voudraient pratiquer des activit�s assimilables � la navigation sont pri�s de se reporter aux derni�res documentations, notamment les cartes papier ou �lectroniques, du SHOM. 
 
Mod�lisation  g�om�trique  :  La  laisse  des  plus  hautes  mers  est  mod�lis�e  par  une  ligne d�altitude constante (de type courbe de niveau) dont l�altitude est calcul�e. 
La laisse des plus basses mers est mod�lis�e par une ligne correspondant � l�isobathe 0 (0 des cartes marines). 
 
Contrainte  de  mod�lisation  :  Les  deux  laisses  ne  se  croisent  pas.  Elles  peuvent  �tre confondues (ex : M�diterran�e).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tron�on de laisse.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '..prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.1  BATI_INDIFFERENCIE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_bati_indifferencie_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_bati_indifferencie_bdt_')) = 'n_bati_indifferencie_bdt_'
	THEN
--- Index
	nom_table := 'n_bati_indifferencie_bdt';
	tb_index := array['id',
			'origin_bat',
			'hauteur',
			'z_min',
			'z_max'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''B�timent ne poss�dant pas de fonction particuli�re de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
B�timent ne poss�dant pas de fonction particuli�re pouvant �tre d�crit dans les autres classes de b�timents surfaciques  (voir 8.2, 8.3, 8.4) : b�timents d�habitation, d�enseignement� (voir d�tails dans les � S�lection et Mod�lisation g�om�trique). 

S�lection  :  B�timents  d�habitation,  bergeries,  bories,  bungalows,  bureaux,  chalets,  b�timents d�enseignement,  garages  individuels,  b�timents  hospitaliers,  immeubles  collectifs,  lavoirs couverts, mus�es, prisons, refuges, villages de vacances. 
 
La  mod�lisation  g�om�trique  peut  �tre  de  deux  types  suivant  que  le  b�timent  est  issu initialement  de  la  BD  TOPO� (c�est-�-dire  principalement  obtenu  par  restitution photogramm�trique  �  partir  d�une  prise  de  vue  a�rienne),  ou  que  celui-ci  est  obtenu  apr�s int�gration  des  donn�es  du  cadastre.  Les  deux  possibilit�s  coexistent  actuellement  dans  la BD TOPO�, jusqu�� int�gration compl�te des b�timents du cadastre. 
 
Int�gration du b�ti du cadastre ou � unification � : L�objectif de l�unification est de cr�er une nouvelle  couche  � b�ti �  en  utilisant  les  points  forts  de  la  BD  TOPO� et de la BD PARCELLAIRE�.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du b�timent.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.2  BATI_INDUSTRIEL
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_bati_industriel_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_bati_industriel_bdt_')) = 'n_bati_industriel_bdt_'
	THEN
--- Index
	nom_table := 'n_bati_industriel_bdt';
	tb_index := array['id',
			'origin_bat',
			'nature',
			'hauteur',
			'z_min',
			'z_max'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''B�timent � caract�re industriel, commercial ou agricole de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
B�timent ne poss�dant pas de fonction particuli�re pouvant �tre d�crit dans les autres classes de b�timents surfaciques  (voir 8.2, 8.3, 8.4) : b�timents d�habitation, d�enseignement� (voir d�tails dans les � S�lection et Mod�lisation g�om�trique). 

S�lection  :
- B�timent agricole : B�timent  r�serv�  �  des  activit�s  agricoles :  b�timent  d��levage industriel, hangar agricole (grand), minoterie. 
- B�timent commercial : B�timent  de  grande  surface  r�serv�  �  des  activit�s commerciales :  centre  commercial,  hypermarch�,  magasin (grand, isol�), parc des expositions (b�timent). 
- B�timent industriel : B�timent  r�serv�  �  des  activit�s  industrielles :  abattoir,  atelier (grand),  auvent  de  quai  de  gare),  auvent  de  p�age,  b�timent industriel  (grand),  centrale  �lectrique  (b�timent),  construction technique, entrep�t, hangar industriel (grand), scierie, usine. 
- Serre : Abri clos � parois translucides destin� � prot�ger les v�g�taux du froid : jardinerie, serre. Les serres en arceaux de moins de 20 m de long sont exclues. Les  serres  situ�es  �  moins  de  3  m  les  unes  des  autres  sont mod�lis�es  par  un  seul  objet  englobant  l�ensemble  des  serres en s�appuyant au maximum sur leurs contours. 
- Silo : R�servoir, qui charg� par le haut se vide par le bas, et qui sert de d�p�t, de magasin, etc. Le silo est exclusivement destin� aux produits agricoles : cuve � vin, silo 
 
La  mod�lisation  g�om�trique  peut  �tre  de  deux  types  suivant  que  le  b�timent  est  issu initialement  de  la  BD  TOPO� (c�est-�-dire  principalement  obtenu  par  restitution photogramm�trique  �  partir  d�une  prise  de  vue  a�rienne),  ou  que  celui-ci  est  obtenu  apr�s int�gration  des  donn�es  du  cadastre.  Les  deux  possibilit�s  coexistent  actuellement  dans  la BD TOPO�, jusqu�� int�gration compl�te des b�timents du cadastre. 
 
Int�gration du b�ti du cadastre ou � unification � : L�objectif de l�unification est de cr�er une nouvelle  couche  � b�ti �  en  utilisant  les  points  forts  de  la  BD  TOPO� et de la BD PARCELLAIRE�.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du b�timent.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.3  BATI_REMARQUABLE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_bati_remarquable_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_bati_remarquable_bdt_')) = 'n_bati_remarquable_bdt_'
	THEN
--- Index
	nom_table := 'n_bati_remarquable_bdt';
	tb_index := array['id',
			'origin_bat',
			'nature',
			'hauteur',
			'z_min',
			'z_max'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''B�timent poss�dant une fonction, contrairement aux b�timents indiff�renci�s, et dont la fonction est autre qu�industrielle de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
B�timent poss�dant une fonction, contrairement aux b�timents indiff�renci�s, et dont la fonction est autre qu�industrielle (ces derniers sont regroup�s dans la classe BATI_INDUSTRIEL). Il s�agit des b�timents administratifs, religieux, sportifs, et relatifs au transport. 
S�lection  :
- A�rogare : Ensemble des b�timents d�un a�roport r�serv�s aux voyageurs et aux marchandises. 
- Arc de triomphe : Portique monumental : arc de triomphe, porte de ville. 
- Ar�ne ou th��tre antique : Vaste  �difice  �  gradins,  de  forme  en  partie  ou  totalement  ronde  ou elliptique : amphith��tre, ar�ne, th��tre antique, th��tre de plein air. 
- B�timent religieux divers : B�timent  r�serv�  �  l�exercice  d�un  culte  religieux,  autre  qu�une chapelle  ou  qu�une  �glise  (voir  ces  valeurs) :  mosqu�e, synagogue, temple. 
- B�timent sportif : B�timent  r�serv�  �  la  pratique  sportive :  gymnase,  piscine  couverte, salle de sport, tennis couvert. 
- Chapelle : Petit �difice religieux catholique de forme caract�ristique 
- Ch�teau : Habitation  ou  ancienne  habitation  f�odale,  royale  ou  seigneuriale :ch�teau, ch�teau fort, citadelle 
- Eglise : �difice religieux catholique de forme caract�ristique : basilique,cath�drale, �glise. 
- Fort, blockhaus, casemate : Ouvrage militaire : blockhaus, casemate, fort, ouvrage fortifi�. 
- Gare : B�timent servant � l�embarquement et au d�barquement des voyageurs en train. 
- Mairie : �difice  o�  se  trouvent  les  services  de  l�administration municipale, appel� aussi h�tel de ville. 
- Monument : Monument comm�moratif quelconque, � l�exception des arcs de triomphe (voir cette valeur d�attribut). 
- P�age : B�timent o� sont per�us les droits d�usage. 
- Pr�fecture : B�timent o� sont install�s les services pr�fectoraux. 
- Sous-pr�fecture : B�timent  o�  sont  les  bureaux  du  sous-pr�fet :  chef-lieu d�arrondissement. 
- Tour, donjon, moulin : B�timent remarquable dans le Paysage par sa forme �lev�e : donjon, moulin � vent, tour, tour de contr�le. 
- Tribune : Tribune de terrain de sport (stade, hippodrome, v�lodrome,�).

La  mod�lisation  g�om�trique  peut  �tre  de  deux  types  suivant  que  le  b�timent  est  issu initialement  de  la  BD  TOPO� (c�est-�-dire  principalement  obtenu  par  restitution photogramm�trique  �  partir  d�une  prise  de  vue  a�rienne),  ou  que  celui-ci  est  obtenu  apr�s int�gration  des  donn�es  du  cadastre.  Les  deux  possibilit�s  coexistent  actuellement  dans  la BD TOPO�, jusqu�� int�gration compl�te des b�timents du cadastre. 
 
Int�gration du b�ti du cadastre ou � unification � : L�objectif de l�unification est de cr�er une nouvelle  couche  � b�ti �  en  utilisant  les  points  forts  de  la  BD  TOPO� et de la BD PARCELLAIRE�.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du b�timent.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les b�timents'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.4 CIMETIERE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_cimetiere_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_cimetiere_bdt_')) = 'n_cimetiere_bdt_'
	THEN
--- Index
	nom_table := 'n_cimetiere_bdt';
	tb_index := array['id',
			'nature'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Cimeti�re de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Lieu o� l�on enterre les morts. 
Cimeti�re communal, islamique, isra�lite, ou militaire.

S�lection : Tous les cimeti�res sont inclus. 
Les cr�matoriums, fun�rariums, ossuaires, � situ�s hors cimeti�re sont exclus. 
 
Mod�lisation g�om�trique : Le contour de la surface repr�sente l�enceinte du cimeti�re (haut du mur si c�est un mur, bord de toit si c�est un b�timent, sol s�il s�agit d�une simple cl�ture). 
 
Contrainte de mod�lisation : 
Un objet de classe CIMETIERE peut englober des b�timents (la surface n�est pas trou�e). 
La  g�om�trie  d�un  cimeti�re  peut  �tre  partiellement  identique  �  celle  d�un  b�timent  (b�timent mitoyen).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du cimetiere.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du cimetiere'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.5 CONSTRUCTION_LEGERE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_construction_legere_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_construction_legere_bdt_')) = 'n_construction_legere_bdt_'
	THEN
--- Index
nom_table := 'n_construction_legere_bdt';
	tb_index := array['id',
			'origin_bat',
			'hauteur'
			];
nb_index := array_length(tb_index, 1);

FOR i_index IN 1..nb_index LOOP
	nom_index:=tb_index[i_index];
	req := '
		DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
		CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Structure l�g�re de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Structure l�g�re non attach�e au sol par l�interm�diaire de fondations (cabanes, abris de jardins�) ou b�timent quelconque ouvert sur au moins un c�t� (pr�aux, auvents, tribunes).

S�lection : Baraquements, cabanes, granges, pr�aux, auvents, tribunes. 
 
Mod�lisation g�om�trique : Voir paragraphe 8.1.1 D�finition de la classe .BATI_INDIFFENCIE. 
 
Disponibilit� : La classe d�objets CONSTRUCTION_LEGERE sera disponible au fur et � mesure de  l�avancement  de  la  production  du  b�ti  unifi�  qui  reprend  la  g�om�trie  de  toutes  les constructions  de  la  BD  PARCELLAIRE�,  sauf  celles  manifestement  d�truites  au  moment  du processus d�unification. 
 
Avant unification des b�timents, il n�y a pas d�objets CONSTRUCTION_LEGERE. 
Apr�s  unification,  tous  les  b�timents  qui  ont  �t�  appari�s  avec  une  construction  l�g�re  de  la BD PARCELLAIRE� sont transf�r�s dans la classe CONSTRUCTION_LEGERE.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction leg�re.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source de la construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.6 CONSTRUCTION_LINEAIRE 
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_construction_lineaire_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_construction_lineaire_bdt_')) = 'n_construction_lineaire_bdt_'
	THEN
--- Index
nom_table := 'n_construction_lineaire_bdt';
tb_index := array['id',
		'nature'
		];
nb_index := array_length(tb_index, 1);

FOR i_index IN 1..nb_index LOOP
	nom_index:=tb_index[i_index];
	req := '
		DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
		CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Construction lin�aire de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Construction dont la forme g�n�rale est lin�aire.Exemples : barrage, mur anti-bruit, ruines, etc.

S�lection : Indiff�renci�, Barrage, Mur anti-bruit, Pont, Ruines, Quai.
 
Mod�lisation g�om�trique : Voir pour chaque valeur de l�attribut NATURE.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction lin�aire.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les constructions'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du b�timent'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.7  CONSTRUCTION_PONCTUELLE 
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_construction_ponctuelle_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_construction_ponctuelle_bdt_')) = 'n_construction_ponctuelle_bdt_'
	THEN
--- Index
nom_table := 'n_construction_ponctuelle_bdt';
tb_index := array['id',
		'nature'
		];
nb_index := array_length(tb_index, 1);

FOR i_index IN 1..nb_index LOOP
	nom_index:=tb_index[i_index];
	req := '
		DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
		CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Construction ponctuelle de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Construction de faible emprise et de grande hauteur de plus de 50 m de haut et de moins de 20 m2.

S�lection : Toutes les constructions de plus de 50 m de haut et de moins de 20 m2. 
Les constructions de grande hauteur et de plus de 20 m� sont exclues (elles sont repr�sent�es par un objet de classe <b�timent>). 
 
Les constructions de moins de 20 m2 et de moins de 50 m de haut sont incluses : 
�  lorsque leur taille ou leur forme font d�elles des constructions � la fois bien identifiables et caract�ristiques dans le paysage ; 
�  pour permettre de coter le sommet d�un b�timent dont la base large impose une saisie au niveau du sol et emp�che de r�cup�rer l�altitude du fa�te �lev� (ex. b�timent de forme pyramidale, surmont� d�une tour,�). 
 
Mod�lisation g�om�trique : Centre de l�objet, altitude maximum. 
 
Contrainte de mod�lisation : Dans le cas d�un clocher, d�un minaret ou d�une chemin�e, l�objet de classe CONSTRUCTION_PONCTUELLE peut �tre superpos� � un objet surfacique.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction lin�aire.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les constructions'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale de la construction lin�aire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale de la construction lin�aire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.8 CONSTRUCTION_SURFACIQUE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_construction_surfacique_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_construction_surfacique_bdt_')) = 'n_construction_surfacique_bdt_'
	THEN
--- Index
nom_table := 'n_construction_surfacique_bdt';
tb_index := array['id',
		'nature'
		];
nb_index := array_length(tb_index, 1);

FOR i_index IN 1..nb_index LOOP
	nom_index:=tb_index[i_index];
	req := '
		DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
		CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Ouvrage surfacique de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Ouvrage de grande surface li� au franchissement d�un obstacle par une voie de communication, ou � l�am�nagement d�une rivi�re ou d�un canal.

S�lection :
- Barrage : Grand barrage en ma�onnerie apparente. Ex : barrage-vo�te 
Tous les barrages ma�onn�s dont la surface projet�e au sol d�passe 25 m de large sont inclus. Les autres barrages (barrages plus �troits ou barrages en terre) sont mod�lis�s par la classe CONSTRUCTION_LINEAIRE. 
Mod�lisation : Contours de l�ouvrage d�fini par l�axe de la partie horizontale sup�rieure, et par le pied du barrage. 
- Dalle  de protection :Dalle  (ou  auvent)  horizontale  prot�geant  une  voie  de  communication  des chutes de pierres, des coul�es de neige, ou prot�geant le voisinage du bruit. 
Toutes les dalles de protection de plus de 100 m de long sont incluses (une suite  de  dalles  se  succ�dant  �  moins  de  20 m  les  unes  des  autres  est consid�r�e comme une seule dalle). 
Mod�lisation : Limite ext�rieure de la dalle, altitude de sa face sup�rieure. 
- Ecluse : Ouvrage  hydraulique  form�  essentiellement  de  portes  munies  de  vannes destin� � retenir ou � l�cher l�eau selon les besoins : ascenseur � bateaux, 
cale s�che, �cluse, radoub. 
Toutes les �cluses, cales s�ches et radoubs poss�dant leurs portes et tous les ascenseurs � bateaux sont inclus lorsqu�ils sont situ�s sur un cours d�eau de plus de 7,5 m de large (Si le cours d�eau est plus �troit, la mod�lisation de l��cluse  se  fait  uniquement  par  changement  d�attribut  du TRONCON_COURS_EAU).
Mod�lisation : Contours de la chambre d��cluse, de la cale ou de la pente de l�ascenseur. L�altitude est celle du bord du quai. 
- Pont : Pont supportant plusieurs objets lin�aires, un objet surfacique, ou pont dont l�emprise  d�passe  largement  celle  des  voies  qu�il  supporte.  Il  peut  �tre mobile. 
Tous  les  ponts  supportant  un  objet  surfacique  ou  plusieurs  objets  lin�aires sont inclus. 
Les ponts dont les parapets se trouvent  � 20 m ou  plus du bord des  voies support�es sont inclus. 
Les  ponts  ne  supportant  qu�un  objet  lin�aire  sont  mod�lis�s  par  un changement  de  valeur  de  l�attribut  <position  par  rapport  au  sol>  (qui  prend une valeur strictement positive sur le pont). 
Mod�lisation : Surface d�finie par les deux parapets du pont et deux lignes joignant les extr�mit�s des parapets. 
- : Escalier  Escalier monumental uniquement (contours de l�escalier). 
Mod�lisation : Contours de la chambre d��cluse, de la cale ou de la pente de l�ascenseur. L�altitude est celle du bord du quai.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction surfacique.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les constructions surfaciques'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale de la construction surfacique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale de la construction surfacique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.9 PISTE_AERODROME
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_piste_aerodrome_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_piste_aerodrome_bdt_')) = 'n_piste_aerodrome_bdt_'
	THEN
--- Index
nom_table := 'n_piste_aerodrome_bdt';
tb_index := array['id',
		'nature'
		];
nb_index := array_length(tb_index, 1);

FOR i_index IN 1..nb_index LOOP
	nom_index:=tb_index[i_index];
	req := '
		DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
		CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Piste d�a�rodrome de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Aire  situ�e  sur  un  a�rodrome,  am�nag�e  afin  de  servir  au  roulement  des a�ronefs, au d�collage et � l�atterrissage, en dur ou en herbe.

S�lection : Tous les a�rodromes sont inclus, y compris les h�liports, que la piste soit rev�tue ou en herbe. 
 
Mod�lisation g�om�trique : Contour de l�ensemble des pistes et des aires de roulement, au sol.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la piste.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les constructions surfaciques'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_moyen IS ''Altitude moyenne de la piste'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.10 RESERVOIR
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_reservoir_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_reservoir_bdt_')) = 'n_reservoir_bdt_'
	THEN
	--- Index
	nom_table := 'n_reservoir_bdt';
	tb_index := array['id',
		'origin_bat',
		'nature',
		'hauteur'
		];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
	---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''R�servoir de plus de 10m de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
R�servoir (eau, mati�res industrielles,�) de plus de 10m de diam�tre. 
Remarque : les r�servoirs d�eau et ch�teau d�eau sont �galement pr�sents dans la classe RESERVOIR_EAU du th�me hydrographique.

S�lection : Tous les r�servoirs de plus de 10 m de diam�tre sont inclus sauf : 
�  les r�servoirs souterrains sont exclus ; les citernes sont dans la  classe POINT_EAU ; 
�  les r�servoirs d�eau non couverts sont exclus (voir classe SURFACE_EAU, NATURE =Bassin). 
 
Mod�lisation g�om�trique : Contour ext�rieur du r�servoir, � l�altitude de ce contour (altitude de l�ar�te sup�rieure en cas de face verticale). 
Un groupe de petits r�servoirs (<10 m) peut �tre mod�lis� par un rectangle englobant l�ensemble. 
 
L�altitude correspondant au contour est une altitude toit m�diane, calcul�e par interpolation sur un MNE  (Mod�le  Num�rique  d��l�vation)  ou  par  rapport  au  Z  du  toit  BD  TOPO�,  en  prenant  en compte les altitudes des contours des b�timents directement contigus s�ils existent.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du reservoir.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.E_BATI 
---- B.5.E.11 TERRAIN_SPORT
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_terrain_sport_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_terrain_sport_bdt_')) = 'n_terrain_sport_bdt_'
	THEN
	--- Index
	nom_table := 'n_terrain_sport_bdt';
	tb_index := array['id',
			'nature'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
	---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''�quipement sportif de plein air de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection :
- Indiff�renci� : Grand terrain d�couvert servant � la pratique de sports collectifs tels  que  le  football,  le  rugby,  etc. :  plate-forme  multisports, terrain d�entra�nement, terrain de football, terrain de rugby. 
Plate-forme multisports : Seules les plates-formes am�nag�es (rev�tement,  panneaux  de  baskets,  marquage  au  sol,�), r�serv�es � la pratique sportive, �quip�es de plusieurs terrains de  jeux,  et  d�une  longueur  totale  de  50 m  au  moins  sont incluses. Les cours de r�cr�ation plus ou moins �quip�es pour la pratique sportive sont exclues. 
Terrain  d�entra�nement : Seuls  les  terrain  d�entra�nement  de football  ou  de  rugby  dont  la  taille  et  l�aspect  sont  proches  de ceux des terrains r�glementaires sont inclus (marquage au sol, pr�sence de tribunes ou de vestiaires, etc.). Les petits terrains mal d�limit�s sont exclus. 
Mod�lisation : Surface s�appuyant sur l�aire de jeu. Dans le cas des plates-formes multisports, c�est l�emprise globale de la partie am�nag�e  qui  est  repr�sent�e.  L�altitude  est  toujours  celle  du sol. 
- Piste de sport : Large piste r�serv�e � la course : autodrome (piste), circuit auto-moto (piste), cynodrome (piste), hippodrome (piste), v�lodrome (piste). 
S�lection : Toutes les pistes de sport de plus de 10 m de large environ  sont  incluses  sauf  celles  qui  sont  situ�es  en  salle (v�lodrome�). 
Les  pistes  de  sport  de  moins  de  10  m  de  large  environ  sont exclues  
Les pistes d�athl�tisme sont exclues. 
Mod�lisation : Contours de la piste, au sol. 
- Terrain de tennis : Terrain sp�cialement am�nag� pour la pratique du tennis. 
S�lection : Tous  les  terrains  de  tennis  ext�rieurs  entretenus sont inclus. 
Mod�lisation : Contours  du  terrain  (grillage  en  planim�trie,  sol en altim�trie). 
Contrainte  de  mod�lisation : Plusieurs  terrains  de  tennis contigus  sont  mod�lis�s  par  un  seul  objet  englobant  les diff�rents terrains. 
- Bassin de natation : Bassin  de  natation  d�une  piscine  d�couverte :  bassin  de natation, piscine (d�couverte). 
S�lection : Tous les bassins de natation de piscine d�couverte dont la longueur est sup�rieure ou �gale � 25 m sont inclus. 
Mod�lisation : Surface s�appuyant sur les rebords du bassin.  
 
Mod�lisation g�om�trique : Voir les diff�rentes valeurs de l�attribut NATURE.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du terrain de sport.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du terrain de sport'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_moyen IS ''Altitude moyenne du terrain de sport'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.F_VEGETATION 
---- B.5.F.1 ZONE_VEGETATION
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_zone_vegetation_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_zone_vegetation_bdt_')) = 'n_zone_vegetation_bdt_'
	THEN
	--- Index
	nom_table := 'n_zone_vegetation_bdt';
	tb_index := array['id',
			'nature'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
	---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Zone de v�g�tation de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Espace v�g�tal naturel ou non diff�renci� selon le couvert forestier.
S�lection : Bois de plus de 500m2 ; for�ts ouvertes, landes, vignes et vergers de plus de 5000m2. 
L�exhaustivit� ne pouvant �tre assur�e en dessous de ces seuils, les s�lections sont effectu�es de fa�on � donner une vision repr�sentative du paysage : 
�  structure principale d�un r�seau dense de haies ou rang�es d�arbres ; 
�  s�lection d�arbres isol�s et bosquets en zone urbaine et en zone de v�g�tation clairsem�e (maquis, jardins ouvriers�). 
 
D�finitions du couvert : 
o   Couvert absolu d�un peuplement : surface planim�trique de la projection verticale des houppiers des arbres du peuplement. 
o   Taux de couvert absolu : quotient du couvert absolu du peuplement par la surface du site. 
o   Taux de couvert relatif d�un sous-peuplement : quotient du couvert absolu du sous-peuplement par le couvert absolu du peuplement. 
 
Mod�lisation  g�om�trique  :  Contour  ext�rieur  de  la  zone.  Voir  d�tail  pour  chaque  valeur  de l�attribut NATURE. 
 
Contrainte de mod�lisation : Voir le d�tail par valeur de l�attribut NATURE. 
 
Disponibilit� : Dans un premier temps, l�attribut NATURE de la classe ZONE_VEGETATION du produit BD TOPO� n�est rempli que par la valeur � Zone arbor�e � ; au fur et � mesure de l�avancement de la production multi-th�me (qui permet de distinguer diff�rents types de v�g�tation), cette valeur dispara�t au profit de 12 postes distincts (la valeur � Zone arbor�e � sera exclusive de toutes les autres).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du terrain de sport.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du terrain de sport'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.G_OROGRAPHIE  
---- B.5.G.1 LIGNE_OROGRAPHIQUE 
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_ligne_orographique_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_ligne_orographique_bdt_')) = 'n_ligne_orographique_bdt_'
	THEN
	--- Index
	nom_table := 'n_ligne_orographique_bdt';
	tb_index := array['id',
			'nature'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
	---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Ligne de rupture de pente artificielle de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Voir chaque valeur de l�attribut NATURE. 

Lev�e 
D�finition : Digue  en  terre  (lev�e  de  terre)  ou  en  ma�onnerie  de  faible  largeur : crassier, lev�e de terre, digue en terre, remblai, terril.
S�lection :
�Remblai : Tous les remblais de voies de communication de plus de 200 m de long, 2 m de haut et de moins de 20 m de large sont inclus.
�Digue : Toutes les digues en terre ou en pierres de plus de 200 m de long et 2 m de haut sont incluses.
�Lev�e de terre : Toutes les lev�es de terre ou de pierres isol�es de plus de 200 m de long et 3 m de haut sont incluses.
Mod�lisation : Axe et sommet de la lev�e.
Contrainte   de   mod�lisation:   Une   lev�e   supportant   une   voie   de   communication  (ou  un  canal)  est  d�crite  par  une  g�om�trie  identique  �  celle-ci.   
Pour cet objet, l�orientation n�est pas significative.

Mur de sout�nement
D�finition : Mur �paulant un remblai, une terrasse.
S�lection :  Tous  les  murs  de  sout�nement  de  plus  de  200  m  de  long  et  2  m  de haut situ�s le long d�une voie de communication sont inclus.
Tous les murs de sout�nement de plus de 3 m de haut et 100 m de long sont inclus (fortifications, terrasse,...).
Mod�lisation g�om�trique : Rebord du mur. L�objet est orient� de mani�re � ce que le cot� aval soit sur sa droite.

Talus 
D�finition : Ligne de rupture de pente : crassier, d�blai, remblai, talus.
S�lection : Tous les talus de plus de 200 m de long et 2 m* de haut situ�s le long  d�une  voie  de  communication  sont  inclus,  qu�ils  soient  en  terre  ou  rocheux (voir aussi <ligne orographique> pour les voies de communication en remblai).
Les talus naturels de plus de 200 m de long et de 3 m de haut sont retenus.
Les    talus    de    carri�re    prennent    une    autre    valeur    d�attribut    (voirNATURE = Carri�re). 
* Le  long  des  routes  situ�es  �  flanc  de  montagne,  le  crit�re  de  hauteur  est  relev� en fonction de la pente, de mani�re � exclure tous les talus de 2 � 5 m qui  font  partie  du  profil  normal  de  la  route,  et  qui  bordent  celle-ci  de  mani�re  continue.
Mod�lisation  g�om�trique :  Ligne  de  rupture  de  pente  amont  (la  limite  aval  d�un talus n�est jamais repr�sent�e). L�objet est orient� de mani�re � ce que le cot� aval soit sur sa droite.

Carri�re
D�finition :  Grand  talus  marquant  le  front  et  la  structure  principale  d�une  carri�re : gravi�re (talus), mine � ciel ouvert (talus), talus de carri�re.
S�lection : Les talus de carri�re principaux sont inclus.
Mod�lisation  g�om�trique  :  Ligne  de  rupture  de  pente  amont  (la  limite  aval  d�un talus n�est jamais repr�sent�e). L�objet est orient� de mani�re � ce que le cot� aval soit sur sa droite.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la ligne orographique.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Pr�cision altim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la ligne de rupture de pente'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale de la ligne orographique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale de la ligne orographique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.G_OROGRAPHIE  
---- B.5.G.2 ORONYME
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_oronyme_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_oronyme_bdt_')) = 'n_oronyme_bdt_'
	THEN
--- Index
	nom_table := 'n_oronyme_bdt';
	tb_index := array['id',
		'origin_nom',
		'importance',
		'nature'
		];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''D�tail du relief portant un nom de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection :  Tous  les  d�tails  orographiques  dont  le  nom  figure  sur  la  carte  au  1 : 25 000  en  service.
- Cap : Pr�dominance dans le contour d�une c�te : cap, pointe, promontoire.
- Cirque : D�pression semi-circulaire, � bords raides.
- Col : Point de passage impos� par la configuration du relief : col, passage.
- Cr�te : Ligne de partage des eaux : cr�te, ar�te, ligne de fa�te.
- D�pression : D�pression naturelle du sol : cuvette, bassin ferm�, d�pression, doline.
- Dune : Monticule de sable sur les bords de la mer.
- Escarpement : Escarpement  du  relief :  barre  rocheuse,  escarpement  rocheux,  face  abrupte, falaise.
- Gorge : Vall�e �troite et encaiss�e : canyon, cluse, d�fil�, gorge.
- Grotte : Grotte naturelle ou excavation : aven, cave, gouffre, grotte.
- Ile : �le, �lot ou presqu��le.
- Isthme : Bande de terre �troite entre deux mers, r�unissant deux terres : cordon littoral, isthme.
- Montagne : D�signe  une  montagne  ou  un  massif  de  mani�re  globale  et  non  un  sommet en particulier (voir sommet).
- Pic : Sommet pointu d�une montagne : aiguille, pic, piton.
- Plage : Zone littorale marqu�e par le flux et le reflux des mar�es : gr�ve, plage.
- Plaine : Zone de surface terrestre caract�ris�e par une relative plan�it� : plaine, plateau.
- R�cif : Rocher   situ�   en   mer   ou   dans   un   fleuve,   mais   dont   une   partie, faiblement �merg�e, peut constituer un obstacle ou un rep�re : brisant, r�cif, rocher marin.
- Rochers : Zone ou d�tail caract�ris� par une nature rocheuse mais non verticale : chaos, �boulis, pierrier, rocher.
- Sommet : Point  haut  du  relief  non  caract�ris�  par  un  profil  abrupt  (voir  la  nature  Pic) : colline, mamelon, mont, sommet.
- Vall�e : Espace  entre  deux  ou  plusieurs  montagnes. Forme  d�finie  par  la  convergence  des  versants  et  qui  est,  ou  a  �t�  parcourue  par  un  cours  d�eau : combe, ravin, val, vall�e, vallon, thalweg.
- Versant : Plan inclin� joignant une ligne de cr�te � un thalweg : coteau, versant.
- Volcan : Toute  forme  de  relief  t�moignant  d�une  activit�  volcanique :  crat�re, volcan.

Mod�lisation g�om�trique : Centre du d�tail nomm�.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du toponyme.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.H_ADMINISTRATIF  
---- B.5.H.1 ARRONDISSEMENT
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_arrondissement_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_arrondissement_bdt_')) = 'n_arrondissement_bdt_'
	THEN
--- Index
	nom_table := 'n_arrondissement_bdt_';
	tb_index := array['id'];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Arrondissement municipal pour Lyon, Paris & Marseille de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Arrondissement municipal: subdivision administrative de certaines communes.
Les arrondissements municipaux sont g�r�s par l�INSEE comme des communes.

S�lection : Arrondissements municipaux de Paris, Lyon et Marseille.
Remarque  sur  la  mod�lisation  g�om�trique :  Les  contours  des  arrondissements  de  la  BD TOPO�  et  de  la  BD  PARCELLAIRE�  ne  sont  pas  exactement  superposables;  en  effet, 
l�origine   de   la   donn�e   n�est   pas   la   m�me   pour   ces   deux   bases   (cadastre   pour   la   BD PARCELLAIRE�).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de l�arrondissement.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom de l�arrondissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.code_insee IS ''Code Insee'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.H_ADMINISTRATIF  
---- B.5.H.2 CHEF_LIEU
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_chef_lieu_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_chef_lieu_bdt_')) = 'n_chef_lieu_bdt_'
	THEN
--- Index
	nom_table := 'n_chef_lieu_bdt';
	tb_index := array['id',
		'id_com',
		'origin_nom',
		'nature',
		'nom',
		'importance'
		];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Chef-lieu de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Centre de la zone d�habitat dans laquelle se trouve la mairie de la commune. 
Dans certains cas, le chef-lieu n�est pas dans la commune.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du chef-lieu.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id_com IS ''Identifiant de la commune � laquelle se rapporte le chef-lieu'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du chef lieu (commune, canton, pr�fecture, sous-pr�fecture)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du chef lieu'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.H_ADMINISTRATIF  
---- B.5.H.3 COMMUNE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_commune_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_commune_bdt_')) = 'n_commune_bdt_'
	THEN
--- Index
	nom_table := 'n_commune_bdt';
	tb_index := array['id',
		'code_insee',
		'statut',
		'arrondisst',
		'depart',
		'region',
		'popul'
		];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Commune de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Plus  petite  subdivision  du  territoire,  administr�e  par  un  maire,  des  adjoints  et  un  conseil municipal.

S�lection : Toutes les communes sont retenues.
Remarque sur la mod�lisation g�om�trique : Les contours des communes de la BD TOPO� et de  la  BD  PARCELLAIRE�  ne  sont  pas  exactement  superposables;  en  effet,  l�origine  de  la donn�e n�est pas la m�me pour ces deux bases (cadastre pour la BD PARCELLAIRE�).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la commune.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Pr�cision planim�trique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.code_insee IS ''Code Insee de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.statut IS ''Statut de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.arrondisst IS ''Nom de l�arrondissement de rattachement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.depart IS ''Nom du d�partement de rattachement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.region IS ''Nom de la r�gion de rattachement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.popul IS ''Population de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.1 PAI_ADMINISTRATIF_MILITAIRE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_administratif_militaire_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_administratif_militaire_bdt_')) = 'n_pai_administratif_militaire_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_administratif_militaire_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t administratif ou militaire de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation d�un  �tablissement,  site  ou  zone  ayant  un  caract�re  public  ou  administratif ou militaire.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Borne : Borne nomm�e :  borne  fronti�re,  point  de  triangulation,  point  fronti�re.
- Bureau ou h�tel des postes : Bureau  de  poste  ouvert  au  public:  Bureau  de  poste,  h�tel  des  postes, agence postale.
Seuls  les  bureaux  de  poste  ouverts  en  permanence  sont  inclus.  En g�n�ral, dans les agglom�rations, seules les postes centrales sont incluses.
- Caserne de pompiers : B�timent ayant ou non un bureau ou une permanence et qui est enti�rement   concern�   par   l�activit�   du   corps   des   Sapeurs-Pompiers.
- Divers public ou administratif : B�timent ou zone � caract�re public ou administratif, qui n�est ni d�fini  par  une  autre  classe  de  PAI,  ni  par  une  autre  valeur  d�attribut NATUREde   la   pr�sente   classe   (administratif   ou   militaire):  UNESCO,  Parlement  Europ�en,  minist�re,  direction  minist�rielle,  Assembl�e  nationale,  S�nat,  cit�  administrative,  poste de douane, capitainerie, salle de spectacle, ...
En  g�n�ral  les  �tablissements  et  les  sites  retenus  ont  une  importance  ou  une  notori�t�  d�ordre  national  ou  r�gional  ou  une  surface au sol d�au moins 1000 m2 environ. 
- Enceinte militaire : Zone  en  permanence  r�serv�e  pour  les  rassemblements  de  troupes  de  toutes  les  armes,  soit  pour  des  man�uvres,  des  exercices (camp d�instruction), soit pour des essais, des �tudes : base,  camp,  caserne,  d�p�t  de  mat�riels,  terrain  permanent  d�entra�nement,   caserne   de   CRS,   caserne   de   gendarmes   mobiles, ...
Les champs de tir sont exclus ainsi que les propri�t�s de l�arm�e qui ne sont indiqu�es d�aucune mani�re sur le terrain (ni cl�tures, ni   barri�re,   ni   pancartes,...)   et   ne   faisant   l�objet   d�aucune  restriction particuli�re.  

- Etablissement p�nitentiaire : �tablissement   clos   am�nag�   pour   recevoir   des   d�linquants   condamn�s  �  une  peine  privative  de  libert�  ou  des  d�tenus  en  instance de jugement : maison d�arr�t, prison.
Les annexes sont exclues.
- Gendarmerie : Caserne   o�   les   gendarmes   sont   log�s;  bureaux  o�  ils remplissent    leurs    fonctions    administratives    :    gendarmerie,    gendarmerie d�autoroute.
D�finition  de  l�emprise  du  site : surface  de  l�ensemble  de  la  caserne,  g�n�ralement  d�limit�e  par  une  cl�ture  et  incluant  logements et bureaux. 
- H�tel de d�partement : B�timent o� si�ge le conseil g�n�ral.
Seul le b�timent principal est inclus. Les annexes ne le sont pas, sauf   �ventuellement   une   annexe   situ�e   dans   une   autre   agglom�ration  lorsqu�elle  a une  fonction  proche  de  celle  du  si�ge.
- H�tel de r�gion : B�timent o� si�ge le conseil r�gional.
Seul le b�timent principal est inclus. Les annexes ne le sont pas, sauf   �ventuellement   une   annexe   situ�e   dans   une   autre   agglom�ration  lorsqu�elle  a  une  fonction proche  de  celle  du  si�ge.
- Mairie : B�timent  o�  se  trouvent  le  bureau  du  maire,  les  services  de  l�administration  municipale  et  o�  si�ge  normalement  le  conseil  municipal : mairie, mairie annexe, h�tel de ville.
Les mairies annexes sont incluses (fr�quentes dans les grandes villes   ou   dans   les   anciens   chefs-lieux   de   commune   ayant   fusionn�,   elles   offrent   des   services   similaires   aux   mairies   principales).
Les annexes de la mairie (services techniques,...) sont exclues.
En g�n�ral le b�timent saisi est celui de l�accueil du public.
- Maison foresti�re : Maison g�r�e par l�office national des for�ts. Les maisons de garde occup�es par au moins un agent de l�ONF sont incluses. 
Les  bureaux  de  l�ONF,  les  domiciles  d�agents  servant  aussi  de  bureau,  sont  exclus  lorsqu�ils  ne  sont  pas  situ�s  dans  une  maison foresti�re.
- Ouvrage militaire : Ouvrages et installations militaires.
- Palais de justice : B�timent o� l�on rend la justice : palais de justice, tribunal. Seule  la  justice  p�nale  est  trait�e.  Les  tribunaux  administratifs  sont exclus.
- Poste ou h�tel de police : �tablissement  occup�  par  un  commissaire  de  police  (officier  de  police judiciaire charg� de faire observer les r�glements de police et  de  veiller  au  maintien  de  la  paix  publique):  h�tel  de  police  nationale, commissariat, CRS d�autoroute, de port ou d�a�roport.
Les  b�timents  h�bergeant  uniquement  la  police  municipale  sont  
exclus. Les casernes de CRS et de gendarmes mobiles prennent la  valeur  �enceinte  militaire�  et  les  gendarmeries  la  valeur  � gendarmerie �. 
- Pr�fecture : �tablissement qui abrite l�ensemble des services de l�administration   pr�fectorale :   pr�fecture,   pr�fecture   annexe,   pr�fecture maritime.
- Pr�fecture de r�gion : �tablissement  qui  abrite  le  si�ge  de  l�administration  civile  de  la  r�gion.
- Sous-pr�fecture : �tablissement  qui  abrite  les  services  administratifs  du  sous-pr�fet.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.2 PAI_CULTURE_LOISIRS
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_culture_loisirs_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_culture_loisirs_bdt_')) = 'n_pai_culture_loisirs_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_culture_loisirs_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t culture ou loisir de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation  d�un  �tablissement  ou  lieu  sp�cialement  am�nag�  pour  une  activit�  culturelle, touristique ou de loisirs

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE :  
- Camping : Emplacement   am�nag�   pour   la   pratique   du   camping   d�une superficie de plus de 2 ha.
- Construction : Construction   nomm�e   habit�e   ou   associ�e   �   un   groupe   d�habitations : construction diverse, pigeonnier, moulin � vent.
- Digue : Digue, m�le, jet�e.
- Dolmen : Monument  m�galithique  form�  d�une  grande  pierre  plate  pos�e  sur d�autres pierres dress�es verticalement. Les all�es couvertes sont incluses.
- Espace public : Large  espace  d�couvert  urbain  d�sign�  par  un  toponyme  o�  aboutissent  plusieurs  rues,  ferm�  �  la  circulation  automobile,  constituant un lieu remarquable : place, square, jardin, parc, parc communal,    parc    intercommunal,    parc    d�partemental,    parc interd�partemental.
Seuls les espaces publics poss�dant un toponyme sont retenus. Les  parcs  �  vocation  commerciale  sont  exclus  (voir  la  valeur  Parc  de  loisirsci-dessous),  de  m�me  que  les  parcs  naturels  (r�serves,  parcs  nationaux,  parcs  naturels  r�gionaux)  qui  sont  trait�s en PAI_ESPACE_NATUREL.
- Habitation troglodytique : Excavation   naturelle   ou   creus�e   dans   le   roc   (caverne,   grotte), habit�e ou anciennement habit�e.
- Maison du parc : B�timent  ouvert  au  public  et  g�r�  par  un  Parc  National  ou  R�gional.
- Menhir : Pierre allong�e, dress�e verticalement.Les alignements en cromlech sont inclus.
- Monument : Monument   sans   caract�re   religieux   particulier:   monument,   statue, st�le.
- Mus�e : �tablissement  ouvert  au  public  exposant  une  grande  collection  d�objets,  de  documents,  etc.,  relatifs  aux  arts  et  aux  sciences  et  pouvant servir � leur histoire.
Sont inclus : tous  les  mus�es  contr�l�s  ou  supervis�s  par  le  minist�re  de  la  Culture (mus�es nationaux, class�s, contr�l�s,...) ;les  mus�es  relevant  de  certains  minist�res  techniques  ou  de  l�assistance publique (mus�e de l�arm�e, de la marine) ;les mus�es priv�s ou associatifs ayant une grande notori�t� ;les �comus�es.
- Parc des expositions : Lieu   d�exposition   ou   de   culture   :   centre   culturel,   parc   des   expositions.
- Parc de loisirs : Parc  �  caract�re  commercial  sp�cialement  am�nag�  pour  les  loisirs:  centre  permanent  de  jeux,  parc  d�attraction,  parc  de  d�tente, centre de loisirs.
Seuls   les   parcs   dont   la   superficie   exc�de   4ha   et   dot�s   d��quipements cons�quents sont inclus. 
Les       parcs       publics       (jardins,       parcs       communaux,       d�partementaux...)  sont  exclus  (voir  la  valeur  Espacepublicci-dessus).
- Parc zoologique : Parc  ouvert  au  public,  o�  il  est  possible  de  voir  des  animaux  sauvages vivant en captivit� ou en semi-libert�.
Tous les parcs ouverts au public sont inclus.
- Refuge : Refuge, refuge gard�, abri de montagne nomm�.
- Vestiges arch�ologiques : Vestiges arch�ologiques, fouilles, tumulus, oppidum.
- Village de vacances : �tablissement   de   vacances,   comprenant   des   �quipements   sportifs ou de d�tente cons�quents dont le gestionnaire est priv� ou public : village de vacances, colonie de vacances. 
Les  h�tels  et  les  � camps  de  vacances�  sont  exclus,  ainsi  que  les  �tablissementsdont  la  capacit�  de  prise  en  charge  est  inf�rieure � 300 personnes.
- NR :  
Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.3 PAI_ESPACE_NATUREL
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_espace_naturel_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_espace_naturel_bdt_')) = 'n_pai_espace_naturel_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_espace_naturel_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t espace naturel de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation  d�un  lieu-dit  non  habit�  dont  le  nom  se  rapporte  ni  �  un  d�tail  orographique ni � un d�tail hydrographique.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Arbre : Arbre nomm� isol�, arbre remarquable.
- Bois : Bois ou for�t.
- Lieu-dit non habit� : Lieu-dit quelconque,  dont  le  nom  est  g�n�ralement  attach�  �  des terres : lieu-dit non habit�, plantation, espace cultiv�.
- Parc : Espace r�glement�, g�n�ralement libre d�acc�s pour le public et  o�  la  nature  fait  l�objet  d�une  protection  sp�ciale :  parc  naturel  r�gional,  parc  national,  r�serve  naturelle nationale  ou  r�gionale, parc naturel marin.
Les parcs � vocation commerciale ne sont pas pris en compte dans cet attribut.
- Pare-feu : Dispositif  destin�  �  emp�cher  la  propagation  d�un  incendie  (g�n�ralement,  ouverture  pratiqu�e  dans  le  massif  forestier  menac�).
- Point de vue : Endroit  d�o�  l�on  jouit  d�une  vue  pittoresque :  point  de  vue,  table d�orientation, belv�d�re.
Seuls   les   points   de   vue   am�nag�s   (table   d�orientation,   bancs,...) sont inclus
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.4 PAI_GESTION_EAUX
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_gestion_eaux_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_gestion_eaux_bdt_')) = 'n_pai_gestion_eaux_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_gestion_eaux_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t pour la gestion de l�eau de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation d�une construction ou site li�s � l�approvisionnement, au traitement de l�eau pour diff�rents besoins (agricole, industriel, consommation) ou � l��puration des eaux us�es avant rejet dans la nature.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Station de pompage : Site  incluant  au  moins  une  construction  abritant  une  installation  de  captage  ou  de  pompage  des  eaux : captage, pompage pour besoins agricole ou industriel, pompage pour production eau potable.
Toutes    les    stations    de    pompage    servant    �    l�alimentation  en  eau  potable  d�une  collectivit�  sont  incluses.
- Usine de traitement des eaux : �tablissement  comprenant  des  installations  destin�es  �  rendre  l�eau  propre  �  la  consommation  (usine  de  traitement  des  eaux)  ou  �  �purer  des  eaux  us�es  avant  leur  rejet  dans  la  nature  (stations  d��puration,  de  lagunage) :  usine  de  traitement  des  eaux,  station  d��puration, station de lagunage.
Les stations d��puration et de lagunage sont incluses. Les stations traitant l�eau afin de la rendre propre � la consommation sont incluses lorsqu�elles comprennent des  installations  cons�quentes  (usines  comprenant  bassins, filtrages, traitements m�caniques).
Sont  exclues  les  stations  lorsqu�il  s�agit  uniquement  d�un traitement chimique d�appoint effectu� au niveau d�un captage ou d�un r�servoir. 
Les stations de rel�vement sont �galement exclues.
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.5 PAI_HYDROGRAPHIE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_hydrographie_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_gestion_eaux_bdt_')) = 'n_pai_hydrographie_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_hydrographie_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t hydrographique de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation se rapportant � un d�tail hydrographique.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Amer : Point  de  rep�re  visible  de  la mer:  amer,  bou�e,  balise,  phare,  feu,  tourelle.
- Baie : Espace marin p�n�trant entre les terres : anse, baie, calanque, crique, golfe.
- Banc : En  mer  ou  sur  un  fleuve,  relief  sous-marin  non  rocheux  repr�sentant  un danger potentiel pour la navigation : banc, hauts-fonds.
- Cascade : Cascade, chute d�eau
- Embouchure : Embouchure d�un fleuve : delta, embouchure, estuaire.
- Espace maritime : Espace maritime, mer, oc�an, passe.
- Glacier : Nom  d�un  glacier  ou  d�un  d�tail  relatif  �  un  glacier :  crevasse,  glacier,  moraine,  n�v�, s�rac.
- Lac : �tendue d�eau terrestre : bassin, �tang, lac, mare.
- Marais : Zone humide : marais, mar�cage, saline.
- Perte : Lieu o� dispara�t, o� se perd un cours d�eau, qui r�appara�t ensuite, en formant une r�surgence, apr�s avoir effectu� un trajet souterrain. 
- Point d�eau : Tout  point  d�eau  naturel  ou  artificiel :  citerne,  fontaine,  lavoir, puits, r�surgence, source, source capt�e. 
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.6 PAI_INDUSTRIEL_COMMERCIAL
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_industriel_commercial_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_industriel_commercial_bdt_')) = 'n_pai_industriel_commercial_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_industriel_commercial_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t industriel et commercial de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation d�un b�timent, site ou zone � caract�re industriel ou commercial.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Aquaculture : Site am�nag� pour l��levage piscicole ou la culture d�esp�ces animales  marines  (coques,  coquilles  Saint-Jacques,  hu�tres,  moules,   palourdes,...):   bouchot,   parc   �   hu�tres,   zone   conchylicole, zone mytilicole, zone ostr�icole.
Toutes les zones de plus de 3 ha poss�dant des installations fixes de p�che et d�limit�es par des alignements de pieux, les parcs � hu�tres, les bassins.
Les installations de p�che au carrelet sont exclues.
- Carri�re : Lieu   d�o�   l�on   extrait   �   ciel   ouvert   des   mat�riaux   de   construction  (pierre,  roche):  carri�re,  sabli�re,  ballasti�re,  gravi�re.
Toutes  les  carri�res  de  plus  de  3  ha  en  exploitation  sont  incluses.
La  d�finition  de  l�enceinte  s�appuie  sur  les  fronts  de  taille (voir aussi la classe LIGNE_OROGRAPHIQUE) et sur la zone d�exploitation visible sur les photographies a�riennes.
- Centrale �lectrique : Usine   o�   l�on   produit   de   l��nergie   �lectrique : centrale   hydro�lectrique,  centrale  thermique,  centrale  nucl�aire,  parc  �olien, centrale photovolta�que.
Les centrales �lectriques souterraines sont exclues.
- Divers commercial : B�timent  ou  zone  �  caract�re  commercial:  hypermarch�,  grand    magasin,    centre    commercial,    zone    �    caract�re    commercial.
Au  moins  tous  les  sites  incluant  un  � grand  magasin 
�,  un  
hypermarch�, ou une zone d�activit� commerciale d�au moins 5 ha. Les hypermarch�s isol�s ayant une surface de vente de plus   de   4000 m2 sont   inclus.   (voir   �galement   la   valeur   d�attribut March� ci-dessous).
- Divers industriel : Organisme  ou  entreprise  �  caract�re  industriel  non  distingu�  de fa�on sp�cifique : centre de recherche, d�p�t, coop�rative (vinicole,   c�r�ali�re...),   �levage   avicole,   haras,   abattoir,   d�ch�terie.
Tous  les  sites  d�importance  ou  de  notori�t�  nationale  ou  r�gionale,   confirm�e   par   un   toponyme,   et   de   surface   sup�rieure   �   3   ha   sont   retenus   (le   toponyme   n�est   pas   n�cessairement retenu).
- Haras national : Lieu  ou  �tablissement  destin�  �  la  reproduction  de  l�esp�ce  chevaline,   �   l�am�lioration   des   races   de   chevaux   par   la   s�lection des �talons. Tous les haras nationaux sont inclus.
L�enceinte  comprend  l�ensemble  des  installations  (man�ge,  �curies, piste d�entra�nement,...).
- Marais salants : Zone  constitu�e  de  bassins  creus�s  �  proximit�  des  c�tes  pour extraire le sel de l�eau de mer par �vaporation.
Les  zones  de  marais  salants  de  moins  de  3  ha  sont  exclues.  Les  anciens  marais  salants  qui  ne  sont  plus  en  activit�  sont  exclus.
- March� : Tout     ensemble     construit     dont     la     finalit�     est     la     commercialisation    de    gros    ou    de    d�tail    de    denr�es    alimentaires:   march�   couvert,   march�   d�int�r�t   national,   march�  d�int�r�t  r�gional,  halle,  foire,  zone  d�exposition  �  caract�re permanent, cri�e couverte.
- Mine : Lieu  d�o�  l�on  extrait  des  minerais :  mine  de  houille,  mine  de  lignite, crassier, entr�e de mine, terril.
Les mines � ciel ouvert de plus de 10 ha sont incluses.  Les mines souterraines sont exclues.
- Usine : �tablissement  domin�  par  une  activit�  industrielle  (fabrication  d�objets  ou  de  produits,  transformation  ou  conservation  de  mati�res   premi�res):   atelier,   fabrique,   manufacture,   mine   avec infrastructure b�tie, usine, scierie.
Les   sites   dont   la   superficie   est   inf�rieure   �   5   ha   sont   g�n�ralement exclus.
- Zone industrielle : Regroupement  d�activit�s  de  production  sur  l�initiative  des  collectivit�s  locales  ou  d�organismes  parapublics  (chambres  de   commerce   et   d�industrie)   et   portant   un   nom : zone artisanale, zone industrielle.
Les   sites   dont   la   superficie   est   inf�rieure   �   5   ha   sont g�n�ralement exclus
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.7 PAI_OROGRAPHIE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_orographie_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_orographie_bdt_')) = 'n_pai_orographie_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_orographie_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t orographique de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation d�un d�tail du relief.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Cap : Pr�dominance dans le contour d�une c�te : cap, pointe, promontoire.
- Cirque : D�pression semi-circulaire, � bords raides.
- Col : Point de passage impos� par la configuration du relief : col, passage.
- Cr�te : Ligne de partage des eaux : cr�te, ar�te, ligne de fa�te.
- D�pression : D�pression naturelle du sol : cuvette, bassin ferm�, d�pression, doline.
- Dune : Monticule de sable sur les bords de la mer.
- Escarpement : Escarpement  du  relief :  barre  rocheuse,  escarpement  rocheux,  face abrupte, falaise.
- Gorge : Vall�e �troite et encaiss�e : canyon, cluse, d�fil�, gorge.
- Grotte : Grotte naturelle ou excavation : aven, cave, gouffre, grotte.
- Ile : �le, �lot ou presqu��le.
- Isthme : Bande de terre �troite entre deux mers, r�unissant deux terres : cordon littoral, isthme.
- Montagne : D�signe  une  montagne  ou  un  massif  de  mani�re  globale  et  non  un  sommet en particulier (voir sommet).
- Pic : Sommet pointu d�une montagne : aiguille, pic, piton. 
- Plage : Zone littorale marqu�e par le flux et le reflux des mar�es : gr�ve, plage.
- Plaine : Zone de surface terrestre caract�ris�e par une relative plan�it� : plaine, plateau.
- R�cif : Rocher   situ�   en   mer   ou   dans   un   fleuve,   mais   dont   une   partie, faiblement �merg�e, peut constituer un obstacle ou un rep�re : brisant, r�cif, rocher marin.
- Rochers : Zone ou d�tail caract�ris� par une nature rocheuse mais non verticale : chaos, �boulis, pierrier, rocher.
- Sommet : Point  haut  du  relief  non  caract�ris�  par  un  profil  abrupt  (voir  la  nature  Pic)  : colline, mamelon, mont, sommet.
- Vall�e : Espace  entre  deux  ou  plusieurs  montagnes. Forme  d�finie  par  la  convergence  des  versants  et  qui  est,  ou  a  �t�  parcourue  par  un  cours  d�eau : combe, ravin, val, vall�e, vallon, thalweg.
- Versant : Plan inclin� joignant une ligne de cr�te � un thalweg : coteau, versant.
- Volcan : Toute  forme  de  relief  t�moignant  d�une  activit�  volcanique :  crat�re,  volcan.
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.8 PAI_RELIGIEUX
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_religieux_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_religieux_bdt_')) = 'n_pai_religieux_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_religieux_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t religieu de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation d�un b�timent r�serv� � la pratique d�une religion.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Croix : Monument religieux : croix, calvaire, vierge, statue religieuse.
- Culte catholique ou orthodoxe : B�timent   r�serv�   �   l�exercice   du   culte   catholique   ou   orthodoxe :  �glise,  cath�drale,  basilique,  chapelle,  abbaye,  oratoire.
- Culte protestant : B�timent  r�serv�  �  l�exercice  du  culte  protestant:  temple  (protestant), �glise r�form�e.
- Culte isra�lite : B�timent r�serv� � l�exercice du culte isra�lite : synagogue.
- Culte islamique : B�timent r�serv� � l�exercice du culte islamique : mosqu�e.
- Culte divers : B�timent  r�serv�  �  l�exercice  d�un  culte  religieux  autre  que  chr�tien,  islamique  ou  isra�lite :  temple  bouddhiste,  temple  hindouiste.
- Tombeau : Cimeti�re,  tombe  ou  tombeau  nomm� :  cimeti�re,  tombe,  tombeau, ossuaire.
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.9 PAI_SANTE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_sante_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_sante_bdt_')) = 'n_pai_sante_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_sante_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t de sant� de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation d�un �tablissement thermal ou de type hospitalier.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Etablissement hospitalier : Autres    �tablissements    relevant    de    la    loi    hospitali�re : sanatorium,  a�rium,hospice,  maison  de  retraite  (MAPA  et  EHPA), �tablissements de convalescence ou de repos.
Tous  les  �tablissements  assurant  les  soins  et  l�h�bergement  ou les soins seulement sont inclus.
- Etablissement thermal
�tablissement   o�   l�on   utilise   les   eaux   m�dicinales   (eaux   min�rales,  chaudes  ou  non):  �tablissement  thermal,  centre  de thalassoth�rapie.
Seuls  sont  inclus  les  �tablissements  agr��s  par  la  S�curit�  Sociale.
- H�pital : �tablissement public ou priv�, o� sont effectu�s tous les soins m�dicaux  et  chirurgicauxlourds  et/ou  de  longue  dur�e,  ainsi  que  les  accouchements:  centre  hospitalier,  h�pital,  h�pital  psychiatrique, CHU, h�pital militaire, clinique.
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.10 PAI_SCIENCE_ENSEIGNEMENT
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_science_enseignement_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_science_enseignement_bdt_')) = 'n_pai_science_enseignement_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_science_enseignement_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t de sant� de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation d�un �tablissement d�enseignement ou de recherche.

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Enseignement primaire : �tablissement    consacr�    �    l�enseignement    maternel    et  primaire:  �cole  primaire,  �cole  maternelle,  groupe  scolaire,  Institut M�dico-P�dagogique (I.M.P.).
Tous  les  �tablissements  d�enseignement  primaire,  publics,  confessionnels   ou   priv�s,   ayant   un   contrat   simple   ou   d�association avec l��tat sont inclus. Les cr�ches sont exclues.
- Enseignement secondaire : �tablissement    consacr�    �    l�enseignement    secondaire : coll�ge, lyc�e.
Tous  les  �tablissements  d�enseignement  secondaire  publics,  confessionnels   ou   priv�s,   ayant   un   contrat   simple   ou   d�association avec l��tat sont inclus.
- Enseignement sup�rieur : �tablissement  consacr�  �  l�enseignement  sup�rieur:  facult�,  centre universitaire, institut, grande �cole, ...
Tous  les  �tablissements  d�enseignement  sup�rieur  publics,  confessionnels   ou   priv�s,   ayant   un   contrat   simple   ou   d�association avec l��tat sont inclus. 
Les  cours  du  soir,  les  cit�s  et  les  restaurants  universitaires  sont exclus.
- Science : �tablissement  scientifique  ou  technique  nomm�  :  centre  de  recherche, laboratoire, observatoire, station scientifique.
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;
	
---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.11 PAI_SPORT
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_sport_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_sport_bdt_')) = 'n_pai_sport_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_sport_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t transport de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation  d�un �tablissement ou lieu sp�cialement am�nag� pour la pratique d�une ou de plusieurs activit�s sportives. 

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Golf :Terrain ouvert au public et consacr� � la pratique du golf.  
Les terrains de moins de 6 trous et les minigolfs sont exclus. 
- Hippodrome : Lieu  ouvert  au  public  et  consacr�  aux  courses  de  chevaux. 
Seuls  les  hippodromes  poss�dant  des  am�nagements cons�quents (tribunes, b�timents sp�cifiques) sont inclus. 
- Piscine : Grand  bassin  de  natation,  et  ensemble  des  installations  qui l�entourent : piscine couverte, piscine d�couverte. 
Toutes les piscines ouvertes au public et ayant un bassin au moins de 25 m ou plus sont incluses.  
Les  piscines  des  centres  de  vacances  ou  des  h�tels  sont exclues (voir la classe TERRAIN_SPORT). 
- Stade : Grande enceinte, terrain am�nag� pour la pratique des sports, et  le  plus  souvent  entour�  de  gradins,  de  tribunes :  stade, terrain  de  sports,  v�lodrome  d�couvert,  circuit  auto-moto, complexe sportif pluridisciplinaire. 
Seules  les  enceintes  incluant  des  am�nagements cons�quents (piste � construite �, tribunes,�) sont incluses. 
Les terrains d�entra�nement incluant seulement 2 ou 3 terrains de  football  et  de  petits  vestiaires  sont  exclus  (voir  aussi  la classe TERRAIN_SPORT) 
- NR : Non renseign�e, l�information est manquante dans la base.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.12 PAI_TRANSPORT

SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_transport_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_transport_bdt_')) = 'n_pai_transport_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_transport_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t zone d�habitation de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation  d�un �tablissement ou lieu sp�cialement am�nag� pour la pratique d�une ou de plusieurs activit�s sportives. 

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- A�rodrome militaire : Tout terrain ou plan d�eau r�serv�s � l�arm�e sp�cialement am�nag� pour l�atterrissage, le d�collage et les man�uvres des  a�ronefs  y  compris  les  installations  annexes  qu�il  peut comporter  pour  les  besoins  du  trafic  et  le  service  des a�ronefs : a�rodrome militaire, h�liport militaire. 
- A�rodrome non militaire : Tout  terrain  ou  plan  d�eau  sp�cialement  am�nag�  pour l�atterrissage, le d�collage et les man�uvres des a�ronefs y compris  les  installations  annexes  qu�il  peut  comporter  pour les  besoins  du  trafic  et  le  service  des  a�ronefs  : altiport, a�rodrome non militaire, h�liport.  
Ne  sont  pas  pris  en  compte  les  a�ro-clubs,  les  terrains  de vol � voile, les pistes d�ULM. 
- A�roport international : A�rodrome de statut international sur lequel ont �t� pr�vues des  installations  en  vue  de  l�abri,  de  l�entretien  ou  de  la r�partition  des  a�ronefs,  ainsi  que  pour  la  r�ception, l�embarquement  et  le  d�barquement  des  passagers,  le chargement et le d�chargement des marchandises. 
- A�roport quelconque : A�rodrome  sur  lequel  ont  �t�  pr�vues  des  installations  en vue de l�abri, de l�entretien ou de la r�partition des a�ronefs, ainsi  que  pour  la  r�ception,  l�embarquement  et  le d�barquement  des  passagers,  le  chargement  et  le d�chargement des marchandises. 
- Aire de service : Espace  am�nag�  �  l��cart  des  chauss�es,  notamment  des autoroutes, pour permettre aux usagers de se ravitailler en carburant. 
Emprise de l�aire. Les contours de la surface ne s�appuient jamais sur des tron�ons de route (qui repr�sentent l�axe des chauss�es). 
- Aire de repos : Espace  am�nag�  (pr�sence  d�un  point  d�eau  obligatoire)  � l��cart  des  chauss�es,  notamment  des  autoroutes,  pour permettre aux usagers de s�arr�ter et de se reposer. 
Emprise de l�aire. Les contours de la surface ne s�appuient jamais sur des tron�ons de route qui repr�sentent l�axe des chauss�es. 
- Barrage : Obstacle  artificiel  plac�  en  travers  d�un  cours  d�eau : barrage, �cluse, vanne. 
- Carrefour : N�ud du r�seau routier : carrefour nomm�. 
- Echangeur : �changeur autoroutier portant un nom ou un num�ro. 
- Gare routi�re : Ensemble  des  installations  destin�es  �  l�embarquement  et au  d�barquement  de  voyageurs  en  car  ou  en  bus  en  un point d�termin�. 
Ne  sont  pas  retenues  les  gares  routi�res  des  bus  de  ville, des bus scolaires, de la RATP et les d�p�ts de bus. 
- Gare voyageurs uniquement : �tablissement ferroviaire ou de transport par c�ble assurant avec  ou  sans  personnel  un  service  commercial  de voyageurs :  gare,  station,  point  d�arr�t,  station  r�seau  ferr� urbain, gare t�l�ph�rique. 
Toutes les gares et arr�ts ferroviaires en service sont inclus. Mod�lisation g�om�trique : Point centr� sur la gare ou sur la ligne ferroviaire dans le cas d�un arr�t. 
- Gare voyageurs et fret : �tablissement ferroviaire assurant un service commercial de voyageurs et de marchandises. (Uniquement le b�timent principal ouvert au public.) 
- Gare fret uniquement : �tablissement ferroviaire assurant un service commercial de marchandises : gare de fret, point de desserte. Le fret a�rien ou maritime est exclu. 
- Parking : Une  aire  de  stationnement  ou  parking  est  une  zone am�nag�e  pour  le  stationnement  des  v�hicules :  aire  de stationnement, parking, parking souterrain, parking � �tages. 
Tous  les  parkings  publics  nomm�s  de  plus  de  100  places sont inclus qu�ils soient souterrains ou a�riens (ex. parkings municipaux), Les parkings de plus de 100 places associ�s � des  services  de  transport  (gares,  a�roports)  sont  retenus m�me s�ils n�ont pas de nom propre. 
Les  parkings  d�aires  de  repos  ou  de  service  ne  sont  pas retenus  (voir  les  valeurs  <Aire  de  repos>  et  <Aire  de service>). 
Les  parkings  appartenant  �  des  �tablissements  purement commerciaux  (ex :  parking  de  supermarch�)  sont  exclus (pour ces derniers, voir aussi la classe SURFACE_ROUTE). 
Un Parking est un objet ponctuel situ� au centre de l�aire de stationnement, ou � l�entr�e pour les parkings souterrains. Il est g�n�ralement associ� � une surface pour des parkings a�riens de plus de 5 ha.
- P�age : Barri�re  de  p�age.  Toutes  les  barri�res  de  p�age  sont repr�sent�es,  qu�elles  soient  ou  non  accompagn�es  d�un �largissement  de  la  chauss�e  ou  d�un  b�timent :  p�age d�autoroute, de pont, de route. 
Si aucun objet de la base n�est associ� au p�age (ni surface de route ni b�timent), le point d�activit� est saisi sur l�axe de la route au niveau de la barri�re de p�age.
Le  p�age  est  mod�lis�  par  une  surface  incluant  tous  les objets  associ�s  �  cette  fonction :  SURFACE_ROUTE BATI_REMARQUABLE ou les deux. 
- Pont : Ouvrage d�art permettant le franchissement d�une vall�e ou d�une voie de communication : pont, passerelle, viaduc, gu�, pont mobile. 
Seuls les ponts nomm�s sont saisis. 
- Port : Abri naturel ou artificiel am�nag� pour recevoir les navires, pour  l�embarquement  et  le  d�barquement  de  leur chargement : port de plaisance, port de p�che, port national, port priv�, port international, port militaire. 
- Rond-point : Rond-point,  place  de  forme  circulaire,  ovale  ou  semi-circulaire, ou carrefour giratoire. Un giratoire est form� d�un anneau central qui permet aux usagers de prendre n�importe quelle direction, y compris de faire un demi-tour. 
Seuls les ronds-points nomm�s sont retenus. 
- Station de m�tro : Station o� il est possible d�acc�der � un r�seau de m�tro ou de tramway : station de m�tro, arr�t de tramway.
On  saisit  un  seul  objet  "Station  de  m�tro"  m�me  s�il  y  a plusieurs  entr�es  distinctes,  �ventuellement  plusieurs ponctuels  "Station  de  m�tro"  pour  les  correspondances importantes  (ex :  Bastille) mais  un  seul  ponctuel  pour  une station de m�tro qui n�est pas une correspondance. 
- T�l�ph�rique : Syst�me de transport � traction par c�ble nomm� : remonte-pente, t�l�cabine, t�l�si�ge, t�l�ph�rique, t�l�ski. 
- Tunnel : Tunnel nomm�. 
- Voie ferr�e : Voie ferr�e nomm�e 
- NR : Non renseign�e, l�information est manquante dans la base. 
Aire d�accueil des gens du voyage, passage � niveau.

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.13 PAI_ZONE_HABITATION
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_pai_zone_habitation_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_pai_zone_habitation_bdt_')) = 'n_pai_zone_habitation_bdt_'
	THEN
--- Index
	nom_table := 'n_pai_zone_habitation_bdt';
	tb_index := array['id',
			'origine',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d�int�r�t du sport de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�signation  d�un �tablissement ou lieu sp�cialement am�nag� pour la pratique d�une ou de plusieurs activit�s sportives. 

S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Ch�teau : Ch�teau ou tour. Le lieu-dit, toujours nomm�, peut ne pas �tre habit�  ou  ne  plus  �tre  habit�  mais  n�est  pas  totalement  en ruines. 
- Grange : Construction  l�g�re :  abri,  baraquement,  cabane,  grange, hangar. 
Voir �galement la classe CONSTRUCTION_LEGERE. 
- Lieu-dit habit� : Groupe d�habitations nomm� situ� en dehors du chef-lieu de commune :  hameau,  habitation  isol�e,  ancien  chef-lieu  de commune. 
- Moulin : Moulin ou ancien moulin � eau. 
- Quartier : Quartier nomm� : cit�, faubourg, lotissement. 
- Ruines : B�timent ou construction en ruines. 
- NR : Non renseign�e, l�information est manquante dans la base.  

Mod�lisation  g�om�trique  :  Au  centre  de  l�objet  ponctuel,  du  b�timent  ou  au  centro�de  de  la  zone d�activit�.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit�  particuli�re (notamment � travers un toponyme �ventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

 ---- B.5.I_ZONE_ACTIVITE  
---- B.5.I.14 SURFACE_ACTIVITE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_surface_activite_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_surface_activite_bdt_')) = 'n_surface_activite_bdt_'
	THEN
--- Index
	nom_table := 'n_surface_activite_bdt';
	tb_index := array['id',
			'origine',
			'categorie'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Surface d�activit� de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
D�finition : Enceinte  d�un  �quipement  public,  d�un  site  ou  d�une  zone  ayant  un  caract�re administratif, culturel, sportif, industriel ou commercial. 

S�lection : Les sites ayant perdu leur fonction administrative, industrielle ou commerciale sont exclus (ancienne �cole, ancienne carri�re, �). 
Les enceintes limit�es � un seul b�timent sont exclues. 
En g�n�ral, la surface minimum pour une enceinte est de l�ordre de 1000m2. 
 
Mod�lisation g�om�trique : Limite apparente du site, seulement indicative. 
La  g�om�trie  de  l�enceinte  ne  saurait,  en  aucun  cas,  donner  la  limite  de  propri�t�  fonci�re  de l�organisme  d�crit.  La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicit� particuli�re (notamment � travers un toponyme �ventuel). 
Toute surface d�activit� contient un point d�activit� ou d�int�r�t mais un point d�activit� ou d�int�r�t ne  se  rapporte  pas  n�cessairement  �  une  surface  qui  est  indicative  et  doit  r�pondre  �  des crit�res de s�lection.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine de la surface d�activit� '';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.categorie IS ''Cat�gorie ou fonction de la surface d�activit� '';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.T_TOPONYMES   
---- B.5.T.1 LIEU_DIT_HABITE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_lieu_dit_habite_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_lieu_dit_habite_bdt_')) = 'n_lieu_dit_habite_bdt_'
	THEN
--- Index
	nom_table := 'n_lieu_dit_habite_bdt';
	tb_index := array['id',
			'origin_nom',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Lieu-dit habit� de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Ch�teau : Ch�teau ou tour. Le lieu-dit, toujours nomm�, peut ne pas �tre habit�  ou  ne  plus  �tre  habit�  mais  n�est  pas  totalement  en ruines. 
- Grange : Construction  l�g�re :  abri,  baraquement,  cabane,  grange, hangar. 
- Lieu-dit habit� : Groupe d�habitations nomm� situ� en dehors du chef-lieu de commune :  hameau,  habitation  isol�e,  ancien  chef-lieu  de commune. 
- Moulin : Moulin ou ancien moulin � eau. 
- Quartier : Quartier nomm� : cit�, faubourg, lotissement. 
- Ruines : B�timent ou construction en ruines.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du lieu-dit.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du lieu-dit habit�'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.T_TOPONYMES   
---- B.5.T.2 LIEU_DIT_NON_HABITE
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_lieu_dit_non_habite_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_lieu_dit_non_habite_bdt_')) = 'n_lieu_dit_non_habite_bdt_'
	THEN
--- Index
	nom_table := 'n_lieu_dit_non_habite_bdt';
	tb_index := array['id',
			'origin_nom',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Lieu-dit non habit� de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
S�lection : Voir les diff�rentes valeurs de l�attribut NATURE : 
- Barrage : Obstacle  artificiel  plac�  en  travers  d�un  cours  d�eau :  barrage, �cluse, vanne. 
- Croix : Monument religieux : croix, calvaire, vierge, statue religieuse. 
- Digue : Digue, m�le, jet�e. 
- Dolmen : Monument m�galithique form� d�une grande pierre plate pos�e sur d�autres pierres dress�es verticalement. Les all�es couvertes sont incluses. 
- Espace public : Large  espace  d�couvert  urbain  d�sign�  par  un  toponyme  o� aboutissent  plusieurs  rues,  ferm�  �  la  circulation  automobile, constituant  un  lieu  remarquable :  place,  square,  jardin,  parc, parc communal, parc intercommunal, parc d�partemental, parc interd�partemental. 
Seuls  les  espaces  publics  poss�dant  un  toponyme  sont retenus.  Les  parcs  �  vocation  commerciale  sont  exclus,  de m�me que les parcs naturels (r�serves, parcs nationaux, parcs naturels r�gionaux) qui sont trait�s en PAI_ESPACE_NATUREL. 
- Habitation troglodytique : Excavation naturelle ou creus�e  dans  le roc (caverne, grotte), habit�e ou anciennement habit�e. 
- Lieu-dit non habit� : Lieu-dit quelconque, dont le nom est g�n�ralement attach� � des terres : lieu-dit non habit�, plantation, espace cultiv�. 
- Marais salants : Zone constitu�e de bassins creus�s � proximit� des c�tes pour extraire le sel de l�eau de mer par �vaporation. 
Les  zones  de  marais  salants  de  moins  de  3  ha  sont  exclues. Les  anciens  marais  salants  qui  ne  sont  plus  en  activit�  sont exclus. 
- Mine : Lieu  d�o�  l�on  extrait  des  minerais :  mine  de  houille,  mine  de lignite, crassier, entr�e de mine, terril. 
Les mines � ciel ouvert de plus de 10 ha sont incluses.  Les mines souterraines sont exclues. 
- Ouvrage : militaire  Ouvrages et installations militaires. 
- Point de vue : Endroit d�o� l�on jouit d�une vue pittoresque : point de vue, table d�orientation, belv�d�re. 
Seuls  les  points  de  vue  am�nag�s  (table  d�orientation, bancs,�) sont inclus 
- Tombeau : Cimeti�re,  tombe  ou  tombeau  nomm� :  cimeti�re,  tombe, tombeau, ossuaire. 
- Vestiges arch�ologiques : Vestiges arch�ologiques, fouilles, tumulus, oppidum.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du lieu-dit.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du lieu-dit habit�'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.T_TOPONYMES   
---- B.5.T.3 TOPONYME_DIVERS
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_toponyme_divers_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_toponyme_divers_bdt_')) = 'n_toponyme_divers_bdt_'
	THEN
--- Index
	nom_table := 'n_toponyme_divers_bdt';
	tb_index := array['id',
			'origin_nom',
			'nature',
			'importance'
			];
	nb_index := array_length(tb_index, 1);

	FOR i_index IN 1..nb_index LOOP
		nom_index:=tb_index[i_index];
		req := '
			DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx;
			CREATE INDEX ' || nom_table || '_' || emprise || '_' || millesime || '_' || nom_index || '_idx ON ' ||nom_schema|| '.' || nom_table || '_' || emprise || '_' || millesime || ' USING btree (' || nom_index || ') TABLESPACE index;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;
---- Commentaire Table
	req := '
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Toponyme divers de la BDTOPO� v2.2 pour le mill�sime ' || millesime || ' et l�emprise ' || emprise || '.
Toponyme de nature diverse, d�signant un b�timent administratif, ou bien une �cole, un d�tail religieux, un �tablissement de sant�etc. 

Voir les valeurs de l�attribut NATURE : 
- A�rodrome militaire : Tout  terrain  ou  plan  d�eau  r�serv�s  �  l�arm�e  sp�cialement am�nag�  pour  l�atterrissage,  le  d�collage  et  les  man�uvres des  a�ronefs  y  compris  les  installations  annexes  qu�il  peut comporter pour les besoins du trafic et le service des a�ronefs : a�rodrome militaire, h�liport militaire. 
- A�rodrome non militaire : Tout  terrain  ou  plan  d�eau  sp�cialement  am�nag�  pour l�atterrissage,  le  d�collage  et  les  man�uvres  des  a�ronefs  y compris les installations annexes qu�il peut comporter pour les besoins du trafic et le service des a�ronefs : altiport, a�rodrome non militaire, h�liport. 
Ne sont pas pris en compte les a�ro-clubs, les terrains de vol � voile, les pistes d�ULM. 
- A�roport international : A�rodrome  de  statut  international  sur  lequel  ont  �t�  pr�vues des  installations  en  vue  de  l�abri,  de  l�entretien  ou  de  la r�partition  des  a�ronefs,  ainsi  que  pour  la  r�ception, l�embarquement  et  le  d�barquement  des  passagers,  le chargement et le d�chargement des marchandises. 
- A�roport quelconque : A�rodrome sur lequel ont �t� pr�vues des installations en vue de  l�abri,  de  l�entretien  ou  de  la  r�partition  des  a�ronefs,  ainsi que pour la r�ception, l�embarquement et le d�barquement des passagers,  le  chargement  et  le  d�chargement  des marchandises. 
- Arbre : Arbre nomm� isol�, arbre remarquable. 
- Bois : Bois ou for�t. 
- Camping : Emplacement  am�nag�  pour  la  pratique  du  camping  d�une superficie de plus de 2 ha. 
- Centrale �lectrique : Usine  o�  l�on  produit  de  l��nergie  �lectrique :  centrale hydro�lectrique,  centrale  thermique,  centrale  nucl�aire,  parc �olien, centrale photovolta�que. 
Les centrales �lectriques souterraines sont exclues. 
- Construction : Construction  nomm�e  habit�e  ou  associ�e  �  un  groupe d�habitations : construction diverse, pigeonnier, moulin � vent. 
- Enceinte militaire : Zone  en  permanence  r�serv�e  pour  les  rassemblements  de troupes  de  toutes  les  armes,  soit  pour  des  man�uvres,  des exercices  (camp  d�instruction),  soit  pour  des  essais,  des �tudes :  base,  camp,  caserne,  d�p�t  de  mat�riels,  terrain permanent  d�entra�nement,  caserne  de  CRS,  caserne  de gendarmes mobiles, � 
Les  champs  de  tir  sont  exclus  ainsi  que  les  propri�t�s  de l�arm�e  qui  ne  sont  indiqu�es  d�aucune  mani�re  sur  le  terrain (ni  cl�tures,  ni  barri�re,  ni  pancartes,�)  et  ne  faisant  l�objet d�aucune restriction particuli�re.  
- Enseignement sup�rieur : �tablissement  consacr�  �  l�enseignement  sup�rieur :  facult�, centre universitaire, institut, grande �cole, � 
Tous  les  �tablissements  d�enseignement  sup�rieur  publics, confessionnels  ou  priv�s,  ayant  un  contrat  simple  ou d�association avec l��tat sont inclus.  
Les cours du soir, les cit�s et les restaurants universitaires sont exclus. 
- Etablissement hospitalier : Autres  �tablissements  relevant  de  la  loi  hospitali�re : sanatorium,  a�rium,  hospice,  maison  de  retraite  (MAPA  et EHPA), �tablissements de convalescence ou de repos. 
Tous les �tablissements assurant les soins et l�h�bergement ou les soins seulement sont inclus. 
- Etablissement p�nitentiaire : �tablissement  clos  am�nag�  pour  recevoir  des  d�linquants condamn�s � une peine privative de libert� ou des d�tenus en instance de jugement : maison d�arr�t, prison. 
Les annexes sont exclues. 
- Etablissement thermal : �tablissement  o�  l�on  utilise  les  eaux  m�dicinales  (eaux min�rales, chaudes ou non) : �tablissement thermal, centre de thalassoth�rapie. 
Seuls  sont  inclus  les  �tablissements  agr��s  par  la  S�curit� Sociale. 
- Golf : Terrain ouvert au public et consacr� � la pratique du golf.  
Les terrains de moins de 6 trous et les minigolfs sont exclus. 
- Haras national : Lieu  ou  �tablissement  destin�  �  la  reproduction  de  l�esp�ce chevaline,  �  l�am�lioration  des  races  de  chevaux  par  la s�lection des �talons. Tous les haras nationaux sont inclus. 
L�enceinte  comprend  l�ensemble  des  installations  (man�ge, �curies, piste d�entra�nement,�). 
- Hippodrome : Lieu  ouvert  au  public  et  consacr�  aux  courses  de  chevaux. Seuls  les  hippodromes  poss�dant  des  am�nagements cons�quents (tribunes, b�timents sp�cifiques) sont inclus. 
- H�pital : �tablissement public ou priv�, o� sont effectu�s tous les soins m�dicaux  et  chirurgicaux  lourds  et/ou  de  longue  dur�e,  ainsi que  les  accouchements :  centre  hospitalier,  h�pital,  h�pital psychiatrique, CHU, h�pital militaire, clinique. 
- Maison du parc : B�timent  ouvert  au  public  et  g�r�  par  un  Parc  National  ou R�gional. 
- Maison foresti�re : Maison g�r�e par l�office national des for�ts. Les  maisons  de  garde  occup�es  par  au  moins  un  agent  de l�ONF sont incluses.  
Les bureaux de l�ONF, les domiciles d�agents servant aussi de bureau,  sont  exclus  lorsqu�ils  ne  sont  pas  situ�s  dans  une maison foresti�re. 
- Menhir : Pierre allong�e, dress�e verticalement. Les alignements en cromlech sont inclus. 
- Monument : Monument  sans  caract�re  religieux  particulier :  monument, statue, st�le. 
- Mus�e : �tablissement ouvert au public exposant une grande collection d�objets, de documents, etc., relatifs aux arts et aux sciences et pouvant servir � leur histoire. Sont inclus : 
�  tous les mus�es contr�l�s ou supervis�s par le minist�re de la Culture (mus�es nationaux, class�s, contr�l�s,�) ; 
�  les mus�es relevant de certains minist�res techniques ou de  l�assistance  publique  (mus�e  de  l�arm�e,  de  la marine) ; 
�  les  mus�es  priv�s  ou  associatifs  ayant  une  grande notori�t� ; 
�  les �comus�es. 
- Parc : Espace  r�glement�,  g�n�ralement  libre  d�acc�s  pour  le  public et o� la nature fait l�objet d�une protection sp�ciale : parc naturel r�gional, parc national, r�serve naturelle nationale ou r�gionale, parc naturel marin. 
Les parcs � vocation commerciale ne sont pas pris en compte dans cet attribut. 
- Parc de loisirs : Parc  �  caract�re  commercial  sp�cialement  am�nag�  pour  les loisirs :  centre  permanent  de  jeux,  parc  d�attraction,  parc  de d�tente, centre de loisirs. 
Seuls  les  parcs  dont  la  superficie  exc�de  4  ha  et  dot�s d��quipements cons�quents sont inclus.  Les  parcs  publics  (jardins,  parcs  communaux, d�partementaux�) sont exclus. 
 - Parc des expositions : Lieu  d�exposition  ou  de  culture  :  centre  culturel,  parc  des expositions. 
- Parc zoologique : Parc  ouvert  au  public,  o�  il  est  possible  de  voir  des  animaux sauvages vivant en captivit� ou en semi-libert�. Tous les parcs ouverts au public sont inclus. 
- Science : �tablissement  scientifique  ou  technique  nomm�  :  centre  de recherche, laboratoire, observatoire, station scientifique. 
- Stade : Grande enceinte, terrain am�nag� pour la pratique des sports, et  le  plus  souvent  entour�  de  gradins,  de  tribunes :  stade, terrain  de  sports,  v�lodrome  d�couvert,  circuit  auto-moto, complexe sportif pluridisciplinaire. 
Seules les enceintes incluant des am�nagements cons�quents (piste � construite �, tribunes,�) sont incluses. 
Les terrains d�entra�nement incluant seulement 2 ou 3 terrains de football et de petits vestiaires sont exclus. 
- Village de vacances : �tablissement  de  vacances,  comprenant  des  �quipements sportifs  ou  de  d�tente  cons�quents  dont  le  gestionnaire  est priv� ou public : village de vacances, colonie de vacances.  
Les h�tels et les � camps de vacances � sont exclus, ainsi que les  �tablissements  dont  la  capacit�  de  prise  en  charge  est inf�rieure � 300 personnes. 
- Zone industrielle : Regroupement  d�activit�s  de  production  sur  l�initiative  des collectivit�s locales ou d�organismes parapublics (chambres de commerce  et  d�industrie)  et  portant  un  nom : zone  artisanale, zone industrielle. 
Les  sites  dont  la  superficie  est  inf�rieure  �  5  ha  sont g�n�ralement exclus.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du lieu-dit.
Cet identifiant est unique. Il est stable d�une �dition � l�autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du lieu-dit habit�'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n�est pas pr�sente';
	RAISE NOTICE '%', req;

	END IF;
*/
END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
  ALTER FUNCTION w_adl_delegue.set_adm_bdtopo_30(
    emprise character varying,
    millesime character varying,
    projection integer)
  OWNER TO postgres;
 
COMMENT ON FUNCTION w_adl_delegue.set_adm_bdtopo_30(
    emprise character varying,
    millesime character varying,
    projection integer)
    IS '[ADMIN - BDTOPO] - Administration d�un millesime de la BDTOPO 30 une fois son import r�alis�

Taches r�alis�es :
---- A. D�placement et Renomage des tables
---- B. Optimisation de toutes les tables
---- B.1 Suppression du champs gid cr��e et de la s�quence correspondante
---- B.2 V�rification du nom du champs g�om�trique
---- B.3 Correction des erreurs sur la g�om�trie
---- B.4 Ajout des contraintes
---- B.4.1 Ajout des contraintes sur le champs g�om�trie
---- B.4.2 CHECK (geometrytype(geom)
---- B.5 Ajout de la clef primaire
---- B.5.1 Suppression de l�ancienne si existante
---- B.5.1 Cr�ation de la cl� primaire selon IGN
---- B.6 Ajout des index spatiaux
---- B.7 Ajout des index attributaires non existants

---- Les commentaires sont renvoy�s � une autre fonction
---- La correction du champs g�om�trique est effectu� par une autre fonction set_admin_bdtopo_30_option_geom()

Tables concern�es :
	adresse
	aerodrome
	arrondissement
	bassin_versant_topographique
	batiment
	canalisation
	cimetiere
	collectivite_territoriale
	commune
	construction_lineaire	
	construction_ponctuelle	
	construction_surfacique	
	cours_d_eau
	departement	
	detail_hydrographique	
	detail_orographique	
	epci	
	equipement_de_transport	
	lieu_dit_non_habite	
	ligne_electrique	
	limite_terre_mer	
	noeud_hydrographique	
	non_communication	
	parc_ou_reserve	
	piste_d_aerodrome	
	plan_d_eau
	point_du_reseau	
	poste_de_transformation	
	pylone	
	region	
	reservoir	
	route_numerotee_ou_nommee		
	surface_hydrographique	
	terrain_de_sport	
	toponymie_bati	
	toponymie_hydrographie	
	toponymie_lieux_nommes	
	toponymie_services_et_activites	
	toponymie_transport	
	toponymie_zones_reglementees	
	transport_par_cable	
	troncon_de_route	
	troncon_de_voie_ferree	
	troncon_hydrographique	
	voie_ferree_nommee	
	zone_d_activite_ou_d_interet	
	zone_d_estran	
	zone_d_habitation	
	zone_de_vegetation	


am�lioration � faire :
---- B.5.1 Ajout de la clef primaire sauf si doublon d�identifiant notamment n_troncon_cours_eau_bdt
erreur : 
ALTER TABLE r_bdtopo_2018.n_toponymie_bati_bdt_000_2018 ADD CONSTRAINT n_toponymie_bati_bdt_000_2018_pkey PRIMARY KEY
Sur la fonction en cours de travail : D�tail :Key (cleabs_de_l_objet)=(CONSSURF0000002000088919) is duplicated..

derni�re MAJ : 30/05/2019';
