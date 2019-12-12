CREATE OR REPLACE FUNCTION w_adl_delegue.set_adm_bdtopo_3_shapefile(emprise character varying, millesime character varying, projection integer DEFAULT 2154)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/*
[ADMIN - BDTOPO] - Administration d´un millésime de la BDTOPO© V.30 issue du ShapeFile; une fois son import réalisé

Taches réalisées :
---- A. Déplacement et Renommage des tables
---- B. Correction du Type du champs géométrie
---- C. Optimisation de toutes les tables
---- C.1 Suppression du champs gid créée et de la séquence correspondante
---- C.2 Vérification du nom du champs géométrique
---- C.3 Correction des erreurs sur la géométrie
---- C.4 Ajout des contraintes
---- C.4.1 Ajout des contraintes sur le champs géométrie
---- C.4.2 CHECK (geometrytype(geom)
---- C.5 Ajout de la clef primaire
---- C.5.1 Suppression de l´ancienne si existante
---- C.5.1 Création de la clé primaire selon IGN
---- C.6 Ajout des index spatiaux
---- C.7 Ajout des index attributaires non existants

---- Les commentaires sont renvoyés à une autre fonction

Tables concernées :
	adresse
	aerodrome
	arrondissement
	arrondissement_municipal
	bassin_versant_topographique
	batiment
	canalisation
	cimetiere
	collectivite_territoriale
	commune_associee_ou_deleguee
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
	erp
	foret_publique
	haie
	lieu_dit_non_habite	
	ligne_electrique
	ligne_orographique	
	limite_terre_mer	
	noeud_hydrographique	
	non_communication	
	parc_ou_reserve	
	piste_d_aerodrome	
	plan_d_eau
	point_de_repere
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

amélioration à faire :
---- A Create Schema : vérification que le schéma n'existe pas et le créer
---- C.5.1 Ajout de la clef primaire sauf si doublon d?identifiant notamment n_troncon_cours_eau_bdt
erreur : 
ALTER TABLE r_bdtopo_2018.n_toponymie_bati_bdt_000_2018 ADD CONSTRAINT n_toponymie_bati_bdt_000_2018_pkey PRIMARY KEY;
Sur la fonction en cours de travail : Détail :Key (cleabs_de_l_objet)=(CONSSURF0000002000088919) is duplicated..

dernière MAJ : 12/12/2019
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
nom_schema:='r_bdtopo_' || millesime;

---- Référencement des tables à traiter
--DEBUG tb_toutestables := array['erp'];
tb_toutestables := array[
	'adresse',
	'aerodrome',
	'arrondissement',
	'arrondissement_municipal',
	'bassin_versant_topographique',
	'batiment',
	'canalisation',
	'cimetiere',
	'collectivite_territoriale',
	'commune',
	'commune_associee_ou_deleguee',
	'construction_lineaire',
	'construction_ponctuelle',
	'construction_surfacique',
	'cours_d_eau',
	'departement',
	'detail_hydrographique',
	'detail_orographique',
	'epci',
	'equipement_de_transport',
	'erp',
	'foret_publique',
	'haie',
	'lieu_dit_non_habite',
	'ligne_electrique',
	'ligne_orographique',
	'limite_terre_mer',
	'noeud_hydrographique',	
	'non_communication',
	'parc_ou_reserve',
	'piste_d_aerodrome',
	'plan_d_eau',
	'point_de_repere',
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

---- A. Déplacement et Renommage des tables
/*
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
		ALTER TABLE public.' || nom_table || ' RENAME TO n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ';
		ALTER TABLE public.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' SET SCHEMA ' || nom_schema || ';	
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n est pas présente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 
*/
---- B. Correction des champs Géométriques
---- B.1 - adresse - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_adresse_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.2 - aerodrome - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_aerodrome_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.3 - arrondissement - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_arrondissement_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.4 - arrondissement_municipal - MULTIPOLYGON 
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_arrondissement_municipal_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.5 - bassin_versant_topographique - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_bassin_versant_topographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.6 - batiment - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_batiment_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.7 - canalisation - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_canalisation_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.8 - cimetiere - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_cimetiere_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.9 - commune - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_commune_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.10 - commune_associee_ou_deleguee - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_commune_associee_ou_deleguee_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.11 - collectivite_territoriale - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_collectivite_territoriale_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.12 - construction_lineaire - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_construction_lineaire_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.13 - construction_ponctuelle - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_construction_ponctuelle_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.14 - construction_surfacique - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_construction_surfacique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.15 - cours_d_eau - MULTILINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_cours_d_eau_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.16 - departement - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_departement_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.17 - detail_hydrographique - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_detail_hydrographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.18 - detail_orographique - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_detail_orographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.19 - epci - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_epci_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- B.20 - erp - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_erp_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- B.21 - foret_publique - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_foret_publique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.22 - haie - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_haie_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.23 - equipement_de_transport	- MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_equipement_de_transport_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.24 - lieu_dit_non_habite - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_lieu_dit_non_habite_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.25 - ligne_electrique - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_ligne_electrique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.26 - ligne_orographique - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.ligne_orographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.27 - limite_terre_mer - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_limite_terre_mer_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.28 - noeud_hydrographique - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_noeud_hydrographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.29 - non_communication - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_non_communication_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.30 - parc_ou_reserve - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_parc_ou_reserve_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.31 - piste_d_aerodrome - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_piste_d_aerodrome_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.32 - plan_d_eau - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_plan_d_eau_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.33 - point_de_repere - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_point_de_repere_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.34 - point_du_reseau - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_point_du_reseau_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.35 - poste_de_transformation - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_poste_de_transformation_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.36 - pylone - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_pylone_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.37 - region - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_region_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.38 - reservoir - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_reservoir_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.39 - route_numerotee_ou_nommee - MULTILINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_route_numerotee_ou_nommee_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.40 - surface_hydrographique - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_surface_hydrographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.41 - terrain_de_sport - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_terrain_de_sport_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.42 - toponymie_bati - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_toponymie_bati_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.43 - toponymie_hydrographie - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_toponymie_hydrographie_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.44 - toponymie_lieux_nommes - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_toponymie_lieux_nommes_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.45 - toponymie_services_et_activites - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_toponymie_services_et_activites_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.46 - toponymie_transport - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_toponymie_transport_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.47 - toponymie_zones_reglementees - POINT
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_toponymie_zones_reglementees_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.48 - transport_par_cable - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_transport_par_cable_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.49 - troncon_de_route - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_troncon_de_route_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.50 - troncon_de_voie_ferree - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_troncon_de_voie_ferree_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.51 - troncon_hydrographique - LINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_troncon_hydrographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.52 - voie_ferree_nommee - MULTILINESTRING
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_voie_ferree_nommee_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.53 - zone_d_activite_ou_d_interet - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_zone_d_activite_ou_d_interet_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.54 - zone_d_estran - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_zone_d_estran_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.55 - zone_d_habitation - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_zone_d_habitation_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- B.56 - zone_de_vegetation - MULTIPOLYGON
req := '
		ALTER TABLE IF EXISTS ' || nom_schema || '.n_zone_de_vegetation_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- C. Optimisation de toutes les tables
