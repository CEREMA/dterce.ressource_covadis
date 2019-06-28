CREATE OR REPLACE FUNCTION w_adl_delegue.set_comment_bdtopo_30(covadis boolean DEFAULT false, emprise character varying DEFAULT NULL::character varying, millesime character varying DEFAULT NULL::character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/*
[ADMIN - BDTOPO] - Mise en place des commentaires

Option :
- nommage COVADIS  par défault non
- si oui :
	emprise : ddd pour département, rrr pour région, 000 pour métropole, fra pour France entière,
	millesime : aaaa pour l'année du millesime

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


dernière MAJ : 28/06/2019
*/

declare
nom_schema 					character varying;		-- Schéma du référentiel en text
nom_table 					character varying;		-- nom de la table en text
req 						text;
veriftable 					character varying;
tb_toutestables				character varying[];	-- Toutes les tables
nb_toutestables 			integer;				-- Nombre de tables --> normalement XX
attribut 					character varying; 		-- Liste des attributs de la table
nomgeometrie 				text; 					-- "GeometryType" de la table

begin
IF covadis is true
	THEN
		nom_schema:='r_bdtopo_' || millesime;
	ELSE
		nom_schema:='public';
END IF;

---- D. Mise en place des commentaires
---- D.1 adresse
IF covadis is true
	then
		nom_table := 'n_adresse_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'adresse';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Point matérialisant une adresse postale'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero IS ''Numéro de l’adresse dans la voie, sans indice de répétition'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero_fictif IS ''Vrai si le numéro n´est pas un numéro définitif ou significatif'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.indice_de_repetition IS ''Indice de répétition'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.designation_de_l_entree IS ''Désignation de l’entrée précisant l’adresse dans les habitats collectifs'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_1 IS ''Nom principal de l’adresse : nom de la voie ou nom de lieu-dit le cas échéant'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_2 IS ''Nom secondaire de l´adresse : un éventuel nom de lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.insee_commune IS ''Numéro INSEE de la commune de l’adresse'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_postal IS ''Code postal de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cote IS ''Côté du tronçon de route où est située l’adresse (à droite ou à gauche) en fonction de son sens de numérisation du tronçon dans la base'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type_de_localisation IS ''Localisation de l´adresse'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.methode IS ''Méthode de positionnement de l´adresse'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.alias IS ''Dénomination ancienne de la voie, un nom de la voie en langue régionale, une voie communale, ou un nom du lieu-dit relatif à l’adresse en usage local'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lien_vers_objet_support_1 IS ''Identifiant de l´objet support 1 (Tronçon de route, Zone d´habitation, ...) de l’adresse'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lien_vers_objet_support_2 IS ''Identifiant de l´objet support 2 (Tronçon de route, Zone d´habitation, ...) de l’adresse'';		
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT.'';
		';
	RAISE NOTICE '%', req;
		EXECUTE(req);
END IF;

---- D.2 aerodrome
IF covadis is true
	then
		nom_table := 'n_aerodrome_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'aerodrome';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Tout terrain ou plan d’eau spécialement aménagé pour l’atterrissage, le décollage et les manoeuvres des aéronefs y compris les installations annexes qu’il peut comporter pour les besoins du trafic et le service des aéronefs'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de l´aérodrome (Aérodrome, Altiport, Héliport, Hydrobase)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.categorie IS ''Catégorie de l´aérodrome en fonction de la circulation aérienne'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.usage IS ''Usage de l´aérodrome (civil, militaire, privé)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_icao IS ''Code ICAO (Organisation de l´Aviation Civile Internationale) de l´aérodrome '';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_iata IS ''Code IATA (International Air Transport Association) de l´aérodrome'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude IS ''Altitude moyenne de l´aérodrome'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
		';
	RAISE NOTICE '%', req;
		EXECUTE(req);
END IF;

---- D.3 arrondissement
IF covadis is true
	then
		nom_table := 'n_arrondissement_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'arrondissement';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Circonscription administrative déconcentrée de l’État, subdivision du département'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_l_arrondissement IS ''Code INSEE de l´arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_du_departement IS ''Code INSEE du département'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_la_region IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_officiel IS ''Nom officiel de l´arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
	';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.4 arrondissement_municipal
IF covadis is true
	then
		nom_table := 'n_arrondissement_municipal_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'arrondissement_municipal';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Subdivision territoriale des communes de Lyon, Marseille et Paris'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee IS ''Code INSEE de l´arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_la_commune_de_rattach IS ''Code INSEE de la commune de rattachement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_postal IS ''Code postal utilisé pour l´arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_officiel IS ''Nom officiel de l´arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lien_vers_chef_lieu IS ''Lien vers la zone d´habitation chef-lieu de l´arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_autorite_administrative IS ''Lien vers la mairie d´arrondissement (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.5 bassin_versant_topographique
IF covadis is true
	then
		nom_table := 'n_bassin_versant_topographique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'bassin_versant_topographique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Aire de collecte (impluvium) considérée à partir d’un exutoire ou ensemble d’exutoires, limitée par le contour à l’intérieur duquel se rassemblent les eaux précipitées qui s’écoulent en surface vers cette sortie'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_hydrographique IS ''Code hydrographique du bassin versant'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_des_coordonnees IS ''Méthode utilisée pour déterminer les coordonnées de l´objet hydrographique.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_du_bassin_hydrographique IS ''Code du bassin hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.libelle_du_bassin_hydrographique IS ''Libellé du bassin hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.origine IS ''Origine, naturelle ou artificielle, du tronçon hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.bassin_fluvial IS ''Indique si le bassin versant est un bassin fluvial'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_bdcarthage IS ''Code de la zone BDCarthage'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_cours_d_eau_principal IS ''Identifiant (clé absolue) du cours d´eau principal du bassin versant.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.6 batiment
IF covadis is true
	then
		nom_table := 'n_batiment_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'batiment';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Bâtiment'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Attribut permettant de distinguer différents types de bâtiments selon leur architecture'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.origine_du_batiment IS ''Attribut indiquant si la géométrie du bâtiment est issue de l´imagerie aérienne ou du cadastre'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.usage_1 IS ''Usage principal du bâtiment'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.usage_2 IS ''Usage secondaire du bâtiment'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.construction_legere IS ''Indique qu´il s´agit d´une structure légère, non attachée au sol par l´intermédiaire de fondations, ou d´un bâtiment ou partie de bâtiment ouvert sur au moins un côté'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.hauteur IS ''Hauteur du bâtiment mesuré entre le sol et la gouttière (altitude maximum de la polyligne décrivant le bâtiment)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nombre_d_etages IS ''Nombre total d´étages du bâtiment'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nombre_de_logements IS ''Nombre de logements dans le bâtiment'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.materiaux_des_murs IS ''Code sur 2 caractères : http://piece-jointe-carto.developpement-durable.gouv.fr/NAT004/DTerNP/html3/annexes/desc_pb40_pevprincipale_dmatgm.html'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.materiaux_de_la_toiture IS ''Code sur 2 caractères : http://piece-jointe-carto.developpement-durable.gouv.fr/NAT004/DTerNP/html3/annexes/desc_pb40_pevprincipale_dmatto.html'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_maximale_sol IS ''Altitude maximale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_maximale_toit IS ''Altitude maximale du toit, c’est-à-dire au faîte du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_minimale_sol IS ''Altitude minimale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_minimale_toit IS ''Altitude minimale du toit, c’est-à-dire au bord du toit ou à la gouttière'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.appariement_fichiers_fonciers IS ''Indicateur relatif à la fiabilité de l´appariement avec les fichiers fonciers'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.7 canalisation
IF covadis is true
	then
		nom_table := 'n_canalisation_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'canalisation';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Infrastructure dédiée au transport d’hydrocarbures liquides ou gazeux ou de matière première (tapis roulant industriel)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la matière transportée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.position_par_rapport_au_sol IS ''Position de l´infrastructure par rapport au niveau du sol'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.8 cimetiere
IF covadis is true
	then
		nom_table := 'n_cimetiere_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'cimetiere';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Endroit où reposent les morts'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Attribut permettant de distinguer les cimetières civils des cimetières militaires'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise du cimetière'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.9 collectivite_territoriale
IF covadis is true
	then
		nom_table := 'n_collectivite_territoriale_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'collectivite_territoriale';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Collectivité territoriale correspondant à l’échelon départemental et incluant les départements ainsi que les collectivités territoriales uniques et les collectivités territoriales à statut particulier'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee IS ''Code INSEE de la collectivité départementale (collectivité territoriale située entre la commune et la région)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_la_region IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_officiel IS ''Nom officiel de la collectivité départementale'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_autorite_administrative IS ''Lien vers le siège du conseil de la collectivité (Zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.10 commune_associee_ou_deleguee
IF covadis is true
	then
		nom_table := 'n_commune_associee_ou_deleguee_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'commune_associee_ou_deleguee';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Ancienne commune ayant perdu ainsi son statut de collectivité territoriale en fusionnant avec d’autres communes, mais ayant gardé son territoire et certaines spécificités comme un maire délégué ou une mairie annexe'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee IS ''Code INSEE de la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_la_commune_de_rattach IS ''Code INSEE de la commune de rattachement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_postal IS ''Code postal utilisé pour la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_officiel IS ''Nom officiel de la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lien_vers_chef_lieu IS ''Lien vers la zone d´habitation chef-lieu de la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_autorite_administrative IS ''Lien vers l´annexe de la mairie ou la mairie annexe de la commune déléguée (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.11 commune
IF covadis is true
	then
		nom_table := 'n_commune_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'commune';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Plus petite subdivision du territoire, administrée par un maire, des adjoints et un conseil municipal'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee IS ''Code insee de la commune sur 5 caractères'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_l_arrondissement IS ''Code INSEE de l´arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_la_collectivite_terr IS ''Code INSEE de la collectivité territoriale incluant cette commune'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_du_departement IS ''Code INSEE du département sur 2 ou 3 caractères'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_la_region IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_postal IS ''Code postal utilisé pour la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_officiel IS ''Nom officiel de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.chef_lieu_d_arrondissement IS ''Indique que la commune est chef-lieu d´arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.chef_lieu_de_collectivite_terr IS ''Indique que la commune est chef-lieu d´une collectivité départementale'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.chef_lieu_de_departement IS ''Indique que la commune est chef-lieu d´un département'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.chef_lieu_de_region IS ''Indique que la commune est chef-lieu d´une région'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.capitale_d_etat IS ''Indique que la commune est la capitale d´Etat'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_du_recensement IS ''Date du recensement sur lequel s´appuie le chiffre de population'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.organisme_recenseur IS ''Nom de l´organisme ayant effectué le recensement de population'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.population IS ''Population sans double compte de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.surface_en_ha IS ''Superficie cadastrale de la commune telle que donnée par l´INSEE (en ha)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.codes_siren_des_epci IS ''Codes SIREN de l´EPCI ou des EPCI auxquels appartient cette commune'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lien_vers_chef_lieu IS ''Lien vers la zone d´habitation chef-lieu de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_autorite_administrative IS ''Lien vers la mairie de cette commune (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.12 construction_lineaire
IF covadis is true
	then
		nom_table := 'n_construction_lineaire_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'construction_lineaire';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Construction dont la forme générale est linéaire'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.13 construction_ponctuelle
IF covadis is true
	then
		nom_table := 'n_construction_ponctuelle_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'construction_ponctuelle';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Construction de faible emprise'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.hauteur IS ''Hauteur de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.14 construction_surfacique
IF covadis is true
	then
		nom_table := 'n_construction_surfacique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'construction_surfacique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Ouvrage de grande largeur lié au franchissement d’un obstacle par une voie de communication, ou à l’aménagement d’une rivière ou d’un canal'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.15 cours_d_eau
IF covadis is true
	then
		nom_table := 'n_cours_d_eau_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'cours_d_eau';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Ensemble de tronçons hydrographiques connexes partageant un même toponyme'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_hydrographique IS ''Code hydrographique, signifiant, défini selon une méthode d´ordination donnée '';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.influence_de_la_maree IS ''Indique si l´eau de surface est affectée par la marée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.caractere_permanent IS ''Indique si le cours d´eau est permanent'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTILINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.16 departement
IF covadis is true
	then
		nom_table := 'n_departement_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'departement';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Circonscription administrative déconcentrée de l’État, subdivision de la région et incluant un ou plusieurs arrondissements'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee IS ''Code INSEE du département'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_de_la_region IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_officiel IS ''Nom officiel du département'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_autorite_administrative IS ''Lien vers la préfecture du département (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTILINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.17 detail_hydrographique
IF covadis is true
	then
		nom_table := 'n_detail_hydrographique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'detail_hydrographique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Détail ou espace dont le nom se rapporte à l’hydrographie'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet du thème Transport qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature du détail hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise du détail hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.18 detail_orographique
IF covadis is true
	then
		nom_table := 'n_detail_orographique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'detail_orographique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Détail ou espace dont le nom se rapporte au relief'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature du détail orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise du détail orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.19 epci
IF covadis is true
	then
		nom_table := 'n_epci_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'epci';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Structure administrative regroupant plusieurs communes afin d’exercer certaines compétences en commun (établissement public de coopération intercommunale)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de l´EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_siren IS ''Code SIREN de l´EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_officiel IS ''Nom de l´EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_autorite_administrative IS ''Lien vers le siège de l´autorité administrative de l´EPCI (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.20 equipement_de_transport
IF covadis is true
	then
		nom_table := 'n_equipement_de_transport_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'equipement_de_transport';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Equipement, construction ou aménagement relatif à un réseau de transport terrestre, maritime ou aérien'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec (...)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de l´équipement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise de l´équipement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.21 erp
IF covadis is true
	then
		nom_table := 'n_erp_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'erp';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Etablissements Recevant du Public'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id_reference IS ''Identifiant de référence unique partagé entre les acteurs '';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.libelle IS ''Dénomination libre de l’établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.categorie IS ''Catégorie dans laquelle est classé l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type_principal IS ''Type d´établissement principal'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.types_secondaires IS ''Types d´établissement secondaires'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.activite_principale IS ''Activité principale de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.activites_secondaires IS ''Activités secondaires de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.public IS ''Etablissement public ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.ouvert IS ''Etablissement effectivement ouvert ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.capacite_d_accueil_du_public IS ''Capacité totale d´accueil au public'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.capacite_d_hebergement IS ''Capacité d´hébergement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero_siret IS ''Numéro SIRET de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.adresse_numero IS ''Numéro de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.adresse_indice_de_repetition IS ''Indice de répétition de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.adresse_designation_de_l_entree IS ''Complément d´adressage de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.adresse_nom_1 IS ''Nom de voie de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.adresse_nom_2 IS ''Elément d´adressage complémentaire de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.insee_commune IS ''Code INSEE de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_postal IS ''Code postal'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.origine_de_la_geometrie IS ''Origine de la géométrie'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type_de_localisation IS ''Type de localisation de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.validation_ign IS ''Validation par l´IGN de l´objet ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_batiment IS ''Lien vers la << Clé absolue >> du ou des bâtiments de la BDTOPO accueillant l´ERP'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_enceinte IS ''Lien vers la << Clé absolue >> de la Zone d´activité ou d´intérêt correspondant à l´ERP dans la BDTOPO''; 
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_adresse IS ''Lien vers l´objet Adresse de la BDTOPO'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.22 foret_publique
IF covadis is true
	then
		nom_table := 'n_foret_publique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'foret_publique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Forêt publique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs  IS '' Identifiant unique de l´objet dans la BDTopo '';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la forêt publique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.23 haie
IF covadis is true
	then
		nom_table := 'n_haie_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'haie';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Clôture naturelle composée d’arbres, d’arbustes, d’épines ou de branchages et servant à limiter ou à protéger un champ'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.24 lieu_dit_non_habite
IF covadis is true
	then
		nom_table := 'n_lieu_dit_non_habite_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'lieu_dit_non_habite';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Lieu-dit non habité dont le nom ne se rapporte ni à un détail orographique ni à un détail hydrographique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de l´espace naturel'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.25 ligne_electrique
IF covadis is true
	then
		nom_table := 'n_ligne_electrique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'ligne_electrique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Portion de ligne électrique homogène pour l’ensemble des attributs qui la concernent'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.voltage IS ''Tension de construction (ligne hors tension) ou d´exploitation maximum (ligne sous tension) de la ligne électrique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.26 ligne_orographique
IF covadis is true
	then
		nom_table := 'n_ligne_orographique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'ligne_orographique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Ligne de rupture de pente artificielle'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la ligne orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.27 limite_terre_mer
IF covadis is true
	then
		nom_table := 'n_limite_terre_mer_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'limite_terre_mer';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Ligne au niveau de laquelle une masse continentale est en contact avec une masse d’eau, incluant en particulier le trait de côte, défini par la laisse des plus  hautes mers de vives eaux astronomiques'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type_de_limite IS ''Type de limite (Ligne de base, 0 NGF, Limite salure eaux, Limite de compétence préfet)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.origine IS ''Origine de la limite terre-mer (exemple : naturel, artificiel)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.niveau IS ''Niveau d´eau définissant la limite terre-eau (exemples : hautes-eaux, basses eaux)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_hydrographique IS ''Code hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_du_pays IS ''Code du pays auquel appartient la limite'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_des_coordonnees IS ''Mode d´obtention des coordonnées planimétriques'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.28 noeud_hydrographique
IF covadis is true
	then
		nom_table := 'n_noeud_hydrographique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'noeud_hydrographique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Extrémité particulière d’un tronçon hydrographique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.categorie IS ''Catégorie du nœud hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_hydrographique IS ''Code hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_du_pays IS ''Code du pays auquel appartient le tronçon hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_des_coordonnees IS ''Mode d´obtention des coordonnées planimétriques'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_de_l_altitude IS ''Mode d´obtention de l´altitude'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_cours_d_eau_amont IS ''Liens vers (clé absolue) la classe Cours d´eau définissant le ou les cours d´eau amont au niveau dupoint de confluence (Noeud hydrographique de Nature="Confluent").'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_cours_d_eau_aval IS ''Liens vers (clé absolue) la classe Cours d´eau définissant le ou les cours d´eau aval au niveau du point de confluence (Noeud hydrographique de Nature="Confluent").'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.29 non_communication
IF covadis is true
	then
		nom_table := 'n_non_communication_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'non_communication';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Nœud du réseau routier indiquant l’impossibilité d’accéder à un tronçon ou à un enchaînement de plusieurs tronçons particuliers à partir d’un tronçon de départ donné'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lien_vers_troncon_entree IS ''Identifiant du tronçon à partir duquel on ne peut se rendre vers les tronçons sortants de ce nœud'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_troncon_sortie IS ''Identifiant des tronçons constituant le chemin vers lequel on ne peut se rendre à partir du tronçon entrant de ce nœud'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.30 parc_ou_reserve
IF covadis is true
	then
		nom_table := 'n_parc_ou_reserve_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'parc_ou_reserve';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Zone naturelle faisant l’objet d’une réglementation spécifique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précisi (...)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la zone réglementée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise de la zone réglementée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.31 piste_d_aerodrome
IF covadis is true
	then
		nom_table := 'n_piste_d_aerodrome_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'piste_d_aerodrome';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Aire située sur un aérodrome, aménagée afin de servir au roulement des aéronefs, au décollage et à l’atterrissage'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Attribut précisant le revêtement de la piste'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fonction IS ''Fonction associée à la piste'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.32 plan_d_eau
IF covadis is true
	then
		nom_table := 'n_plan_d_eau_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'plan_d_eau';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Etendue d’eau d’origine naturelle ou anthropique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature d´un objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_moyenne IS ''Altitude à la cote moyenne ou normale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.referentiel_de_l_altitude_moyenne IS ''Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_de_l_altitude_moy IS ''Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_de_l_altitude_moyenne IS ''Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.hauteur_d_eau_maximale IS ''Hauteur d’eau maximale d’un plan d’eau artificiel'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_de_la_hauteur IS ''Méthode d´obtention de la hauteur maximale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_hydrographique IS ''Code hydrographique, signifiant, défini selon une méthode d´ordination donnée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.influence_de_la_maree IS ''Indique si l´eau de surface est affectée par la marée'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.caractere_permanent IS ''Indique si le plan d´eau est permanent'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.33 point_de_repere
IF covadis is true
	then
		nom_table := 'n_point_de_repere_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'point_de_repere';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Point de repère situé le long d’une route et utilisé pour assurer le référencement linéaire d’objets ou d’évènements le long de cette route'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee_du_departement IS ''Code INSEE du département'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.route IS ''Numéro de la route classée à laquelle le PR est associé'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero IS ''Numéro du PR propre à la route à laquelle il est associé'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.abscisse IS ''Abscisse du PR le long de la route à laquelle il est associé'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cote IS ''Côté de la route où se situe le PR par rapport au sens des PR croissants '';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.34 point_du_reseau
IF covadis is true
	then
		nom_table := 'n_point_du_reseau_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'point_du_reseau';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Point particulier d’un réseau de transport pouvant constituer, un obstacle permanent ou temporaire à la circulation'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature d´un point particulier situé sur un réseau de communication'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Attribut précisant la nature d´un point particulier situé sur un réseau de communication'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.35 poste_de_transformation
IF covadis is true
	then
		nom_table := 'n_poste_de_transformation_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'poste_de_transformation';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Enceinte à l’intérieur de laquelle le courant transporté par une ligne électrique est transformé'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.36 pylone
IF covadis is true
	then
		nom_table := 'n_pylone_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'pylone';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Support en charpente métallique ou en béton, d’une ligne électrique aérienne'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.hauteur IS ''Hauteur du pylône'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.37 region
IF covadis is true
	then
		nom_table := 'n_region_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'region';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - La région est à la fois une circonscription administrative déconcentrée de l’Etat qui englobe un ou plusieurs départements, et une collectivité territoriale décentralisée présidé par un conseil régional.'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_officiel IS ''Nom officiel de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_autorite_administrative IS ''Lien vers la préfecture de région (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.38 reservoir
IF covadis is true
	then
		nom_table := 'n_reservoir_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'reservoir';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) then
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Réservoir (eau, matières industrielles,…)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature du réservoir'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.hauteur IS ''Hauteur du réservoir'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_maximale_sol IS ''Altitude maximale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_maximale_toit IS ''Altitude maximale du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_minimale_sol IS ''Altitude minimale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.altitude_minimale_toit IS ''Altitude minimale du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.39 route_numerotee_ou_nommee
IF covadis is true
	then
		nom_table := 'n_route_numerotee_ou_nommee_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'route_numerotee_ou_nommee';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Voie de communication destinée aux automobiles, aux piétons, aux cycles ou aux animaux et possédant un numéro ou un nom particulier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type_de_route IS ''Statut d´une route numérotée ou nommée'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.gestionnaire IS ''Gestionnaire administratif de la route'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero IS ''Numéro de la route'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.40 surface_hydrographique
IF covadis is true
	then
		nom_table := 'n_surface_hydrographique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'surface_hydrographique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Zone couverte d’eau douce, d’eau salée ou glacier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature d´un objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut IS ''Statut de l´objet dans le système d´information'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_des_coordonnees IS ''Méthode utilisée pour déterminer les coordonnées de l´objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_de_l_altitude IS ''Méthode utilisée pour établir l´altitude de l´objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.persistance IS ''Degré de persistance de l´écoulement de l´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.position_par_rapport_au_sol IS ''Niveau de l’objet par rapport à la surface du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.origine IS ''Origine, naturelle ou artificielle, du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.salinite IS ''Permet de préciser si la surface élémentaire est de type eau salée (oui) ou eau douce (non)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_du_pays IS ''Code du pays auquel appartient la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_hydrographique IS ''Code hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_plan_d_eau IS '' Identifiant (clé absolue) de l´objet Plan d´eau parent. Une surface hydrographique peut être liée avec 0 à n objets Plan d´eau ''; 
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_cours_d_eau IS '' Identifiant (clé absolue) de l´objet Cours d´eau traversant la Surface hydrographique. Une surface hydrographique peut être liée avec 0 à n objets Cours d´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lien_vers_entite_de_transition IS '' Identifiant (clé absolue) de l´objet Entité de transition à laquelle appartient la Surface hydrographique (estuaires, deltas...). Une surface hydrographique peut être liée avec 0 ou 1 objet Entité de transition'';
 			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme_de_plan_d_eau IS ''Toponyme(s) du ou des Plans d´eau constitués par la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme_de_cours_d_eau IS ''Toponyme(s) du ou des Cours d´eau traversant la surface hydrographique'';
	 		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme_d_entite_de_transition IS ''Toponyme(s) de l´Entité de transition traversant la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.41 terrain_de_sport
IF covadis is true
	then
		nom_table := 'n_terrain_de_sport_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'terrain_de_sport';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Équipement sportif de plein air'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature du terrain de sport'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise du terrain de sport'';	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.42 toponymie_bati
IF covadis is true
	then
		nom_table := 'n_toponymie_bati_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'toponymie_bati';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème bâti'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.43 toponymie_hydrographie
IF covadis is true
	then
		nom_table := 'n_toponymie_hydrographie_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'toponymie_hydrographie';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème hydrographie'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.44 toponymie_lieux_nommes
IF covadis is true
	then
		nom_table := 'n_toponymie_lieux_nommes_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'toponymie_lieux_nommes';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche des lieux nommés'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.45 toponymie_services_et_activites
IF covadis is true
	then
		nom_table := 'n_toponymie_services_et_activites_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'toponymie_services_et_activites';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème services et activités'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.46 toponymie_transport
IF covadis is true
	then
		nom_table := 'n_toponymie_transport_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'toponymie_transport';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème transport'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.47 toponymie_zones_reglementees
IF covadis is true
	then
		nom_table := 'n_toponymie_zones_reglementees_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'toponymie_zones_reglementees';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème zones réglementées'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.48 transport_par_cable
IF covadis is true
	then
		nom_table := 'n_transport_par_cable_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'transport_par_cable';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Moyen de transport constitué d’un ou de plusieurs câbles porteurs'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Attribut permettant de distinguer différents types de transport par câble'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.49 troncon_de_route
IF covadis is true
	then
		nom_table := 'n_troncon_de_route_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'troncon_de_route';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Portion de voie de communication destinée aux automobiles, aux piétons, aux cycles ou aux animaux,  homogène pour l’ensemble des attributs et des relations qui la concernent'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précis (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Attribut permettant de classer un tronçon de route ou de chemin suivant ses caractéristiques physiques'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.position_par_rapport_au_sol IS ''Position du tronçon par rapport au niveau du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nombre_de_voies IS ''Nombre total de voies de circulation tracées au sol ou effectivement utilisées, sur une route, une rue ou une chaussée de route à chaussées séparées'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.largeur_de_chaussee IS ''Largeur de la chaussée, en mètres'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.itineraire_vert IS ''Indique l’appartenance ou non d’un tronçon routier au réseau vert'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_mise_en_service IS ''Date prévue ou la date effective de mise en service d’un tronçon de route'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.prive IS ''Indique le caractère privé d´un tronçon de route carrossable'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sens_de_circulation IS ''Sens licite de circulation sur les voies pour les véhicules légers'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.bande_cyclable IS ''Sens de circulation sur les bandes cyclables'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.reserve_aux_bus IS ''Sens de circulation sur les voies réservées au bus'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.urbain IS ''Indique que le tronçon de route est situé en zone urbaine'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.vitesse_moyenne_vl IS ''Vitesse moyenne des véhicules légers dans le sens direct'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.acces_vehicule_leger IS ''Conditions de circulation sur le tronçon pour un véhicule léger'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.acces_pieton IS ''Conditions d´accès pour les piétons'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.periode_de_fermeture IS ''Périodes pendant lesquelles le tronçon n´est pas accessible à la circulation automobile'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_de_la_restriction IS ''Nature précise de la restriction sur un tronçon où la circulation automobile est restreinte'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.restriction_de_hauteur IS ''Exprime l´interdiction de circuler pour les véhicules dépassant la hauteur indiquée'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.restriction_de_poids_total IS ''Exprime l´interdiction de circuler pour les véhicules dépassant le poids indiqué'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.restriction_de_poids_par_essieu IS ''Exprime l´interdiction de circuler pour les véhicules dépassant le poids par essieu indiqué'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.restriction_de_largeur IS ''Exprime l´interdiction de circuler pour les véhicules dépassant la largeur indiquée'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.restriction_de_longueur IS ''Exprime l´interdiction de circuler pour les véhicules dépassant la longueur indiquée'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.matieres_dangereuses_interdites IS ''Exprime l´interdiction de circuler pour les véhicules transportant des matières dangereuses'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiant_voie_1_gauche IS ''Identifiant de la voie pour le côté gauche du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiant_voie_1_droite IS ''Identifiant de la voie pour le côté droit du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_1_gauche IS ''Nom principal de la rue, côté gauche du tronçon : nom de la voie ou nom de lieu-dit le cas échéant'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_1_droite IS ''Nom principal de la rue, côté droit du tronçon : nom de la voie ou nom de lieu-dit le cas échéant'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_2_gauche IS ''Nom secondaire de la rue, côté gauche du tronçon (éventuel nom de lieu-dit)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_2_droite IS ''Nom secondaire de la rue, côté droit du tronçon (éventuel nom de lieu-dit)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.borne_debut_gauche IS ''Numéro de borne à gauche du tronçon en son sommet initial'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.borne_debut_droite IS ''Numéro de borne à droite du tronçon en son sommet initial'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.borne_fin_gauche IS ''Numéro de borne à gauche du tronçon en son sommet final'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.borne_fin_droite IS ''Numéro de borne à droite du tronçon en son sommet final'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.insee_commune_gauche IS ''Code INSEE de la commune située à droite du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.insee_commune_droite IS ''Code INSEE de la commune située à gauche du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type_d_adressage_du_troncon IS ''Type d´adressage du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.alias_gauche IS ''Ancien nom, nom en langue régionale ou désignation d’une voie communale utilisé pour le côté gauche de la rue'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.alias_droit IS ''Ancien nom, nom en langue régionale ou désignation d’une voie communale utilisé pour le côté droit de la rue'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_postal_gauche IS ''Code postal du bureau distributeur des adresses situées à gauche du tronçon par rapport à son sens de numérisation'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_postal_droit IS ''Code postal du bureau distributeur des adresses situées à droite du tronçon par rapport à son sens de numérisation'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_route_nommee IS ''Identifiant(s) (clé absolue) de l´objet Route numérotée ou nommée parent(s)''; 
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_classement_administratif IS ''Classement administratif de la route'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_numero IS ''Numéro d´une route classée'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_gestionnaire IS ''Gestionnaire d´une route classée'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_numero_route_europeenne IS ''Numéro d´une route européenne'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme_route_nommee IS ''Toponyme d´une route nommée (n´inclut pas les noms de rue)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme_itineraire_cyclable IS ''Nom d´un itinéraire cyclable'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme_voie_verte IS ''Nom d´une voie verte'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.50 troncon_de_voie_ferree
IF covadis is true
	then
		nom_table := 'n_troncon_de_voie_ferree_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'troncon_de_voie_ferree';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Portion de voie ferrée homogène pour l’ensemble des attributs qui la concernent'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Attribut permettant de distinguer plusieurs types de voies ferrées selon leur fonction'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.electrifie IS ''Indique si la voie ferrée est électrifiée'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.largeur IS ''Attribut permettant de distinguer les voies ferrées de largeur standard pour la France (1,435 m), des voies ferrées plus larges ou plus étroites'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nombre_de_voies IS ''Attribut indiquant si une ligne de chemin de fer est constituée d´une seule voie ferrée ou de plusieurs'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.position_par_rapport_au_sol IS ''Niveau de l’objet par rapport à la surface du sol (valeur négative pour un objet souterrain, nulle pour un objet au sol et positive pour un objet en sursol)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.usage IS ''Précise le type de transport auquel la voie ferrée est destinée'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.vitesse_maximale IS ''Vitesse maximale pour laquelle la ligne a été construite'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_voie_ferree_nommee IS ''Le cas échéant, lien vers l´identifiant (clé absolue) de l´objet Voie ferrée nommée décrivant le parcours et le toponyme de l´itinéraire ferré auquel ce tronçon appartient''; 
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme IS ''Nom de la ligne ferroviaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.51 troncon_hydrographique
IF covadis is true
	then
		nom_table := 'n_troncon_hydrographique_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'troncon_hydrographique';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='

		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Axe du lit d’une rivière, d’un ruisseau ou d’un canal, homogène pour ses attributs et ses relations et n’inclant pas de confluent en dehors de ses extrémités’'';

	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec  (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature d´un tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut IS ''Statut de l´objet dans le système d´information'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero_d_ordre IS ''Nombre (ou code) exprimant le degré de ramification d´un tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.strategie_de_classement IS ''Stratégie de classement du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.perimetre_d_utilisation_ou_origine IS ''Périmètre d´utilisation ou origine du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sens_de_l_ecoulement IS ''Sens d´écoulement de l´eau dans le tronçon par rapport à la numérisation de sa géométrie'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_des_coordonnees IS ''Méthode d’obtention des coordonnées d´un tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.mode_d_obtention_de_l_altitude IS ''Mode d´obtention de l´altitude'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.reseau_principal_coulant IS ''Appartient au réseau principal coulant'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.delimitation IS ''Indique que la délimitation (par exemple, limites et autres informations) d´un objet géographique est connue'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.origine IS ''Origine, naturelle ou artificielle, du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.classe_de_largeur IS ''Classe de largeur du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.salinite IS ''Permet de préciser si le tronçon hydrographique est de type eau salée ou eau douce'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type_de_bras IS ''Type de bras'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.persistance IS ''Degré de persistance de l´écoulement de l´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.position_par_rapport_au_sol IS ''Niveau de l’objet par rapport à la surface du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fosse IS ''Indique qu´il s´agit d´un fossé et non pas d´un cours d´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.navigabilite IS ''Navigabilité du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_du_pays IS ''Code du pays auquel appartient le tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_hydrographique IS ''Code hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.inventaire_police_de_l_eau IS ''Classé à l´inventaire de la police de l´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiant_police_de_l_eau IS ''Identifiant police de l´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_du_cours_d_eau_bdcarthage IS ''Code générique du cours d´eau BDCarthage'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_cours_d_eau IS ''Identifiant (clé absolue) du cours d´eau principal du bassin versant'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.liens_vers_surface_hydrographique IS ''Identifiant(s) du ou des éventuel(s) objets Surface hydrographique traversé(s) par le tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lien_vers_entite_de_transition IS ''Identifiant de l´éventuel objet Entité de transition auquel appartient le tronçon hydrographique''; 
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme_de_cours_d_eau IS ''Toponyme du cours d´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cpx_toponyme_d_entite_de_transition IS ''Toponyme(s) du ou des Entité de transition traversant la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.52 voie_ferree_nommee
IF covadis is true
	then
		nom_table := 'n_voie_ferree_nommee_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'voie_ferree_nommee';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Itinéraire ferré décrivant une voie ferrée nommée, touristique ou non, un vélo-rail'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.53 zone_d_activite_ou_d_interet
IF covadis is true
	then
		nom_table := 'n_zone_d_activite_ou_d_interet_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'zone_d_activite_ou_d_interet';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Lieu dédié à une activité particulière ou présentant un intérêt spécifique'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.categorie IS ''Attribut permettant de distinguer plusieurs types d´activité sans rentrer dans le détail de chaque nature'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la zone d´activité ou d´intérêt'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise de la zone d´activité ou d´intérêt'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.54 zone_d_estran
IF covadis is true
	then
		nom_table := 'n_zone_d_estran_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'zone_d_estran';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Partie du littoral située entre les limites extrêmes des plus hautes et des plus basses marées'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la zone d´estran'';	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.55 zone_d_habitation
IF covadis is true
	then
		nom_table := 'n_zone_d_habitation_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'zone_d_habitation';
		nomgeometrie := 'geometrie';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Zone habitée de manière permanente ou temporaire ou ruines'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.toponyme IS ''Toponyme de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec préci (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la zone d´habitation'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature_detaillee IS ''Nature précise de la zone d´habitation'';	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.56 zone_de_vegetation
IF covadis is true
	then
		nom_table := 'n_zone_de_vegetation_bdt_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'zone_de_vegetation';
		nomgeometrie := 'geometrie';
END IF;
IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN BDTOPO® - Edition 191 - Espace végétal naturel ou non,différencié en particulier selon le couvert forestier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nature IS ''Nature de la végétation'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';		
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

RETURN current_time;
END; 
$function$
;
