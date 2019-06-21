CREATE OR REPLACE FUNCTION w_adl_delegue.creer_vues_dptales_bdtopo30 (emprise character varying, millesime character varying, projection integer DEFAULT 2154)
  RETURNS text AS $function$
/*
[ADMIN - BDTOPO] - création des vues départementales matérialisées et vues classiques une fois les couches nationales administrées
---- Liste des départements pour la DTerCE 'élargie'
---- Liste des départements hors DTerCE 'élargie'

Taches réalisées :
---- A. generation des vues départementales matérialisées : 
---- A.1 Boucle pour la generation des vues stockées épartements pour la DTerCE 'élargie'
---- A.1.1 Ajout d'un champs de géométrie en 2154
---- A.2 Ajout des index spatiaux
---- A.3 Ajout des index attributaires non existants

---- B. generation des vues départementales simples hors DTerCE 'élargie'
---- B.1 Boucle pour la generation des vues stockées

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
Spécifier le type de géométrie dans le champs geom_2154

dernière MAJ : 21/06/2019
*/
DECLARE
---- déclaration variables  --
nom_schema 				character varying;					-- Schéma du référentiel en text
tb_table 				character varying[]; 				-- Tables BDTOPO sur lequel excecuter le script
nb_table				integer;							-- nombre de tables BDTOPO dans la liste
i_table 				int2; 								-- boucle Tables
nom_table 				character varying;					-- nom de la table en text

tb_dpt_vue 				character varying[]; 				-- départements hors zone d'action : generation de vues simples
nb_dpt_vue 				integer; 							-- nombre de départements hors zone d'action
tb_dpt_vuestockee 		character varying[]; 				-- départements  zone d'action : generation de vues stockées
nb_dpt_vuestockee 		integer; 							-- nombre de départements  zone d'action
i_dpt 					int2; 								-- boucle départementale
dpt 					character varying; 					-- Numéro du département en format texte
dpt_num 				integer;							-- Numéro du département en numérique

req 					text;								-- requête à generer pour les commandes
attribut 				character varying; 					-- Liste des attributs de la table

begin
nom_schema:='r_bdtopo_' || millesime;
---- Tables de la BDTOPO V30	
tb_table := array[
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
--	'erp',
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
nb_table := array_length(tb_table, 1);

---- Liste des départements pour la DTerCE 'élargie'
DEBUG tb_dpt_vuestockee := array['001','003'];
/*tb_dpt_vuestockee := array['001','003','007',
							'015','019',
							'021','023','025','026',
							'038','039',
							'042','043','048',
							'058',
							'063','069',
							'070','071','073','074',
							'087','089',
							'090'];*/
nb_dpt_vuestockee := array_length(tb_dpt_vuestockee, 1);

---- Liste des départements hors DTerCE 'élargie'
--DEBUG tb_dpt_vue := array['002','004'];
tb_dpt_vue :=	array[
					'002','004','005','006','008','009',
				  	'010','011','012','013','014','016','017','018',
					'02A','02B','022','024','027','028','029',
					'030','031','032','033','034','036','036','037',
					'040','041','044','045','046','047','049',
					'050','051','052','053','054','055','056','057','059',
					'060','061','062','064','065','066','067','068',
					'072','075','076','077','078','079',
					'080','081','082','083','084','085','086','088',
					'091','092','093','094','095',
					'971', '972', '973', '975', '976'
					 ];
nb_dpt_vue := array_length(tb_dpt_vue, 1);	

---- A. generation des vues stockées
FOR i_dpt IN 1..nb_dpt_vuestockee LOOP
dpt:=tb_dpt_vuestockee[i_dpt];
---- A.1 Boucle pour la generation des vues stockées
	FOR i_table IN 1..nb_table LOOP
		nom_table := tb_table[i_table];
		req := '
				DROP MATERIALIZED VIEW IF EXISTS ' || nom_schema || '.v_' || nom_table || '_bdt_' || dpt || '_' || millesime || ';
				DROP VIEW IF EXISTS ' || nom_schema || '.v_' || nom_table || '_bdt_' || dpt || '_' || millesime || ';
				CREATE MATERIALIZED VIEW ' || nom_schema || '.v_' || nom_table || '_bdt_' || dpt || '_' || millesime || ' AS
					SELECT row_number() over () as rownum, bdt.*, ST_Transform(bdt.geom,'||projection||') AS geom_2154
					FROM ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' as bdt
					JOIN ' || nom_schema || '.n_departement_bdt_' || emprise || '_' || millesime || ' as adm
					ON ''0''||adm.code_insee = '''||dpt||''' AND ST_Intersects(adm.geom, bdt.geom);
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);
		
---- A.2 Ajout des index spatiaux
		req := '
			CREATE INDEX v_' || nom_table || '_bdt_' || dpt || '_' || millesime || '_geom_gist ON ' || nom_schema || '.v_' || nom_table || '_bdt_' || dpt || '_' || millesime || ' USING gist (geom) TABLESPACE index;
			ALTER TABLE IF EXISTS ' || nom_schema || '.v_' || nom_table || '_bdt_' || dpt || '_' || millesime || ' CLUSTER ON v_' || nom_table || '_bdt_' || dpt || '_' || millesime || '_geom_gist;
		';
		RAISE NOTICE '%', req;
		EXECUTE(req);

---- A.3 Ajout des index attributaires non existants
		nom_table := 'v_' || nom_table || '_bdt_0' || dpt || '_' || millesime;
		FOR attribut IN SELECT COLUMN_NAME
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = nom_table
				AND COLUMN_NAME != 'geom' AND COLUMN_NAME != 'the_geom'
		LOOP
				req := '
					CREATE INDEX ' || nom_table || '_' || attribut || '_idx ON ' || nom_schema || '.' || nom_table || ' USING btree (' || attribut || ') TABLESPACE index;
				';
				RAISE NOTICE '%', req;
				EXECUTE(req);
		END LOOP;	
	END LOOP;
END LOOP;
/*
---- B. generation des vues simples
FOR i_dpt IN 1..nb_dpt_vue LOOP
dpt:=tb_dpt_vue[i_dpt];
---- B.1 Boucle pour la generation des vues stockées
	FOR i_table IN 1..nb_table LOOP
		nom_table := tb_table[i_table];
		req := '
				DROP VIEW IF EXISTS ' || nom_schema || '.v_' || nom_table || '_bdt_' || dpt || '_' || millesime || ';
				DROP MATERIALIZED VIEW IF EXISTS ' || nom_schema || '.v_' || nom_table || '_bdt_' || dpt || '_' || millesime || ';
				CREATE VIEW ' || nom_schema || '.v_' || nom_table || '_bdt_' || dpt || '_' || millesime || ' AS
					SELECT bdt.*
					FROM ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' as bdt
					JOIN ' || nom_schema || '.n_departement_bdt_' || emprise || '_' || millesime || ' as adm
					ON adm.code_insee = '''||dpt||''' AND ST_Intersects(adm.geom, bdt.geom);
		';
		RAISE NOTICE '%', req;
		--EXECUTE(req);
	END LOOP;
END LOOP;
*/
RETURN current_time;
END;
$function$
  LANGUAGE plpgsql VOLATILE
  COST 100;