FOR i_table IN 1..nb_toutestables LOOP
	nom_table:='n_' || tb_toutestables[i_table] || '_bdt_' || emprise || '_' || millesime;
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
		ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)=' || projection || ');
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
				ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' DROP CONSTRAINT IF EXISTS ' || attribut  || ';
			 ';
			RAISE NOTICE '%', req;
			EXECUTE(req);
		END IF;
---- C.5.1 Création de la clé primaire selon IGN
			select left(nom_table,12) into attribut;
			IF attribut != 'n_toponymie_'
			then
				req := '
					ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_pkey PRIMARY KEY (id);
				';		
			else
				req := '
					--ALTER TABLE IF EXISTS ' || nom_schema || '.' || nom_table || ' ADD CONSTRAINT ' || nom_table || '_pkey PRIMARY KEY (cleabs_de_l_objet);
					select current_time;
				';					
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
					WHERE TABLE_NAME = nom_table AND TABLE_SCHEMA = nom_schema
					AND COLUMN_NAME != 'geom' AND COLUMN_NAME != 'the_geom'
			LOOP
					req := '
						DROP INDEX IF EXISTS ' || nom_schema || '.' || nom_table || '_' || attribut || '_idx;
						CREATE INDEX ' || nom_table || '_' || attribut || '_idx ON ' || nom_schema || '.' || nom_table || ' USING btree (' || attribut || ') TABLESPACE index;
					';
					RAISE NOTICE '%', req;
					EXECUTE(req);
			END LOOP;				
---- C.99 Fin de la boucle
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n?est pas présente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 	

RETURN current_time;
END; 
$function$
;

COMMENT ON FUNCTION w_adl_delegue.set_adm_bdtopo_3_shapefile("varchar","varchar","int4") IS '[ADMIN - BDTOPO] - Administration d´un millesime de la BDTOPO 30 une fois son import réalisé

Taches réalisées :
---- A. Déplacement et Renomage des tables
---- B. Correction du Type du champs géométrie
---- C. Optimisation de toutes les tables
---- C.1 Suppression du champs gid créée et de la séquence correspondante
---- C.2 Vérification du nom du champs géométrique
---- C.3 Correction des erreurs sur la géométrie
---- C.4 Ajout des contraintes
---- C.4.1 Ajout des contraintes sur le champs géométrie
---- C.4.2 CHECK (geometrytype(geom)
---- C.5 Ajout de la clef primaire
---- C.5.1 Suppression de l´ancienne si existante
---- C.5.1 Création de la clé primaire selon IGN
---- C.6 Ajout des index spatiaux
---- C.7 Ajout des index attributaires non existants

---- Les commentaires sont renvoyés à une autre fonction

TTables concernées :
	adresse
	aerodrome
	arrondissement
	arrondissement_municipal
	bassin_versant_topographique
	batiment
	canalisation
	cimetiere
	collectivite_territoriale
	commune_associee_ou_deleguee
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
	erp
	foret_publique
	haie
	lieu_dit_non_habite	
	ligne_electrique
	ligne_orographique	
	limite_terre_mer	
	noeud_hydrographique	
	non_communication	
	parc_ou_reserve	
	piste_d_aerodrome	
	plan_d_eau
	point_de_repere
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

amélioration à faire :
---- A Create Schema : verification que le schéma n existe pas et le crééer
---- C.5.1 Ajout de la clef primaire sauf si doublon d?identifiant notamment n_troncon_cours_eau_bdt
erreur : 
ALTER TABLE r_bdtopo_2018.n_toponymie_bati_bdt_000_2018 ADD CONSTRAINT n_toponymie_bati_bdt_000_2018_pkey PRIMARY KEY;
Sur la fonction en cours de travail : Détail :Key (cleabs_de_l_objet)=(CONSSURF0000002000088919) is duplicated..

dernière MAJ : 12/12/2019';
