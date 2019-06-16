CREATE OR REPLACE FUNCTION w_adl_delegue.set_admin_bdtopo_30_option_geom(
	emprise character varying,
	millesime character varying,
	projection integer DEFAULT 2154)
    RETURNS void
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
/*
[ADMIN - BDTOPO] - Correction du Type du champs géométrie de la BDTOPO V30

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
	ligne_orographique
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

amélioration à faire :

dernière MAJ : 16/06/2019
*/

declare
nom_schema 					character varying;		-- Schéma du référentiel en text
req 						text;					-- Requête à passer

BEGIN

nom_schema:='r_bdtopo_' || millesime;

/*
SELECT 
	GeometryType(geom) AS "GeometryType"
FROM r_bdtopo_2018.n_zone_d_habitation_bdt_000_2018
group by "GeometryType"
*/

---- A - Correction des champs Géométriques
---- A.1 - adresse - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_adresse_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.2 - aerodrome - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_aerodrome_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.3 - arrondissement - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_arrondissement_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.4 - arrondissement_municipal - MULTIPOLYGON 
req := '
		ALTER TABLE ' || nom_schema || '.n_arrondissement_municipal_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.5 - bassin_versant_topographique - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_bassin_versant_topographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.6 - batiment - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_batiment_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.7 - canalisation - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_canalisation_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.8 - cimetiere - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_cimetiere_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.9 - commune - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_commune_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.10 - collectivite_territoriale - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_collectivite_territoriale_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.11 - construction_lineaire - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_construction_lineaire_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.12 - construction_ponctuelle - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_construction_ponctuelle_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.13 - construction_surfacique - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_construction_surfacique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.14 - cours_d_eau - MULTILINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_cours_d_eau_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.15 - departement - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_departement_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.16 - detail_hydrographique - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_detail_hydrographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.17 - detail_orographique - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_detail_orographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.18 - epci - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_epci_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.19 - equipement_de_transport	- MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_equipement_de_transport_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.20 - lieu_dit_non_habite - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_lieu_dit_non_habite_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.21 - ligne_electrique - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_ligne_electrique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.22 - ligne_orographique - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.ligne_orographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.23 - limite_terre_mer - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_limite_terre_mer_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.24 - noeud_hydrographique - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_noeud_hydrographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.25 - non_communication - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_non_communication_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.26 - parc_ou_reserve - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_parc_ou_reserve_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.27 - piste_d_aerodrome - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_piste_d_aerodrome_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.28 - plan_d_eau - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_plan_d_eau_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.29 - point_du_reseau - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_point_du_reseau_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.30 - poste_de_transformation - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_poste_de_transformation_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.31 - pylone - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_pylone_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.32 - region - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_region_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.33 - reservoir - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_reservoir_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.34 - route_numerotee_ou_nommee - MULTILINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_route_numerotee_ou_nommee_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.35 - surface_hydrographique - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_surface_hydrographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.36 - terrain_de_sport - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_terrain_de_sport_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.37 - toponymie_bati - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_toponymie_bati_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.38 - toponymie_hydrographie - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_toponymie_hydrographie_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.39 - toponymie_lieux_nommes - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_toponymie_lieux_nommes_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.340 - toponymie_services_et_activites - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_toponymie_services_et_activites_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.41 - toponymie_transport - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_toponymie_transport_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.42 - toponymie_zones_reglementees - POINT
req := '
		ALTER TABLE ' || nom_schema || '.n_toponymie_zones_reglementees_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''POINT'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.43 - transport_par_cable - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_transport_par_cable_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.44 - troncon_de_route - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_troncon_de_route_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.45 - troncon_de_voie_ferree - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_troncon_de_voie_ferree_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.46 - troncon_hydrographique - LINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_troncon_hydrographique_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''LINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.47 - voie_ferree_nommee - MULTILINESTRING
req := '
		ALTER TABLE ' || nom_schema || '.n_voie_ferree_nommee_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTILINESTRING'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.48 - zone_d_activite_ou_d_interet - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_zone_d_activite_ou_d_interet_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.49 - zone_d_estran - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_zone_d_estran_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.50 - zone_d_habitation - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_zone_d_habitation_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- A.51 - zone_de_vegetation - MULTIPOLYGON
req := '
		ALTER TABLE ' || nom_schema || '.n_zone_de_vegetation_bdt_' || emprise || '_' || millesime || ' ALTER COLUMN geom TYPE geometry(''MULTIPOLYGON'',' || projection || ');
';
RAISE NOTICE '%', req;
EXECUTE(req);

END; 
$BODY$;

ALTER FUNCTION w_adl_delegue.set_admin_bdtopo_30_option_geom(character varying, character varying, integer)
    OWNER TO postgres;

COMMENT ON FUNCTION w_adl_delegue.set_admin_bdtopo_30_option_geom(character varying, character varying, integer)
    IS '[ADMIN - BDTOPO] - Correction du Type du champs géométrie de la BDTOPO V30

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
	ligne_orographique
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

amélioration à faire :

dernière MAJ : 16/06/2019';
