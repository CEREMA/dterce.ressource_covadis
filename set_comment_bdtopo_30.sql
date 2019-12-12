CREATE OR REPLACE FUNCTION w_adl_delegue.set_comment_bdtopo_3(nom_schema character varying, livraison character DEFAULT 'sql'::bpchar, emprise character DEFAULT '000'::bpchar, millesime character DEFAULT NULL::bpchar, covadis boolean DEFAULT true)
 RETURNS text
 LANGUAGE plpgsql
AS $function$

/*
[ADMIN - BDTOPO] - Mise en place des commentaires

Option :
- nom du schéma où se trouvent les tables
- format de livraison de l'IGN :
	- 'shp' = shapefile
	- 'sql' = dump postgis
- emprise sur 3 caractères selon la COVADIS ddd : 
	- 'fra' : France Entière
	- '000' : France Métropolitaine
	- 'rrr' : Numéro INSEE de la Région : 'r84' pour Avergne-Rhône-Alpes
	- 'ddd' : Numéro INSEE du département : '038' pour l'Isère
				non pris en compte si COVADIS = false
- millesime selon COVADIS : aaaa pour l'année du millesime ou null si pas de millesime
				non pris en compte si COVADIS = false
- COVADIS : nommage des tble selon la COVADIS : oui : true / non false

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


dernière MAJ : 12/12/2019
*/

declare
nom_table 					character varying;		-- nom de la table en text
champs						character varying;		-- nom de la table en text;
commentaires 				character varying;		-- nom de la table en text
req 						text;
veriftable 					character varying;
liste_valeur				character varying[][4];	-- Toutes les tables
--liste_sous_valeur			character varying[3];	-- Toutes les tables
nb_valeur					integer;				-- Nombre de tables --> normalement XX
attribut 					character varying; 		-- Liste des attributs de la table
--typegeometrie 				text; 					-- "GeometryType" de la table

begin
	
---- A] Commentaires des tables
---- Liste des valeurs à passer :
---- ARRAY['nom de la table telle que livrées par IGN','nom du champs dans le livraison SQL','nom du champs dans la livraison shapefile', 'Commentaires à passer']
---- récupéré ici http://professionnels.ign.fr/doc/Structure_Nouvelle_BDTopo%20%285%29.xlsx
liste_valeur := ARRAY[
ARRAY['adresse','.'],
ARRAY['aerodrome','.'],
ARRAY['arrondissement','.'],
ARRAY['arrondissement_municipal','.'],
ARRAY['bassin_versant_topographique','.'],
ARRAY['batiment','.'],
ARRAY['canalisation','.'],
ARRAY['cimetiere','.'],
ARRAY['collectivite_territoriale','.'],
ARRAY['commune_associee_ou_deleguee','.'],
ARRAY['commune','.'],
ARRAY['construction_lineaire','.'],
ARRAY['construction_ponctuelle','.'],
ARRAY['construction_surfacique','.'],
ARRAY['cours_d_eau','.'],
ARRAY['departement','.'],
ARRAY['detail_hydrographique','.'],
ARRAY['detail_orographique','.'],
ARRAY['epci','.'],
ARRAY['equipement_de_transport','.'],
ARRAY['erp','.'],
ARRAY['foret_publique','.'],
ARRAY['haie','.'],
ARRAY['lieu_dit_non_habite','.'],
ARRAY['ligne_electrique','.'],
ARRAY['ligne_orographique','.'],
ARRAY['limite_terre_mer','.'],
ARRAY['noeud_hydrographique','.'],
ARRAY['non_communication','.'],
ARRAY['parc_ou_reserve','.'],
ARRAY['piste_d_aerodrome','.'],
ARRAY['plan_d_eau','.'],
ARRAY['point_de_repere','.'],
ARRAY['point_du_reseau','.'],
ARRAY['poste_de_transformation','.'],
ARRAY['pylone','.'],
ARRAY['region','.'],
ARRAY['reservoir','.'],
ARRAY['route_numerotee_ou_nommee','.'],
ARRAY['surface_hydrographique','.'],
ARRAY['terrain_de_sport','.'],
ARRAY['toponymie_bati','.'],
ARRAY['toponymie_hydrographie','.'],
ARRAY['toponymie_lieux_nommes','.'],
ARRAY['toponymie_services_et_activites','.'],
ARRAY['toponymie_transport','.'],
ARRAY['toponymie_zones_reglementees','.'],
ARRAY['transport_par_cable','.'],
ARRAY['troncon_de_route','.'],
ARRAY['troncon_de_voie_ferree','.'],
ARRAY['troncon_hydrographique','.'],
ARRAY['voie_ferree_nommee','.'],
ARRAY['zone_d_activite_ou_d_interet','.'],
ARRAY['zone_d_estran','.'],
ARRAY['zone_d_habitation','.'],
ARRAY['zone_de_vegetation','.']
];
nb_valeur := array_length(liste_valeur, 1);

FOR i_table IN 1..nb_valeur LOOP
---- Récupération des champs
---- Nom de la table
	select
		case
			when COVADIS is false then 
				lower(liste_valeur[i_table][1])
			else
				case
					when millesime is not null then
						'n_' || lower(liste_valeur[i_table][1]) || '_bdt_' || emprise || '_' || millesime
					else
						'n_' || lower(liste_valeur[i_table][1]) || '_bdt_' || emprise
				end
		end
		 into nom_table;
---- Nom du commentaire	
	SELECT liste_valeur[i_table][2] into commentaires;

---- Execution de la requete
	IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) then
		req := '
				COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''' || commentaires || ''';
				';
		--RAISE NOTICE '%', req;
		EXECUTE(req);
	else
		req := '
				La table ' || nom_schema || '.' || nom_table || ' n´est pas présente.
				';
		RAISE NOTICE '%', req;
	END IF;

END LOOP;

---- B] Commentaires des attributs
---- Liste des valeurs à passer :
---- ARRAY['nom de la table telle que livrées par IGN','nom du champs dans le livraison SQL','nom du champs dans la livraison shapefile', 'Commentaires à passer']
---- récupéré ici http://professionnels.ign.fr/doc/Structure_Nouvelle_BDTopo%20%285%29.xlsx
liste_valeur := ARRAY[
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','nature','NATURE','Nature : Nature de la commune associée ou déléguée.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','code_insee','INSEE_CAD','Code INSEE : Code INSEE de la commune associée ou déléguée.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','code_insee_de_la_commune_de_rattach','INSEE_COM','Code INSEE de la commune de rattach : Code INSEE de la commune de rattachement.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','code_postal','CODE_POST','Code postal : Code postal utilisé pour la commune associée ou déléguée.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','nom_officiel','NOM','Nom officiel : Nom officiel de la commune associée ou déléguée.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','lien_vers_chef_lieu','ID_CH_LIEU','Lien vers chef-lieu : Lien vers la zone d´habitation chef-lieu de la commune associée ou déléguée.'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','liens_vers_autorite_administrative','ID_AUT_ADM','Liens vers autorité administrative : Lien vers l´annexe de la mairie ou la mairie annexe de la commune déléguée (zone d´activité ou d´intérêt).'],
ARRAY['COMMUNE_ASSOCIEE_OU_DELEGUEE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ARRONDISSEMENT_MUNICIPAL','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ARRONDISSEMENT_MUNICIPAL','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','code_insee','INSEE_ARM','Code INSEE : Code INSEE de l´arrondissement municipal.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','code_insee_de_la_commune_de_rattach','INSEE_COM','Code INSEE de la commune de rattach : Code INSEE de la commune de rattachement.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','code_postal','CODE_POST','Code postal : Code postal utilisé pour l´arrondissement municipal.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','nom_officiel','NOM','Nom officiel : Nom officiel de l´arrondissement municipal.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','lien_vers_chef_lieu','ID_CH_LIEU','Lien vers chef-lieu : Lien vers la zone d´habitation chef-lieu de l´arrondissement municipal.'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','liens_vers_autorite_administrative','ID_AUT_ADM','Liens vers autorité administrative : Lien vers la mairie d´arrondissement (zone d´activité ou d´intérêt).'],
ARRAY['ARRONDISSEMENT_MUNICIPAL','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['COMMUNE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['COMMUNE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['COMMUNE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COMMUNE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['COMMUNE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COMMUNE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['COMMUNE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['COMMUNE','code_insee','INSEE_COM','Code INSEE : Code insee de la commune sur 5 caractères.'],
ARRAY['COMMUNE','code_insee_de_l_arrondissement','INSEE_ARR','Code INSEE de l´arrondissement : Code INSEE de l´arrondissement.'],
ARRAY['COMMUNE','code_insee_de_la_collectivite_terr','INSEE_COL','Code INSEE de la collectivité terr : Code INSEE de la collectivité territoriale incluant cette commune.'],
ARRAY['COMMUNE','code_insee_du_departement','INSEE_DEP','Code INSEE du département : Code INSEE du département sur 2 ou 3 caractères.'],
ARRAY['COMMUNE','code_insee_de_la_region','INSEE_REG','Code INSEE de la région : Code INSEE de la région.'],
ARRAY['COMMUNE','code_postal','CODE_POST','Code postal : Code postal utilisé pour la commune.'],
ARRAY['COMMUNE','nom_officiel','NOM','Nom officiel : Nom officiel de la commune.'],
ARRAY['COMMUNE','chef_lieu_d_arrondissement','CL_ARROND','Chef-lieu d´arrondissement : Indique que la commune est chef-lieu d´arrondissement.'],
ARRAY['COMMUNE','chef_lieu_de_collectivite_terr','CL_COLLTER','Chef-lieu de collectivité terr : Indique que la commune est chef-lieu d´une collectivité départementale.'],
ARRAY['COMMUNE','chef_lieu_de_departement','CL_DEPART','Chef-lieu de département : Indique que la commune est chef-lieu d´un département.'],
ARRAY['COMMUNE','chef_lieu_de_region','CL_REGION','Chef-lieu de région : Indique que la commune est chef-lieu d´une région.'],
ARRAY['COMMUNE','capitale_d_etat','CAPITALE','Capitale d´Etat : Indique que la commune est la capitale d´Etat.'],
ARRAY['COMMUNE','date_du_recensement','DATE_RCT','Date du recensement : Date du recensement sur lequel s´appuie le chiffre de population.'],
ARRAY['COMMUNE','organisme_recenseur','RECENSEUR','Organisme recenseur : Nom de l´organisme ayant effectué le recensement de population.'],
ARRAY['COMMUNE','population','POPULATION','Population : Population sans double compte de la commune.'],
ARRAY['COMMUNE','surface_en_ha','SURFACE_HA','Surface en ha : Superficie cadastrale de la commune telle que donnée par l´INSEE (en ha).'],
ARRAY['COMMUNE','codes_siren_des_epci','SIREN_EPCI','Codes SIREN des EPCI : Codes SIREN de l´EPCI ou des EPCI auxquels appartient cette commune.'],
ARRAY['COMMUNE','lien_vers_chef_lieu','ID_CH_LIEU','Lien vers chef-lieu : Lien vers la zone d´habitation chef-lieu de la commune.'],
ARRAY['COMMUNE','liens_vers_autorite_administrative','ID_AUT_ADM','Liens vers autorité administrative : Lien vers la mairie de cette commune (zone d´activité ou d´intérêt).'],
ARRAY['COMMUNE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ARRONDISSEMENT','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ARRONDISSEMENT','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ARRONDISSEMENT','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ARRONDISSEMENT','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ARRONDISSEMENT','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ARRONDISSEMENT','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ARRONDISSEMENT','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ARRONDISSEMENT','code_insee_de_l_arrondissement','INSEE_ARR','Code INSEE : Code INSEE de l´arrondissement.'],
ARRAY['ARRONDISSEMENT','code_insee_du_departement','INSEE_DEP','Code INSEE du département : Code INSEE du département.'],
ARRAY['ARRONDISSEMENT','code_insee_de_la_region','INSEE_REG','Code INSEE de la région : Code INSEE de la région.'],
ARRAY['ARRONDISSEMENT','nom_officiel','NOM','Nom officiel : Nom officiel de l´arrondissement.'],
ARRAY['ARRONDISSEMENT','liens_vers_autorite_administrative','ID_AUT_ADM','Liens vers autorité administrative : Lien vers la sous-préfecture de l´arrondissement (zone d´activité ou d´intérêt).'],
ARRAY['ARRONDISSEMENT','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['COLLECTIVITE_TERRITORIALE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['COLLECTIVITE_TERRITORIALE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['COLLECTIVITE_TERRITORIALE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COLLECTIVITE_TERRITORIALE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['COLLECTIVITE_TERRITORIALE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COLLECTIVITE_TERRITORIALE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['COLLECTIVITE_TERRITORIALE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['COLLECTIVITE_TERRITORIALE','code_insee','INSEE_COL','Code INSEE : Code INSEE de la collectivité départementale (collectivité territoriale située entre la commune et la région).'],
ARRAY['COLLECTIVITE_TERRITORIALE','code_insee_de_la_region','INSEE_REG','Code INSEE de la région : Code INSEE de la région.'],
ARRAY['COLLECTIVITE_TERRITORIALE','nom_officiel','NOM','Nom officiel : Nom officiel de la collectivité départementale.'],
ARRAY['COLLECTIVITE_TERRITORIALE','liens_vers_autorite_administrative','ID_AUT_ADM','Liens vers autorité administrative : Lien vers le siège du conseil de la collectivité (Zone d´activité ou d´intérêt).'],
ARRAY['COLLECTIVITE_TERRITORIALE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['DEPARTEMENT','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['DEPARTEMENT','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['DEPARTEMENT','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['DEPARTEMENT','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['DEPARTEMENT','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['DEPARTEMENT','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['DEPARTEMENT','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['DEPARTEMENT','code_insee','INSEE_DEP','Code INSEE : Code INSEE du département.'],
ARRAY['DEPARTEMENT','code_insee_de_la_region','INSEE_REG','Code INSEE de la région : Code INSEE de la région.'],
ARRAY['DEPARTEMENT','nom_officiel','NOM','Nom officiel : Nom officiel du département.'],
ARRAY['DEPARTEMENT','liens_vers_autorite_administrative','ID_AUT_ADM','Liens vers autorité administrative : Lien vers la préfecture du département (zone d´activité ou d´intérêt).'],
ARRAY['DEPARTEMENT','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['REGION','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['REGION','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['REGION','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['REGION','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['REGION','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['REGION','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['REGION','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['REGION','code_insee','INSEE_REG','Code INSEE : Code INSEE de la région.'],
ARRAY['REGION','nom_officiel','NOM','Nom officiel : Nom officiel de la région.'],
ARRAY['REGION','liens_vers_autorite_administrative','ID_AUT_ADM','Liens vers autorité administrative : Lien vers la préfecture de région (zone d´activité ou d´intérêt).'],
ARRAY['REGION','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['EPCI','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['EPCI','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['EPCI','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['EPCI','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['EPCI','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['EPCI','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['EPCI','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['EPCI','nature','NATURE','Nature : Nature de l´EPCI.'],
ARRAY['EPCI','code_siren','CODE_SIREN','Code SIREN : Code SIREN de l´EPCI.'],
ARRAY['EPCI','nom_officiel','NOM','Nom officiel : Nom de l´EPCI.'],
ARRAY['EPCI','liens_vers_autorite_administrative','ID_AUT_ADM','Liens vers autorité administrative : Lien vers le siège de l´autorité administrative de l´EPCI (zone d´activité ou d´intérêt).'],
ARRAY['EPCI','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['CONDOMINIUM','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['CONDOMINIUM','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['CONDOMINIUM','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CONDOMINIUM','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['CONDOMINIUM','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CONDOMINIUM','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['CONDOMINIUM','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['CONDOMINIUM','unites_administratives_souveraines','PAYS_SOUVE','Unités administratives souveraines : Noms des unités administratives souveraines.'],
ARRAY['CONDOMINIUM','lien_vers_lieu_dit','ID_LIEUDIT','Lien vers lieu-dit : Lien vers la zone d´habitation ou l´espace naturel décrivant ce lieu.'],
ARRAY['CONDOMINIUM','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TRONCON_DE_ROUTE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['TRONCON_DE_ROUTE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['TRONCON_DE_ROUTE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TRONCON_DE_ROUTE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['TRONCON_DE_ROUTE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TRONCON_DE_ROUTE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['TRONCON_DE_ROUTE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['TRONCON_DE_ROUTE','etat_de_l_objet','ETAT','Etat de l´objet : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['TRONCON_DE_ROUTE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['TRONCON_DE_ROUTE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['TRONCON_DE_ROUTE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['TRONCON_DE_ROUTE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['TRONCON_DE_ROUTE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['TRONCON_DE_ROUTE','fictif','FICTIF','Fictif : Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision).'],
ARRAY['TRONCON_DE_ROUTE','nature','NATURE','Nature : Attribut permettant de classer un tronçon de route ou de chemin suivant ses caractéristiques physiques.'],
ARRAY['TRONCON_DE_ROUTE','position_par_rapport_au_sol','POS_SOL','Position par rapport au sol : Position du tronçon par rapport au niveau du sol.'],
ARRAY['TRONCON_DE_ROUTE','nombre_de_voies','NB_VOIES','Nombre de voies : Nombre total de voies de circulation tracées au sol ou effectivement utilisées, sur une route, une rue ou une chaussée de route à chaussées séparées.'],
ARRAY['TRONCON_DE_ROUTE','largeur_de_chaussee','LARGEUR','Largeur de chaussée : Largeur de la chaussée, en mètres.'],
ARRAY['TRONCON_DE_ROUTE','itineraire_vert','IT_VERT','Itinéraire vert : Indique l’appartenance ou non d’un tronçon routier au réseau vert.'],
ARRAY['TRONCON_DE_ROUTE','date_de_mise_en_service','DATE_SERV','Date de mise en service : Date prévue ou la date effective de mise en service d’un tronçon de route.'],
ARRAY['TRONCON_DE_ROUTE','prive','PRIVE','Privé : Indique le caractère privé d´un tronçon de route carrossable.'],
ARRAY['TRONCON_DE_ROUTE','sens_de_circulation','SENS','Sens de circulation : Sens licite de circulation sur les voies pour les véhicules légers.'],
ARRAY['TRONCON_DE_ROUTE','bande_cyclable','CYCLABLE','Bande cyclable : Sens de circulation sur les bandes cyclables.'],
ARRAY['TRONCON_DE_ROUTE','reserve_aux_bus','BUS','Réservé aux bus : Sens de circulation sur les voies réservées au bus.'],
ARRAY['TRONCON_DE_ROUTE','urbain','URBAIN','Urbain : Indique que le tronçon de route est situé en zone urbaine.'],
ARRAY['TRONCON_DE_ROUTE','vitesse_moyenne_vl','VIT_MOY_VL','Vitesse moyenne VL : Vitesse moyenne des véhicules légers dans le sens direct.'],
ARRAY['TRONCON_DE_ROUTE','acces_vehicule_leger','ACCES_VL','Accès véhicule léger : Conditions de circulation sur le tronçon pour un véhicule léger.'],
ARRAY['TRONCON_DE_ROUTE','acces_pieton','ACCES_PED','Accès piéton : Conditions d´accès pour les piétons.'],
ARRAY['TRONCON_DE_ROUTE','periode_de_fermeture','FERMETURE','Période de fermeture : Périodes pendant lesquelles le tronçon n´est pas accessible à la circulation automobile.'],
ARRAY['TRONCON_DE_ROUTE','nature_de_la_restriction','NAT_RESTR','Nature de la restriction : Nature précise de la restriction sur un tronçon où la circulation automobile est restreinte.'],
ARRAY['TRONCON_DE_ROUTE','restriction_de_hauteur','RESTR_H','Restriction de hauteur : Exprime l´interdiction de circuler pour les véhicules dépassant la hauteur indiquée.'],
ARRAY['TRONCON_DE_ROUTE','restriction_de_poids_total','RESTR_P','Restriction de poids total : Exprime l´interdiction de circuler pour les véhicules dépassant le poids indiqué.'],
ARRAY['TRONCON_DE_ROUTE','restriction_de_poids_par_essieu','RESTR_PPE','Restriction de poids par essieu : Exprime l´interdiction de circuler pour les véhicules dépassant le poids par essieu indiqué.'],
ARRAY['TRONCON_DE_ROUTE','restriction_de_largeur','RESTR_LAR','Restriction de largeur : Exprime l´interdiction de circuler pour les véhicules dépassant la largeur indiquée.'],
ARRAY['TRONCON_DE_ROUTE','restriction_de_longueur','RESTR_LON','Restriction de longueur : Exprime l´interdiction de circuler pour les véhicules dépassant la longueur indiquée.'],
ARRAY['TRONCON_DE_ROUTE','matieres_dangereuses_interdites','RESTR_MAT','Matières dangereuses interdites : Exprime l´interdiction de circuler pour les véhicules transportant des matières dangereuses.'],
ARRAY['TRONCON_DE_ROUTE','identifiant_voie_1_gauche','ID_VOIE_G','Identifiant voie 1 gauche : Identifiant de la voie pour le côté gauche du tronçon.'],
ARRAY['TRONCON_DE_ROUTE','identifiant_voie_1_droite','ID_VOIE_D','Identifiant voie 1 droite : Identifiant de la voie pour le côté droit du tronçon.'],
ARRAY['TRONCON_DE_ROUTE','nom_1_gauche','NOM_1_G','Nom 1 gauche : Nom principal de la rue, côté gauche du tronçon : nom de la voie ou nom de lieu-dit le cas échéant.'],
ARRAY['TRONCON_DE_ROUTE','nom_1_droite','NOM_1_D','Nom 1 droite : Nom principal de la rue, côté droit du tronçon : nom de la voie ou nom de lieu-dit le cas échéant.'],
ARRAY['TRONCON_DE_ROUTE','nom_2_gauche','NOM_2_G','Nom 2 gauche : Nom secondaire de la rue, côté gauche du tronçon (éventuel nom de lieu-dit).'],
ARRAY['TRONCON_DE_ROUTE','nom_2_droite','NOM_2_D','Nom 2 droite : Nom secondaire de la rue, côté droit du tronçon (éventuel nom de lieu-dit).'],
ARRAY['TRONCON_DE_ROUTE','borne_debut_gauche','BORNEDEB_G','Borne début gauche : Numéro de borne à gauche du tronçon en son sommet initial.'],
ARRAY['TRONCON_DE_ROUTE','borne_debut_droite','BORNEDEB_D','Borne début droite : Numéro de borne à droite du tronçon en son sommet initial.'],
ARRAY['TRONCON_DE_ROUTE','borne_fin_gauche','BORNEFIN_G','Borne fin gauche : Numéro de borne à gauche du tronçon en son sommet final.'],
ARRAY['TRONCON_DE_ROUTE','borne_fin_droite','BORNEFIN_D','Borne fin droite : Numéro de borne à droite du tronçon en son sommet final.'],
ARRAY['TRONCON_DE_ROUTE','insee_commune_gauche','INSEECOM_G','INSEE commune gauche : Code INSEE de la commune située à droite du tronçon.'],
ARRAY['TRONCON_DE_ROUTE','insee_commune_droite','INSEECOM_D','INSEE commune droite : Code INSEE de la commune située à gauche du tronçon.'],
ARRAY['TRONCON_DE_ROUTE','type_d_adressage_du_troncon','TYP_ADRES','Type d´adressage du tronçon : Type d´adressage du tronçon.'],
ARRAY['TRONCON_DE_ROUTE','alias_gauche','ALIAS_G','Alias gauche : Ancien nom, nom en langue régionale ou désignation d’une voie communale utilisé pour le côté gauche de la rue.'],
ARRAY['TRONCON_DE_ROUTE','alias_droit','ALIAS_D','Alias droit : Ancien nom, nom en langue régionale ou désignation d’une voie communale utilisé pour le côté droit de la rue.'],
ARRAY['TRONCON_DE_ROUTE','code_postal_gauche','C_POSTAL_G','Code postal gauche : Code postal du bureau distributeur des adresses situées à gauche du tronçon par rapport à son sens de numérisation.'],
ARRAY['TRONCON_DE_ROUTE','code_postal_droit','C_POSTAL_D','Code postal droit : Code postal du bureau distributeur des adresses situées à droite du tronçon par rapport à son sens de numérisation.'],
ARRAY['TRONCON_DE_ROUTE','liens_vers_route_nommee','ID_RN','Liens vers route nommée : .'],
ARRAY['TRONCON_DE_ROUTE','cpx_classement_administratif','CL_ADMIN','Type de route : Classement administratif de la route.'],
ARRAY['TRONCON_DE_ROUTE','cpx_numero','NUMERO','Numéro : Numéro d´une route classée.'],
ARRAY['TRONCON_DE_ROUTE','cpx_gestionnaire','GESTION','Gestionnaire : Gestionnaire d´une route classée.'],
ARRAY['TRONCON_DE_ROUTE','cpx_numero_route_europeenne','NUM_EUROP','Numéro : Numéro d´une route européenne.'],
ARRAY['TRONCON_DE_ROUTE','cpx_toponyme_route_nommee','TOPONYME','Toponyme : Toponyme d´une route nommée (n´inclut pas les noms de rue).'],
ARRAY['TRONCON_DE_ROUTE','cpx_toponyme_itineraire_cyclable','ITI_CYCL','Toponyme : Nom d´un itinéraire cyclable.'],
ARRAY['TRONCON_DE_ROUTE','cpx_toponyme_voie_verte','VOIE_VERTE','Toponyme : Nom d´une voie verte.'],
ARRAY['TRONCON_DE_ROUTE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['NON_COMMUNICATION','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['NON_COMMUNICATION','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['NON_COMMUNICATION','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['NON_COMMUNICATION','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['NON_COMMUNICATION','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['NON_COMMUNICATION','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['NON_COMMUNICATION','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['NON_COMMUNICATION','lien_vers_troncon_entree','ID_TR_ENT','Lien vers tronçon entrée : Identifiant du tronçon à partir duquel on ne peut se rendre vers les tronçons sortants de ce nœud.'],
ARRAY['NON_COMMUNICATION','liens_vers_troncon_sortie','ID_TR_SOR','Liens vers tronçon sortie : Identifiant des tronçons constituant le chemin vers lequel on ne peut se rendre à partir du tronçon entrant de ce nœud.'],
ARRAY['NON_COMMUNICATION','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','type_de_route','TYPE_ROUTE','Type de route : Statut d´une route numérotée ou nommée.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','gestionnaire','GESTION','Gestionnaire : Gestionnaire administratif de la route.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','numero','NUMERO','Numéro : Numéro de la route.'],
ARRAY['ROUTE_NUMEROTEE_OU_NOMMEE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['POINT_DE_REPERE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['POINT_DE_REPERE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['POINT_DE_REPERE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['POINT_DE_REPERE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['POINT_DE_REPERE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['POINT_DE_REPERE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['POINT_DE_REPERE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['POINT_DE_REPERE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['POINT_DE_REPERE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['POINT_DE_REPERE','code_insee_du_departement','INSEE_DEP','Code INSEE du département : Code INSEE du département.'],
ARRAY['POINT_DE_REPERE','route','ROUTE','Route : Numéro de la route classée à laquelle le PR est associé.'],
ARRAY['POINT_DE_REPERE','numero','NUMERO','Numéro : Numéro du PR propre à la route à laquelle il est associé.'],
ARRAY['POINT_DE_REPERE','abscisse','ABSCISSE','Abscisse : Abscisse du PR le long de la route à laquelle il est associé.'],
ARRAY['POINT_DE_REPERE','cote','COTE','Côté : Côté de la route où se situe le PR par rapport au sens des PR croissants .'],
ARRAY['POINT_DE_REPERE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['EQUIPEMENT_DE_TRANSPORT','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['EQUIPEMENT_DE_TRANSPORT','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','etat_de_l_objet','ETAT','Etat de l´objet transport : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','fictif','FICTIF','Fictif : Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision).'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','nature','NATURE','Nature : Nature de l´équipement.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise de l´équipement.'],
ARRAY['EQUIPEMENT_DE_TRANSPORT','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['POINT_DU_RESEAU','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['POINT_DU_RESEAU','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['POINT_DU_RESEAU','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['POINT_DU_RESEAU','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['POINT_DU_RESEAU','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['POINT_DU_RESEAU','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['POINT_DU_RESEAU','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['POINT_DU_RESEAU','etat_de_l_objet','ETAT','Etat de l´objet transport : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité.'],
ARRAY['POINT_DU_RESEAU','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['POINT_DU_RESEAU','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['POINT_DU_RESEAU','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['POINT_DU_RESEAU','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['POINT_DU_RESEAU','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['POINT_DU_RESEAU','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['POINT_DU_RESEAU','nature','NATURE','Nature : Nature d´un point particulier situé sur un réseau de communication.'],
ARRAY['POINT_DU_RESEAU','nature_detaillee','NAT_DETAIL','Nature détaillée : Attribut précisant la nature d´un point particulier situé sur un réseau de communication.'],
ARRAY['POINT_DU_RESEAU','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['POINT_D_ACCES','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['POINT_D_ACCES','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['POINT_D_ACCES','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['POINT_D_ACCES','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['POINT_D_ACCES','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['POINT_D_ACCES','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['POINT_D_ACCES','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['POINT_D_ACCES','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['POINT_D_ACCES','sens','SENS','Sens : Indique si ce point d´accès à un équipement correspond à une entrée, une sortie ou aux deux.'],
ARRAY['POINT_D_ACCES','mode','MODE','Mode : Précise à qui est destiné le point d´accès.'],
ARRAY['POINT_D_ACCES','lien_vers_point_d_interet','ID_POI','Lien vers point d´intérêt : .'],
ARRAY['POINT_D_ACCESS','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['PISTE_D_AERODROME','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['PISTE_D_AERODROME','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['PISTE_D_AERODROME','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['PISTE_D_AERODROME','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['PISTE_D_AERODROME','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['PISTE_D_AERODROME','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['PISTE_D_AERODROME','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['PISTE_D_AERODROME','etat_de_l_objet','ETAT','Etat de l´objet transport : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité.'],
ARRAY['PISTE_D_AERODROME','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['PISTE_D_AERODROME','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['PISTE_D_AERODROME','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['PISTE_D_AERODROME','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['PISTE_D_AERODROME','nature','NATURE','Nature : Attribut précisant le revêtement de la piste.'],
ARRAY['PISTE_D_AERODROME','fonction','FONCTION','Fonction : Fonction associée à la piste.'],
ARRAY['PISTE_D_AERODROME','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['AERODROME','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['AERODROME','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['AERODROME','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['AERODROME','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['AERODROME','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['AERODROME','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['AERODROME','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['AERODROME','etat_de_l_objet','ETAT','Etat de l´objet transport : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité.'],
ARRAY['AERODROME','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['AERODROME','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['AERODROME','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['AERODROME','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['AERODROME','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['AERODROME','fictif','FICTIF','Fictif : Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision).'],
ARRAY['AERODROME','nature','NATURE','Nature : Nature de l´aérodrome (Aérodrome, Altiport, Héliport, Hydrobase).'],
ARRAY['AERODROME','categorie','CATEGORIE','Catégorie : Catégorie de l´aérodrome en fonction de la circulation aérienne.'],
ARRAY['AERODROME','usage','USAGE','Usage : Usage de l´aérodrome (civil, militaire, privé).'],
ARRAY['AERODROME','code_icao','CODE_ICAO','Code ICAO : Code ICAO (Organisation de l´Aviation Civile Internationale) de l´aérodrome .'],
ARRAY['AERODROME','code_iata','CODE_IATA','Code IATA : Code IATA (International Air Transport Association) de l´aérodrome.'],
ARRAY['AERODROME','altitude','ALTITUDE','Altitude : Altitude moyenne de l´aérodrome.'],
ARRAY['AERODROME','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TRONCON_DE_VOIE_FERREE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['TRONCON_DE_VOIE_FERREE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['TRONCON_DE_VOIE_FERREE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TRONCON_DE_VOIE_FERREE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['TRONCON_DE_VOIE_FERREE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TRONCON_DE_VOIE_FERREE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['TRONCON_DE_VOIE_FERREE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['TRONCON_DE_VOIE_FERREE','etat_de_l_objet','ETAT','Etat de l´objet transport : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité.'],
ARRAY['TRONCON_DE_VOIE_FERREE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['TRONCON_DE_VOIE_FERREE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['TRONCON_DE_VOIE_FERREE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['TRONCON_DE_VOIE_FERREE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['TRONCON_DE_VOIE_FERREE','nature','NATURE','Nature : Attribut permettant de distinguer plusieurs types de voies ferrées selon leur fonction.'],
ARRAY['TRONCON_DE_VOIE_FERREE','electrifie','ELECTRIFIE','Electrifié : Indique si la voie ferrée est électrifiée.'],
ARRAY['TRONCON_DE_VOIE_FERREE','largeur','LARGEUR','Largeur : Attribut permettant de distinguer les voies ferrées de largeur standard pour la France (1,435 m), des voies ferrées plus larges ou plus étroites.'],
ARRAY['TRONCON_DE_VOIE_FERREE','nombre_de_voies','NB_VOIES','Nombre de voies : Attribut indiquant si une ligne de chemin de fer est constituée d´une seule voie ferrée ou de plusieurs.'],
ARRAY['TRONCON_DE_VOIE_FERREE','position_par_rapport_au_sol','POS_SOL','Position par rapport au sol : Niveau de l’objet par rapport à la surface du sol (valeur négative pour un objet souterrain, nulle pour un objet au sol et positive pour un objet en sursol).'],
ARRAY['TRONCON_DE_VOIE_FERREE','usage','USAGE','Usage : Précise le type de transport auquel la voie ferrée est destinée.'],
ARRAY['TRONCON_DE_VOIE_FERREE','vitesse_maximale','VITES_MAX','Vitesse maximale : Vitesse maximale pour laquelle la ligne a été construite.'],
ARRAY['TRONCON_DE_VOIE_FERREE','liens_vers_voie_ferree_nommee','ID_VFN','Liens vers voie ferrée nommée : .'],
ARRAY['TRONCON_DE_VOIE_FERREE','cpx_toponyme','TOPONYME','Toponyme : Nom de la ligne ferroviaire.'],
ARRAY['TRONCON_DE_VOIE_FERREE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['VOIE_FERREE_NOMMEE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['VOIE_FERREE_NOMMEE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['VOIE_FERREE_NOMMEE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['VOIE_FERREE_NOMMEE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['VOIE_FERREE_NOMMEE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['VOIE_FERREE_NOMMEE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['VOIE_FERREE_NOMMEE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['VOIE_FERREE_NOMMEE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['VOIE_FERREE_NOMMEE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['VOIE_FERREE_NOMMEE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['VOIE_FERREE_NOMMEE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['VOIE_FERREE_NOMMEE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TRANSPORT_PAR_CABLE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['TRANSPORT_PAR_CABLE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['TRANSPORT_PAR_CABLE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TRANSPORT_PAR_CABLE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['TRANSPORT_PAR_CABLE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TRANSPORT_PAR_CABLE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['TRANSPORT_PAR_CABLE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['TRANSPORT_PAR_CABLE','etat_de_l_objet','ETAT','Etat de l´objet transport : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité.'],
ARRAY['TRANSPORT_PAR_CABLE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['TRANSPORT_PAR_CABLE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['TRANSPORT_PAR_CABLE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['TRANSPORT_PAR_CABLE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['TRANSPORT_PAR_CABLE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['TRANSPORT_PAR_CABLE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['TRANSPORT_PAR_CABLE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['TRANSPORT_PAR_CABLE','nature','NATURE','Nature : Attribut permettant de distinguer différents types de transport par câble.'],
ARRAY['TRANSPORT_PAR_CABLE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TOPONYMIE_TRANSPORT','cleabs_de_l_objet','ID',' : Identifiant de l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_TRANSPORT','classe_de_l_objet','CLASSE',' : Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_TRANSPORT','nature_de_l_objet','NATURE',' : Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet).'],
ARRAY['TOPONYMIE_TRANSPORT','graphie_du_toponyme','GRAPHIE',' : Une des graphies possibles pour décrire l´objet topographique.'],
ARRAY['TOPONYMIE_TRANSPORT','source_du_toponyme','SOURCE',' : Source de la graphie (peut être différent de la source de l´objet topographique lui-même).'],
ARRAY['TOPONYMIE_TRANSPORT','statut_du_toponyme','STATUT_TOP',' : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['TOPONYMIE_TRANSPORT','date_du_toponyme','DATE_TOP',' : Date d´enregistrement ou de validation du toponyme.'],
ARRAY['TOPONYMIE_TRANSPORT','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['BATIMENT','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['BATIMENT','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['BATIMENT','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['BATIMENT','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['BATIMENT','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['BATIMENT','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['BATIMENT','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['BATIMENT','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['BATIMENT','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['BATIMENT','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['BATIMENT','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['BATIMENT','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['BATIMENT','nature','NATURE','Nature : Attribut permettant de distinguer différents types de bâtiments selon leur architecture.'],
ARRAY['BATIMENT','origine_du_batiment','ORIGIN_BAT','Origine du bâtiment : Attribut indiquant si la géométrie du bâtiment est issue de l´imagerie aérienne ou du cadastre.'],
ARRAY['BATIMENT','usage_1','USAGE1','Usage 1 : Usage principal du bâtiment.'],
ARRAY['BATIMENT','usage_2','USAGE2','Usage 2 : Usage secondaire du bâtiment.'],
ARRAY['BATIMENT','construction_legere','LEGER','Construction légère : Indique qu´il s´agit d´une structure légère, non attachée au sol par l´intermédiaire de fondations, ou d´un bâtiment ou partie de bâtiment ouvert sur au moins un côté.'],
ARRAY['BATIMENT','hauteur','HAUTEUR','Hauteur : Hauteur du bâtiment mesuré entre le sol et la gouttière (altitude maximum de la polyligne décrivant le bâtiment).'],
ARRAY['BATIMENT','nombre_d_etages','NB_ETAGES','Nombre d´étages : Nombre total d´étages du bâtiment.'],
ARRAY['BATIMENT','nombre_de_logements','NB_LOGTS','Nombre de logements : Nombre de logements dans le bâtiment.'],
ARRAY['BATIMENT','materiaux_des_murs','MAT_MURS','Matériaux des murs : Code sur 2 caractères : http://piece-jointe-carto.developpement-durable.gouv.fr/NAT004/DTerNP/html3/annexes/desc_pb40_pevprincipale_dmatgm.html.'],
ARRAY['BATIMENT','materiaux_de_la_toiture','MAT_TOITS','Matériaux de la toiture : Code sur 2 caractères : http://piece-jointe-carto.developpement-durable.gouv.fr/NAT004/DTerNP/html3/annexes/desc_pb40_pevprincipale_dmatto.html.'],
ARRAY['BATIMENT','altitude_maximale_sol','Z_MAX_SOL','Altitude maximale sol : Altitude maximale au pied de la construction.'],
ARRAY['BATIMENT','altitude_maximale_toit','Z_MAX_TOIT','Altitude maximale toit : Altitude maximale du toit, c’est-à-dire au faîte du toit.'],
ARRAY['BATIMENT','altitude_minimale_sol','Z_MIN_SOL','Altitude minimale sol : Altitude minimale au pied de la construction.'],
ARRAY['BATIMENT','altitude_minimale_toit','Z_MIN_TOIT','Altitude minimale toit : Altitude minimale du toit, c’est-à-dire au bord du toit ou à la gouttière.'],
ARRAY['BATIMENT','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['CONSTRUCTION_SURFACIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['CONSTRUCTION_SURFACIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['CONSTRUCTION_SURFACIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CONSTRUCTION_SURFACIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['CONSTRUCTION_SURFACIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CONSTRUCTION_SURFACIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['CONSTRUCTION_SURFACIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['CONSTRUCTION_SURFACIQUE','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['CONSTRUCTION_SURFACIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['CONSTRUCTION_SURFACIQUE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['CONSTRUCTION_SURFACIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['CONSTRUCTION_SURFACIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['CONSTRUCTION_SURFACIQUE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['CONSTRUCTION_SURFACIQUE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['CONSTRUCTION_SURFACIQUE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['CONSTRUCTION_SURFACIQUE','nature','NATURE','Nature : Nature de la construction.'],
ARRAY['CONSTRUCTION_SURFACIQUE','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise de la construction.'],
ARRAY['CONSTRUCTION_SURFACIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['RESERVOIR','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['RESERVOIR','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['RESERVOIR','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['RESERVOIR','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['RESERVOIR','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['RESERVOIR','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['RESERVOIR','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['RESERVOIR','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['RESERVOIR','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['RESERVOIR','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['RESERVOIR','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['RESERVOIR','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['RESERVOIR','nature','NATURE','Nature : Nature du réservoir.'],
ARRAY['RESERVOIR','hauteur','HAUTEUR','Hauteur : Hauteur du réservoir.'],
ARRAY['RESERVOIR','altitude_maximale_sol','Z_MAX_SOL','Altitude maximale sol : Altitude maximale au pied de la construction.'],
ARRAY['RESERVOIR','altitude_maximale_toit','Z_MAX_TOIT','Altitude maximale toit : Altitude maximale du toit.'],
ARRAY['RESERVOIR','altitude_minimale_sol','Z_MIN_SOL','Altitude minimale sol : Altitude minimale au pied de la construction.'],
ARRAY['RESERVOIR','altitude_minimale_toit','Z_MIN_TOIT','Altitude minimale toit : Altitude minimale du toit.'],
ARRAY['RESERVOIR','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TERRAIN_DE_SPORT','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['TERRAIN_DE_SPORT','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['TERRAIN_DE_SPORT','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TERRAIN_DE_SPORT','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['TERRAIN_DE_SPORT','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TERRAIN_DE_SPORT','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['TERRAIN_DE_SPORT','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['TERRAIN_DE_SPORT','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['TERRAIN_DE_SPORT','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['TERRAIN_DE_SPORT','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['TERRAIN_DE_SPORT','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['TERRAIN_DE_SPORT','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['TERRAIN_DE_SPORT','nature','NATURE','Nature : Nature du terrain de sport.'],
ARRAY['TERRAIN_DE_SPORT','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise du terrain de sport.'],
ARRAY['TERRAIN_DE_SPORT','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['CIMETIERE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['CIMETIERE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['CIMETIERE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CIMETIERE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['CIMETIERE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CIMETIERE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['CIMETIERE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['CIMETIERE','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['CIMETIERE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['CIMETIERE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['CIMETIERE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['CIMETIERE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['CIMETIERE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['CIMETIERE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['CIMETIERE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['CIMETIERE','nature','NATURE','Nature : Attribut permettant de distinguer les cimetières civils des cimetières militaires.'],
ARRAY['CIMETIERE','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise du cimetière.'],
ARRAY['CIMETIERE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['CONSTRUCTION_LINEAIRE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['CONSTRUCTION_LINEAIRE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['CONSTRUCTION_LINEAIRE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CONSTRUCTION_LINEAIRE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['CONSTRUCTION_LINEAIRE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CONSTRUCTION_LINEAIRE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['CONSTRUCTION_LINEAIRE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['CONSTRUCTION_LINEAIRE','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['CONSTRUCTION_LINEAIRE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['CONSTRUCTION_LINEAIRE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['CONSTRUCTION_LINEAIRE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['CONSTRUCTION_LINEAIRE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['CONSTRUCTION_LINEAIRE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['CONSTRUCTION_LINEAIRE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['CONSTRUCTION_LINEAIRE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['CONSTRUCTION_LINEAIRE','nature','NATURE','Nature : Nature de la construction.'],
ARRAY['CONSTRUCTION_LINEAIRE','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise de la construction.'],
ARRAY['CONSTRUCTION_LINEAIRE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['CONSTRUCTION_PONCTUELLE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['CONSTRUCTION_PONCTUELLE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['CONSTRUCTION_PONCTUELLE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CONSTRUCTION_PONCTUELLE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['CONSTRUCTION_PONCTUELLE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CONSTRUCTION_PONCTUELLE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['CONSTRUCTION_PONCTUELLE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['CONSTRUCTION_PONCTUELLE','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['CONSTRUCTION_PONCTUELLE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['CONSTRUCTION_PONCTUELLE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['CONSTRUCTION_PONCTUELLE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['CONSTRUCTION_PONCTUELLE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['CONSTRUCTION_PONCTUELLE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['CONSTRUCTION_PONCTUELLE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['CONSTRUCTION_PONCTUELLE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['CONSTRUCTION_PONCTUELLE','nature','NATURE','Nature : Nature de la construction.'],
ARRAY['CONSTRUCTION_PONCTUELLE','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise de la construction.'],
ARRAY['CONSTRUCTION_PONCTUELLE','hauteur','HAUTEUR','Hauteur : Hauteur de la construction.'],
ARRAY['CONSTRUCTION_PONCTUELLE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['PYLONE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['PYLONE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['PYLONE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['PYLONE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['PYLONE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['PYLONE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['PYLONE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['PYLONE','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['PYLONE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['PYLONE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['PYLONE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['PYLONE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['PYLONE','hauteur','HAUTEUR','Hauteur : Hauteur du pylône.'],
ARRAY['PYLONE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['LIGNE_OROGRAPHIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['LIGNE_OROGRAPHIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['LIGNE_OROGRAPHIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['LIGNE_OROGRAPHIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['LIGNE_OROGRAPHIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['LIGNE_OROGRAPHIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['LIGNE_OROGRAPHIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['LIGNE_OROGRAPHIQUE','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['LIGNE_OROGRAPHIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['LIGNE_OROGRAPHIQUE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['LIGNE_OROGRAPHIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['LIGNE_OROGRAPHIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['LIGNE_OROGRAPHIQUE','nature','NATURE','Nature : Nature de la ligne orographique.'],
ARRAY['LIGNE_OROGRAPHIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TOPONYMIE_BATI','cleabs_de_l_objet','ID',' : Identifiant de l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_BATI','classe_de_l_objet','CLASSE',' : Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_BATI','nature_de_l_objet','NATURE',' : Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet).'],
ARRAY['TOPONYMIE_BATI','graphie_du_toponyme','GRAPHIE',' : Une des graphies possibles pour décrire l´objet topographique.'],
ARRAY['TOPONYMIE_BATI','source_du_toponyme','SOURCE',' : Source de la graphie (peut être différent de la source de l´objet topographique lui-même).'],
ARRAY['TOPONYMIE_BATI','statut_du_toponyme','STATUT_TOP',' : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['TOPONYMIE_BATI','date_du_toponyme','DATE_TOP',' : Date d´enregistrement ou de validation du toponyme.'],
ARRAY['TOPONYMIE_BATI','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','fictif','FICTIF','Fictif : Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision).'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','categorie','CATEGORIE','Catégorie : Attribut permettant de distinguer plusieurs types d´activité sans rentrer dans le détail de chaque nature.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','nature','NATURE','Nature : Nature de la zone d´activité ou d´intérêt.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise de la zone d´activité ou d´intérêt.'],
ARRAY['ZONE_D_ACTIVITE_OU_D_INTERET','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['LIGNE_ELECTRIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['LIGNE_ELECTRIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['LIGNE_ELECTRIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['LIGNE_ELECTRIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['LIGNE_ELECTRIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['LIGNE_ELECTRIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['LIGNE_ELECTRIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['LIGNE_ELECTRIQUE','etat_de_l_objet','ETAT','Etat de l´objet : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['LIGNE_ELECTRIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['LIGNE_ELECTRIQUE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['LIGNE_ELECTRIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['LIGNE_ELECTRIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['LIGNE_ELECTRIQUE','voltage','VOLTAGE','Voltage : Tension de construction (ligne hors tension) ou d´exploitation maximum (ligne sous tension) de la ligne électrique.'],
ARRAY['LIGNE_ELECTRIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['POSTE_DE_TRANSFORMATION','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['POSTE_DE_TRANSFORMATION','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['POSTE_DE_TRANSFORMATION','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['POSTE_DE_TRANSFORMATION','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['POSTE_DE_TRANSFORMATION','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['POSTE_DE_TRANSFORMATION','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['POSTE_DE_TRANSFORMATION','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['POSTE_DE_TRANSFORMATION','etat_de_l_objet','ETAT','Etat de l´objet : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['POSTE_DE_TRANSFORMATION','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['POSTE_DE_TRANSFORMATION','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['POSTE_DE_TRANSFORMATION','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['POSTE_DE_TRANSFORMATION','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['POSTE_DE_TRANSFORMATION','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['POSTE_DE_TRANSFORMATION','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['POSTE_DE_TRANSFORMATION','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['POSTE_DE_TRANSFORMATION','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['CANALISATION','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['CANALISATION','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['CANALISATION','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CANALISATION','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['CANALISATION','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['CANALISATION','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['CANALISATION','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['CANALISATION','etat_de_l_objet','ETAT','Etat de l´objet : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['CANALISATION','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['CANALISATION','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['CANALISATION','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['CANALISATION','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['CANALISATION','nature','NATURE','Nature : Nature de la matière transportée.'],
ARRAY['CANALISATION','position_par_rapport_au_sol','POS_SOL','Position par rapport au sol : Position de l´infrastructure par rapport au niveau du sol.'],
ARRAY['CANALISATION','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ERP','cleabs','ID',' : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ERP','gcms_date_creation','DATE_CREAT',' : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ERP','gcms_date_modification','DATE_MAJ',' : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ERP','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ERP','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ERP','date_d_apparition','DATE_APP',' : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ERP','date_de_confirmation','DATE_CONF',' : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ERP','etat_de_l_objet','ETAT',' : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['ERP','precision_planimetrique','PREC_PLANI',' : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['ERP','sources','SOURCE',' : Organismes attestant l´existence de l´objet.'],
ARRAY['ERP','identifiants_sources','ID_SOURCE',' : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['ERP','id_reference','ID_REF',' : Identifiant de référence unique partagé entre les acteurs .'],
ARRAY['ERP','libelle','LIBELLE',' : Dénomination libre de l’établissement.'],
ARRAY['ERP','categorie','CATEGORIE',' : Catégorie dans laquelle est classé l´établissement.'],
ARRAY['ERP','type_principal','TYPE_1',' : Type d´établissement principal.'],
ARRAY['ERP','types_secondaires','TYPE_2',' : Types d´établissement secondaires.'],
ARRAY['ERP','activite_principale','ACTIV_1',' : Activité principale de l´établissement.'],
ARRAY['ERP','activites_secondaires','ACTIV_2',' : Activités secondaires de l´établissement.'],
ARRAY['ERP','public','PUBLIC',' : Etablissement public ou non.'],
ARRAY['ERP','ouvert','OUVERT',' : Etablissement effectivement ouvert ou non.'],
ARRAY['ERP','capacite_d_accueil_du_public','CAP_ACC',' : Capacité totale d´accueil au public.'],
ARRAY['ERP','capacite_d_hebergement','CAP_HEBERG',' : Capacité d´hébergement.'],
ARRAY['ERP','numero_siret','SIRET',' : Numéro SIRET de l´établissement.'],
ARRAY['ERP','adresse_numero','ADR_NUMERO',' : Numéro de l´adresse de l´établissement.'],
ARRAY['ERP','adresse_indice_de_repetition','ADR_REP',' : Indice de répétition de l´adresse de l´établissement.'],
ARRAY['ERP','adresse_designation_de_l_entree','ADR_COMPL',' : Complément d´adressage de l´adresse de l´établissement.'],
ARRAY['ERP','adresse_nom_1','ADR_NOM_1',' : Nom de voie de l´adresse de l´établissement.'],
ARRAY['ERP','adresse_nom_2','ADR_NOM_2',' : Elément d´adressage complémentaire de l´adresse de l´établissement.'],
ARRAY['ERP','insee_commune','CODE_INSEE',' : Code INSEE de la commune.'],
ARRAY['ERP','code_postal','CODE_POST',' : Code postal.'],
ARRAY['ERP','origine_de_la_geometrie','ORIGIN_GEO',' : Origine de la géométrie.'],
ARRAY['ERP','type_de_localisation','TYPE_LOC',' : Type de localisation de l´objet.'],
ARRAY['ERP','validation_ign','VALID_IGN',' : Validation par l´IGN de l´objet ou non.'],
ARRAY['ERP','liens_vers_batiment','ID_BATI',' : .'],
ARRAY['ERP','liens_vers_enceinte','ID_ENCEINT',' : .'],
ARRAY['ERP','liens_vers_adresse','ID_ADRESSE',' : .'],
ARRAY['ERP','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TOPONYMIE_SERVICES_ET_ACTIVITES','cleabs_de_l_objet','ID',' : Identifiant de l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_SERVICES_ET_ACTIVITES','classe_de_l_objet','CLASSE',' : Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_SERVICES_ET_ACTIVITES','nature_de_l_objet','NATURE',' : Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet).'],
ARRAY['TOPONYMIE_SERVICES_ET_ACTIVITES','graphie_du_toponyme','GRAPHIE',' : Une des graphies possibles pour décrire l´objet topographique.'],
ARRAY['TOPONYMIE_SERVICES_ET_ACTIVITES','source_du_toponyme','SOURCE',' : Source de la graphie (peut être différent de la source de l´objet topographique lui-même).'],
ARRAY['TOPONYMIE_SERVICES_ET_ACTIVITES','statut_du_toponyme','STATUT_TOP',' : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['TOPONYMIE_SERVICES_ET_ACTIVITES','date_du_toponyme','DATE_TOP',' : Date d´enregistrement ou de validation du toponyme.'],
ARRAY['TOPONYMIE_SERVICES_ET_ACTIVITES','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ZONE_DE_VEGETATION','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ZONE_DE_VEGETATION','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ZONE_DE_VEGETATION','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ZONE_DE_VEGETATION','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ZONE_DE_VEGETATION','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ZONE_DE_VEGETATION','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ZONE_DE_VEGETATION','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ZONE_DE_VEGETATION','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['ZONE_DE_VEGETATION','nature','NATURE','Nature : Nature de la végétation.'],
ARRAY['ZONE_DE_VEGETATION','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['HAIE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['HAIE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['HAIE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['HAIE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['HAIE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['HAIE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['HAIE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['HAIE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['HAIE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ZONE_D_ESTRAN','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ZONE_D_ESTRAN','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ZONE_D_ESTRAN','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ZONE_D_ESTRAN','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ZONE_D_ESTRAN','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ZONE_D_ESTRAN','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ZONE_D_ESTRAN','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ZONE_D_ESTRAN','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['ZONE_D_ESTRAN','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['ZONE_D_ESTRAN','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['ZONE_D_ESTRAN','nature','NATURE','Nature : Nature de la zone d´estran.'],
ARRAY['ZONE_D_ESTRAN','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['PARC_OU_RESERVE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['PARC_OU_RESERVE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['PARC_OU_RESERVE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['PARC_OU_RESERVE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['PARC_OU_RESERVE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['PARC_OU_RESERVE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['PARC_OU_RESERVE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['PARC_OU_RESERVE','etat_de_l_objet','ETAT','Etat de l´objet : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['PARC_OU_RESERVE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['PARC_OU_RESERVE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['PARC_OU_RESERVE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['PARC_OU_RESERVE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['PARC_OU_RESERVE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['PARC_OU_RESERVE','fictif','FICTIF','Fictif : Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision).'],
ARRAY['PARC_OU_RESERVE','nature','NATURE','Nature : Nature de la zone réglementée.'],
ARRAY['PARC_OU_RESERVE','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise de la zone réglementée.'],
ARRAY['PARC_OU_RESERVE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['FORET_PUBLIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['FORET_PUBLIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['FORET_PUBLIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['FORET_PUBLIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['FORET_PUBLIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['FORET_PUBLIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['FORET_PUBLIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['FORET_PUBLIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['FORET_PUBLIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['FORET_PUBLIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['FORET_PUBLIQUE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['FORET_PUBLIQUE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['FORET_PUBLIQUE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['FORET_PUBLIQUE','nature','NATURE','Nature : Nature de la forêt publique.'],
ARRAY['FORET_PUBLIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TOPONYMIE_ZONES_REGLEMENTEES','cleabs_de_l_objet','ID',' : Identifiant de l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_ZONES_REGLEMENTEES','classe_de_l_objet','CLASSE',' : Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_ZONES_REGLEMENTEES','nature_de_l_objet','NATURE',' : Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet).'],
ARRAY['TOPONYMIE_ZONES_REGLEMENTEES','graphie_du_toponyme','GRAPHIE',' : Une des graphies possibles pour décrire l´objet topographique.'],
ARRAY['TOPONYMIE_ZONES_REGLEMENTEES','source_du_toponyme','SOURCE',' : Source de la graphie (peut être différent de la source de l´objet topographique lui-même).'],
ARRAY['TOPONYMIE_ZONES_REGLEMENTEES','statut_du_toponyme','STATUT_TOP',' : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['TOPONYMIE_ZONES_REGLEMENTEES','date_du_toponyme','DATE_TOP',' : Date d´enregistrement ou de validation du toponyme.'],
ARRAY['TOPONYMIE_ZONES_REGLEMENTEES','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['SURFACE_HYDROGRAPHIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['SURFACE_HYDROGRAPHIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','etat_de_l_objet','ETAT','Etat de l´objet : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','nature','NATURE','Nature : Nature d´un objet hydrographique.'],
--ARRAY['SURFACE_HYDROGRAPHIQUE','statut_de_l_objet_hydrographique','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','statut','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
--ARRAY['SURFACE_HYDROGRAPHIQUE','mode_d_obtention_de_la_resolution','SRC_COORD','Mode d´obtention de la résolution : Méthode d’obtention de la résolution d´un tronçon hydrographique.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','mode_d_obtention_des_coordonnees','SRC_COORD','Mode d´obtention de la résolution : Méthode d’obtention de la résolution d´un tronçon hydrographique.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','mode_d_obtention_de_l_altitude','SRC_ALTI','Mode d´obtention de l´altitude : .'],
ARRAY['SURFACE_HYDROGRAPHIQUE','persistance','PERSISTANC','Persistance : Degré de persistance de l´écoulement de l´eau.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','position_par_rapport_au_sol','POS_SOL','Position par rapport au sol : Niveau de l’objet par rapport à la surface du sol.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','origine','ORIGINE','Origine : Origine, naturelle ou artificielle, du tronçon hydrographique.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','salinite','SALINITE','Salinité : Permet de préciser si la surface élémentaire est de type eau salée (oui) ou eau douce (non).'],
ARRAY['SURFACE_HYDROGRAPHIQUE','code_du_pays','CODE_PAYS','Code du pays : Code du pays auquel appartient la surface hydrographique.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','code_hydrographique','CODE_HYDRO','Code hydrographique : Code hydrographique.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','commentaire_sur_l_objet_hydro','COMMENT','Commentaire sur l´objet hydro : Commentaire sur l´objet hydrographique.'],
ARRAY['SURFACE_HYDROGRAPHIQUE','liens_vers_plan_d_eau','ID_P_EAU','Liens vers plan d´eau : .'],
ARRAY['SURFACE_HYDROGRAPHIQUE','liens_vers_cours_d_eau','ID_C_EAU','Liens vers cours d´eau : .'],
ARRAY['SURFACE_HYDROGRAPHIQUE','lien_vers_entite_de_transition','ID_ENT_TR','Lien vers entité de transition : .'],
ARRAY['SURFACE_HYDROGRAPHIQUE','cpx_toponyme_de_plan_d_eau','NOM_P_EAU','CPX_Toponyme de plan d´eau : .'],
--ARRAY['SURFACE_HYDROGRAPHIQUE','cpx_toponyme_de_cours_deau','NOM_C_EAU','CPX_Toponyme de cours d´eau : .'],
ARRAY['SURFACE_HYDROGRAPHIQUE','cpx_toponyme_de_cours_d_eau','NOM_C_EAU','CPX_Toponyme de cours d´eau : .'],
ARRAY['SURFACE_HYDROGRAPHIQUE','cpx_toponyme_d_entite_de_transition','NOM_ENT_TR','CPX_Toponyme d´entité de transition : .'],
ARRAY['SURFACE_HYDROGRAPHIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['TRONCON_HYDROGRAPHIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['TRONCON_HYDROGRAPHIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','etat_de_l_objet','ETAT','Etat de l´objet : Etat ou stade d´un objet qui peut être en projet, en construction ou en service.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','fictif','FICTIF','Fictif : Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision).'],
ARRAY['TRONCON_HYDROGRAPHIQUE','nature','NATURE','Nature : Nature d´un tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','statut','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','numero_d_ordre','NUM_ORDRE','Numéro d´ordre : Nombre (ou code) exprimant le degré de ramification d´un tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','strategie_de_classement','CLA_ORDRE','Stratégie de classement du tronçon : Stratégie de classement du tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','perimetre_d_utilisation_ou_origine','PER_ORDRE','Périmètre d´utilisation ou origine : Périmètre d´utilisation ou origine du tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','sens_de_l_ecoulement','SENS_ECOUL','Sens de l´écoulement : Sens d´écoulement de l´eau dans le tronçon par rapport à la numérisation de sa géométrie.'],
--ARRAY['TRONCON_HYDROGRAPHIQUE','mode_d_obtention_de_la_resolution','SRC_COORD','Mode d´obtention de la résolution : Méthode d’obtention de la résolution d´un tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','mode_d_obtention_des_coordonnees','SRC_COORD','Mode d´obtention de la résolution : Méthode d’obtention de la résolution d´un tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','mode_d_obtention_de_l_altitude','SRC_ALTI','Mode d´obtention de l´altitude : Mode d´obtention de l´altitude.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','reseau_principal_coulant','RES_COULAN','Réseau principal coulant : Appartient au réseau principal coulant.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','delimitation','DELIMIT','delimitation : Indique que la délimitation (par exemple, limites et autres informations) d´un objet géographique est connue.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','origine','ORIGINE','Origine : Origine, naturelle ou artificielle, du tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','classe_de_largeur','LARGEUR','Classe de largeur : Classe de largeur du tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','salinite','SALINITE','Salinité : Permet de préciser si le tronçon hydrographique est de type eau salée ou eau douce.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','type_de_bras','BRAS','Type de bras : Type de bras.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','persistance','PERSISTANC','Persistance : Degré de persistance de l´écoulement de l´eau.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','position_par_rapport_au_sol','POS_SOL','Position par rapport au sol : Niveau de l’objet par rapport à la surface du sol.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','fosse','FOSSE','Fossé : Indique qu´il s´agit d´un fossé et non pas d´un cours d´eau.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','navigabilite','NAVIGABL','Navigabilité : Navigabilité du tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','code_du_pays','CODE_PAYS','Code du pays : Code du pays auquel appartient le tronçon hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','code_hydrographique','CODE_HYDRO','Code hydrographique : Code hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','commentaire_sur_l_objet_hydro','COMMENT','Commentaire sur l´objet hydro : Commentaire sur l´objet hydrographique.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','inventaire_police_de_l_eau','INV_PO_EAU','Inventaire police de l´eau : Classé à l´inventaire de la police de l´eau.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','identifiant_police_de_l_eau','ID_PO_EAU','Code hydrographique : Identifiant police de l´eau.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','code_du_cours_d_eau_bdcarthage','CODE_CARTH',' : Code générique du cours d´eau BDCarthage.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','liens_vers_cours_d_eau','ID_C_EAU','Liens vers cours d´eau : .'],
ARRAY['TRONCON_HYDROGRAPHIQUE','liens_vers_surface_hydrographique','ID_S_HYDRO','Liens vers surface hydrographique : .'],
ARRAY['TRONCON_HYDROGRAPHIQUE','lien_vers_entite_de_transition','ID_ENT_TR','Lien vers entité de transition : .'],
--ARRAY['TRONCON_HYDROGRAPHIQUE','cpx_toponyme','NOM_C_EAU','CPX_Toponyme : Toponyme du cours d´eau.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','cpx_toponyme_de_cours_d_eau','NOM_C_EAU','CPX_Toponyme : Toponyme du cours d´eau.'],
ARRAY['TRONCON_HYDROGRAPHIQUE','cpx_toponyme_d_entite_de_transition','NOM_ENT_TR','CPX_Toponyme d´entité de transition : .'],
ARRAY['TRONCON_HYDROGRAPHIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['NOEUD_HYDROGRAPHIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['NOEUD_HYDROGRAPHIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','precision_altimetrique','PREC_ALTI','Précision altimétrique : Précision altimétrique de la géométrie décrivant l´objet.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','statut','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','categorie','CATEGORIE','Catégorie : Catégorie du nœud hydrographique.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','code_hydrographique','CODE_HYDRO','Code hydrographique : Code hydrographique.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','commentaire_sur_l_objet_hydro','COMMENT',' : Commentaire sur l´objet hydrographique.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','code_du_pays','CODE_PAYS','Code du pays : Code du pays auquel appartient le tronçon hydrographique.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','mode_d_obtention_des_coordonnees','SRC_COORD','Mode d´obtention des coordonnées : Mode d´obtention des coordonnées planimétriques.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','mode_d_obtention_de_l_altitude','SRC_ALTI','Mode d´obtention de l´altitude : Mode d´obtention de l´altitude.'],
ARRAY['NOEUD_HYDROGRAPHIQUE','liens_vers_cours_d_eau_amont','ID_CE_AMON',' : .'],
ARRAY['NOEUD_HYDROGRAPHIQUE','liens_vers_cours_d_eau_aval','ID_CE_AVAL',' : .'],
ARRAY['NOEUD_HYDROGRAPHIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['LIMITE_TERRE_MER','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['LIMITE_TERRE_MER','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['LIMITE_TERRE_MER','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['LIMITE_TERRE_MER','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['LIMITE_TERRE_MER','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['LIMITE_TERRE_MER','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['LIMITE_TERRE_MER','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['LIMITE_TERRE_MER','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['LIMITE_TERRE_MER','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['LIMITE_TERRE_MER','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['LIMITE_TERRE_MER','statut','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
ARRAY['LIMITE_TERRE_MER','type_de_limite','TYPE_LIMIT','Type de limite : Type de limite (Ligne de base, 0 NGF, Limite salure eaux, Limite de compétence préfet).'],
ARRAY['LIMITE_TERRE_MER','origine','ORIGINE','Origine : Origine de la limite terre-mer (exemple : naturel, artificiel).'],
ARRAY['LIMITE_TERRE_MER','niveau','NIVEAU','Niveau : Niveau d´eau définissant la limite terre-eau (exemples : hautes-eaux, basses eaux).'],
ARRAY['LIMITE_TERRE_MER','code_hydrographique','CODE_HYDRO',' : Code hydrographique.'],
ARRAY['LIMITE_TERRE_MER','code_du_pays','CODE_PAYS',' : Code du pays auquel appartient la limite.'],
ARRAY['LIMITE_TERRE_MER','mode_d_obtention_des_coordonnees','SRC_COORD',' : Mode d´obtention des coordonnées planimétriques.'],
ARRAY['LIMITE_TERRE_MER','commentaire_sur_l_objet_hydro','COMMENT',' : Commentaire sur l´objet hydrographique.'],
ARRAY['LIMITE_TERRE_MER','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['COURS_D_EAU','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['COURS_D_EAU','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['COURS_D_EAU','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COURS_D_EAU','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['COURS_D_EAU','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['COURS_D_EAU','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['COURS_D_EAU','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['COURS_D_EAU','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['COURS_D_EAU','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['COURS_D_EAU','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['COURS_D_EAU','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['COURS_D_EAU','statut','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
ARRAY['COURS_D_EAU','code_hydrographique','CODE_HYDRO','Code hydrographique : Code hydrographique, signifiant, défini selon une méthode d´ordination donnée .'],
ARRAY['COURS_D_EAU','commentaire_sur_l_objet_hydro','COMMENT','Commentaire sur l´objet hydro : Commentaire sur l´objet hydrographique.'],
ARRAY['COURS_D_EAU','influence_de_la_maree','MAREE','Influence de la marée : Indique si l´eau de surface est affectée par la marée.'],
ARRAY['COURS_D_EAU','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['COURS_D_EAU','caractere_permanent','PERMANENT','Caractère permanent : Indique si le cours d´eau est permanent.'],
ARRAY['COURS_D_EAU','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['PLAN_D_EAU','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['PLAN_D_EAU','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['PLAN_D_EAU','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['PLAN_D_EAU','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['PLAN_D_EAU','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['PLAN_D_EAU','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['PLAN_D_EAU','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['PLAN_D_EAU','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['PLAN_D_EAU','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['PLAN_D_EAU','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['PLAN_D_EAU','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['PLAN_D_EAU','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['PLAN_D_EAU','nature','NATURE','Nature : Nature d´un objet hydrographique.'],
ARRAY['PLAN_D_EAU','statut','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
ARRAY['PLAN_D_EAU','altitude_moyenne','Z_MOY','Altitude moyenne : Altitude à la cote moyenne ou normale du plan d´eau.'],
ARRAY['PLAN_D_EAU','referentiel_de_l_altitude_moyenne','REF_Z_MOY','Référentiel de l´altitude moy : Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau.'],
--ARRAY['PLAN_D_EAU','mode_d_obtention_de_l_altitude','MODE_Z_MOY','Mode d´obtention de l´altitude moy : Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau.'],
ARRAY['PLAN_D_EAU','mode_d_obtention_de_l_altitude_moy','MODE_Z_MOY','Mode d´obtention de l´altitude moy : Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau.'],
ARRAY['PLAN_D_EAU','precision_de_l_altitude_moyenne','PREC_Z_MOY','Précision de l´altitude moyenne : Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau.'],
ARRAY['PLAN_D_EAU','hauteur_d_eau_maximale','HAUT_MAX','Hauteur d´eau maximale : Hauteur d’eau maximale d’un plan d’eau artificiel.'],
ARRAY['PLAN_D_EAU','mode_d_obtention_de_la_hauteur','OBT_HT_MAX','Mode d´obtention de la hauteur : Méthode d´obtention de la hauteur maximale du plan d´eau.'],
ARRAY['PLAN_D_EAU','code_hydrographique','CODE_HYDRO','Code hydrographique : Code hydrographique, signifiant, défini selon une méthode d´ordination donnée.'],
ARRAY['PLAN_D_EAU','commentaire_sur_l_objet_hydro','COMMENT','Commentaire sur l´objet hydro : Commentaire sur l´objet hydrographique.'],
ARRAY['PLAN_D_EAU','influence_de_la_maree','MAREE','Influence de la marée : Indique si l´eau de surface est affectée par la marée.'],
ARRAY['PLAN_D_EAU','caractere_permanent','PERMANENT','Caractère permanent : Indique si le plan d´eau est permanent.'],
ARRAY['PLAN_D_EAU','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ENTITE_DE_TRANSITION','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ENTITE_DE_TRANSITION','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ENTITE_DE_TRANSITION','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ENTITE_DE_TRANSITION','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ENTITE_DE_TRANSITION','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ENTITE_DE_TRANSITION','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ENTITE_DE_TRANSITION','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ENTITE_DE_TRANSITION','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['ENTITE_DE_TRANSITION','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['ENTITE_DE_TRANSITION','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['ENTITE_DE_TRANSITION','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['ENTITE_DE_TRANSITION','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['ENTITE_DE_TRANSITION','statut','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
ARRAY['ENTITE_DE_TRANSITION','code_hydrographique','CODE_HYDRO','Code hydrographique : Code hydrographique.'],
ARRAY['ENTITE_DE_TRANSITION','commentaire_sur_l_objet_hydro','COMMENT',' : Commentaire sur l´objet hydrographique.'],
ARRAY['ENTITE_DE_TRANSITION','influence_de_la_maree','MAREE','Influence de la marée : Indique si l´eau de surface est affectée par la marée.'],
ARRAY['ENTITE_DE_TRANSITION','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','statut','STATUT','Statut de l´objet hydrographique : Statut de l´objet dans le système d´information.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','code_hydrographique','CODE_HYDRO','Code hydrographique : Code hydrographique du bassin versant.'],
--ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','mode_d_obtention_de_la_resolution','SRC_COORD','Mode d´obtention de la résolution : Méthode d’obtention de la résolution d´un tronçon hydrographique.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','mode_d_obtention_des_coordonnees','SRC_COORD','Mode d´obtention de la résolution : Méthode d’obtention de la résolution d´un tronçon hydrographique.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','commentaire_sur_l_objet_hydro','COMMENT','Commentaire sur l´objet hydro : Commentaire sur l´objet hydrographique, Tronçon hydrographique.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','code_du_bassin_hydrographique','CODE_BH','Code du bassin hydrographique : Code du bassin hydrographique.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','libelle_du_bassin_hydrographique','BASS_HYDRO','Libellé du bassin hydrographique : Libellé du bassin hydrographique.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','origine','ORIGINE','Origine : Origine, naturelle ou artificielle, du tronçon hydrographique.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','bassin_fluvial','B_FLUVIAL','Bassin fluvial : Indique si le bassin versant est un bassin fluvial.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','code_bdcarthage','CODE_CARTH','Code BDCarthage : Code de la zone BDCarthage.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','liens_vers_cours_d_eau_principal','ID_C_EAU','Liens vers cours d´eau principal.'],
ARRAY['BASSIN_VERSANT_TOPOGRAPHIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['DETAIL_HYDROGRAPHIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['DETAIL_HYDROGRAPHIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','nature','NATURE','Nature : Nature du détail hydrographique.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise du détail hydrographique.'],
ARRAY['DETAIL_HYDROGRAPHIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TOPONYMIE_HYDROGRAPHIE','cleabs_de_l_objet','ID',' : Identifiant de l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_HYDROGRAPHIE','classe_de_l_objet','CLASSE',' : Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_HYDROGRAPHIE','nature_de_l_objet','NATURE',' : Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet).'],
ARRAY['TOPONYMIE_HYDROGRAPHIE','graphie_du_toponyme','GRAPHIE',' : Une des graphies possibles pour décrire l´objet topographique.'],
ARRAY['TOPONYMIE_HYDROGRAPHIE','source_du_toponyme','SOURCE',' : Source de la graphie (peut être différent de la source de l´objet topographique lui-même).'],
ARRAY['TOPONYMIE_HYDROGRAPHIE','statut_du_toponyme','STATUT_TOP',' : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['TOPONYMIE_HYDROGRAPHIE','date_du_toponyme','DATE_TOP',' : Date d´enregistrement ou de validation du toponyme.'],
ARRAY['TOPONYMIE_HYDROGRAPHIE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ZONE_D_HABITATION','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ZONE_D_HABITATION','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ZONE_D_HABITATION','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ZONE_D_HABITATION','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ZONE_D_HABITATION','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ZONE_D_HABITATION','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['ZONE_D_HABITATION','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['ZONE_D_HABITATION','etat_de_l_objet','ETAT','Etat de l´objet bati : Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines.'],
ARRAY['ZONE_D_HABITATION','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['ZONE_D_HABITATION','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['ZONE_D_HABITATION','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['ZONE_D_HABITATION','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['ZONE_D_HABITATION','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['ZONE_D_HABITATION','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['ZONE_D_HABITATION','fictif','FICTIF','Fictif : Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision).'],
ARRAY['ZONE_D_HABITATION','nature','NATURE','Nature : Nature de la zone d´habitation.'],
ARRAY['ZONE_D_HABITATION','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise de la zone d´habitation.'],
ARRAY['ZONE_D_HABITATION','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['LIEU_DIT_NON_HABITE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['LIEU_DIT_NON_HABITE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['LIEU_DIT_NON_HABITE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['LIEU_DIT_NON_HABITE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['LIEU_DIT_NON_HABITE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['LIEU_DIT_NON_HABITE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['LIEU_DIT_NON_HABITE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['LIEU_DIT_NON_HABITE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['LIEU_DIT_NON_HABITE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['LIEU_DIT_NON_HABITE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['LIEU_DIT_NON_HABITE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['LIEU_DIT_NON_HABITE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['LIEU_DIT_NON_HABITE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['LIEU_DIT_NON_HABITE','nature','NATURE','Nature : Nature de l´espace naturel.'],
ARRAY['LIEU_DIT_NON_HABITE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['DETAIL_OROGRAPHIQUE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['DETAIL_OROGRAPHIQUE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['DETAIL_OROGRAPHIQUE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['DETAIL_OROGRAPHIQUE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['DETAIL_OROGRAPHIQUE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['DETAIL_OROGRAPHIQUE','date_d_apparition','DATE_APP','Date d´apparition : Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain.'],
ARRAY['DETAIL_OROGRAPHIQUE','date_de_confirmation','DATE_CONF','Date de confirmation : Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain.'],
ARRAY['DETAIL_OROGRAPHIQUE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['DETAIL_OROGRAPHIQUE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['DETAIL_OROGRAPHIQUE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['DETAIL_OROGRAPHIQUE','importance','IMPORTANCE','Importance : Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative.'],
ARRAY['DETAIL_OROGRAPHIQUE','toponyme','TOPONYME','Toponyme : Toponyme de l´objet.'],
ARRAY['DETAIL_OROGRAPHIQUE','statut_du_toponyme','STATUT_TOP','Statut du toponyme : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['DETAIL_OROGRAPHIQUE','nature','NATURE','Nature : Nature du détail orographique.'],
ARRAY['DETAIL_OROGRAPHIQUE','nature_detaillee','NAT_DETAIL','Nature détaillée : Nature précise du détail orographique.'],
ARRAY['DETAIL_OROGRAPHIQUE','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['TOPONYMIE_LIEUX_NOMMES','cleabs_de_l_objet','ID',' : Identifiant de l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_LIEUX_NOMMES','classe_de_l_objet','CLASSE',' : Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme.'],
ARRAY['TOPONYMIE_LIEUX_NOMMES','nature_de_l_objet','NATURE',' : Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet).'],
ARRAY['TOPONYMIE_LIEUX_NOMMES','graphie_du_toponyme','GRAPHIE',' : Une des graphies possibles pour décrire l´objet topographique.'],
ARRAY['TOPONYMIE_LIEUX_NOMMES','source_du_toponyme','SOURCE',' : Source de la graphie (peut être différent de la source de l´objet topographique lui-même).'],
ARRAY['TOPONYMIE_LIEUX_NOMMES','statut_du_toponyme','STATUT_TOP',' : Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité.'],
ARRAY['TOPONYMIE_LIEUX_NOMMES','date_du_toponyme','DATE_TOP',' : Date d´enregistrement ou de validation du toponyme.'],
ARRAY['TOPONYMIE_LIEUX_NOMMES','geometrie','geom','Champs comptenant la géométrie de l´objet.'],
ARRAY['ADRESSE','cleabs','ID','Cleabs : Identifiant unique de l´objet dans la BDTopo.'],
--ARRAY['ADRESSE','gcms_date_creation','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
--ARRAY['ADRESSE','gcms_date_modification','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ADRESSE','date_creat','DATE_CREAT','GCMS_Date création : Date à laquelle l´objet a été saisi pour la première fois dans la base de données.'],
ARRAY['ADRESSE','date_maj','DATE_MAJ','GCMS_Date modification : Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données.'],
ARRAY['ADRESSE','precision_planimetrique','PREC_PLANI','Précision planimétrique : Précision planimétrique de la géométrie décrivant l´objet.'],
ARRAY['ADRESSE','sources','SOURCE','Sources : Organismes attestant l´existence de l´objet.'],
ARRAY['ADRESSE','identifiants_sources','ID_SOURCE','Identifiants sources : Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire.'],
ARRAY['ADRESSE','numero','NUMERO','Numéro : Numéro de l’adresse dans la voie, sans indice de répétition.'],
ARRAY['ADRESSE','numero_fictif','NUM_FICTIF','Numéro fictif : Vrai si le numéro n´est pas un numéro définitif ou significatif.'],
ARRAY['ADRESSE','indice_de_repetition','REP','Indice de répétition : Indice de répétition.'],
ARRAY['ADRESSE','designation_de_l_entree','COMPL','Désignation de l´entrée : Désignation de l’entrée précisant l’adresse dans les habitats collectifs.'],
ARRAY['ADRESSE','nom_1','NOM_1','Nom 1 : Nom principal de l’adresse : nom de la voie ou nom de lieu-dit le cas échéant.'],
ARRAY['ADRESSE','nom_2','NOM_2','Nom 2 : Nom secondaire de l´adresse : un éventuel nom de lieu-dit.'],
ARRAY['ADRESSE','insee_commune','CODE_INSEE','INSEE commune : Numéro INSEE de la commune de l’adresse.'],
ARRAY['ADRESSE','code_postal','CODE_POST','Code postal : Code postal de la commune.'],
ARRAY['ADRESSE','cote','COTE','Côté : Côté du tronçon de route où est située l’adresse (à droite ou à gauche) en fonction de son sens de numérisation du tronçon dans la base.'],
ARRAY['ADRESSE','type_de_localisation','TYPE_LOC','Type de localisation : Localisation de l´adresse.'],
ARRAY['ADRESSE','methode','METHODE','Méthode : Méthode de positionnement de l´adresse.'],
ARRAY['ADRESSE','alias','ALIAS','Alias : Dénomination ancienne de la voie, un nom de la voie en langue régionale, une voie communale, ou un nom du lieu-dit relatif à l’adresse en usage local.'],
ARRAY['ADRESSE','lien_vers_objet_support_1','ID_SUPPOR1','Lien vers objet support 1 : Identifiant de l´objet support 1 (Tronçon de route, Zone d´habitation, ...) de l’adresse.'],
ARRAY['ADRESSE','lien_vers_objet_support_2','ID_SUPPOR2','Lien vers objet support 2 : Identifiant de l´objet support 2 (Tronçon de route, Zone d´habitation, ...) de l’adresse.'],
ARRAY['ADRESSE','geometrie','geom','Champs comptenant la géométrie de l´objet.']
];
nb_valeur := array_length(liste_valeur, 1);

FOR i_table IN 1..nb_valeur LOOP
---- Récupération des champs
---- Nom de la table
	select
		case
			when COVADIS is false then 
				lower(liste_valeur[i_table][1])
			else
				case
					when millesime is not null then
						'n_' || lower(liste_valeur[i_table][1]) || '_bdt_' || emprise || '_' || millesime
					else
						'n_' || lower(liste_valeur[i_table][1]) || '_bdt_' || emprise
				end
		end
		 into nom_table;
---- Nom du champs à commenter		
	SELECT 
		CASE
			WHEN livraison = 'sql' THEN lower(liste_valeur[i_table][2])
			ELSE lower(liste_valeur[i_table][3])
		END
		into champs;
---- Nom du commentaire	
	SELECT liste_valeur[i_table][4] into commentaires;
	/*-- debug
	RAISE NOTICE '%', i_table;
	RAISE NOTICE '%', nom_table;
	RAISE NOTICE '%', champs;
	RAISE NOTICE '%', commentaires;
	-- debug */

---- Execution de la requete
	IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) then
		req := '
				COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || champs || ' IS ''' || commentaires || ''';
				';
		--RAISE NOTICE '%', req;
		EXECUTE(req);
	else
		req := '
				La table ' || nom_schema || '.' || nom_table || ' n´est pas présente pour le champs ' || champs || '.
				';
		RAISE NOTICE '%', req;
	END IF;

END LOOP; 

RETURN current_time;
END; 

$function$
;

COMMENT ON FUNCTION w_adl_delegue.set_comment_bdtopo_3("varchar","bpchar","bpchar","bpchar","bool") IS '[ADMIN - BDTOPO] - Mise en place des commentaires

Option :
- nom du schéma où se trouvent les tables
- format de livraison de l''IGN :
	- ''shp'' = shapefile
	- ''sql'' = dump postgis
- emprise sur 3 caractères selon la COVADIS ddd : 
	- ''fra'' : France Entière
	- ''000'' : France Métropolitaine
	- ''rrr'' : Numéro INSEE de la Région : ''r84'' pour Avergne-Rhône-Alpes
	- ''ddd'' : Numéro INSEE du département : ''038'' pour l''Isère
				non pris en compte si COVADIS = false
- millesime selon COVADIS : aaaa pour l''année du millesime ou null si pas de millesime
				non pris en compte si COVADIS = false
- COVADIS : nommage des tble selon la COVADIS : oui : true / non false

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


dernière MAJ : 12/12/2019';
