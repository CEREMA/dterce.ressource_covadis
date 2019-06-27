--CREATE SCHEMA w_adl_delegue;
--> Finish time	Sat May 18 09:55:41 CEST 2019

CREATE OR REPLACE FUNCTION w_adl_delegue.set_comment_bdtopo_30(emprise character varying, millesime character varying, projection integer DEFAULT 2154)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/*
[ADMIN - BDTOPO] - Administration d´un millesime de la BDTOPO 30 une fois son import réalisé

Taches réalisées :
---- D. Mise en place des commentaires 


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
---- A Create Schema : verification que le schéma n'existe pas et le crééer
---- C.5.1 Ajout de la clef primaire sauf si doublon d?identifiant notamment n_troncon_cours_eau_bdt
erreur : 
ALTER TABLE r_bdtopo_2018.n_toponymie_bati_bdt_000_2018 ADD CONSTRAINT n_toponymie_bati_bdt_000_2018_pkey PRIMARY KEY;
Sur la fonction en cours de travail : Détail :Key (cleabs_de_l_objet)=(CONSSURF0000002000088919) is duplicated..

dernière MAJ : 21/06/2019
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


---- D. Mise en place des commentaires
---- D.1 adresse
nom_table := 'adresse';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Point matérialisant une adresse postale'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='	
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero IS ''Numéro de l’adresse dans la voie, sans indice de répétition'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero_fictif IS ''Vrai si le numéro n´est pas un numéro définitif ou significatif'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.indice_de_repetition IS ''Indice de répétition'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.designation_de_l_entree IS ''Désignation de l’entrée précisant l’adresse dans les habitats collectifs'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_1 IS ''Nom principal de l’adresse : nom de la voie ou nom de lieu-dit le cas échéant'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_2 IS ''Nom secondaire de l´adresse : un éventuel nom de lieu-dit'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.insee_commune IS ''Numéro INSEE de la commune de l’adresse'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cote IS ''Côté du tronçon de route où est située l’adresse (à droite ou à gauche) en fonction de son sens de numérisation du tronçon dans la base'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_localisation IS ''Localisation de l´adresse'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.methode IS ''Méthode de positionnement de l´adresse'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.alias IS ''Dénomination ancienne de la voie, un nom de la voie en langue régionale, une voie communale, ou un nom du lieu-dit relatif à l’adresse en usage local'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_objet_support_1 IS ''Identifiant de l´objet support 1 (Tronçon de route, Zone d´habitation, ...) de l’adresse'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_objet_support_2 IS ''Identifiant de l´objet support 2 (Tronçon de route, Zone d´habitation, ...) de l’adresse'';		
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT.'';
	';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.2 aerodrome
nom_table := 'aerodrome';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Tout terrain ou plan d’eau spécialement aménagé pour l’atterrissage, le décollage et les manoeuvres des aéronefs y compris les installations annexes qu’il peut comporter pour les besoins du trafic et le service des aéronefs'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précision)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de l´aérodrome (Aérodrome, Altiport, Héliport, Hydrobase)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.categorie IS ''Catégorie de l´aérodrome en fonction de la circulation aérienne'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.usage IS ''Usage de l´aérodrome (civil, militaire, privé)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_icao IS ''Code ICAO (Organisation de l´Aviation Civile Internationale) de l´aérodrome '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_iata IS ''Code IATA (International Air Transport Association) de l´aérodrome'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude IS ''Altitude moyenne de l´aérodrome'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON.'';
	';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.3 arrondissement
nom_table := 'arrondissement';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Circonscription administrative déconcentrée de l’État, subdivision du département'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_l_arrondissement IS ''Code INSEE de l´arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_du_departement IS ''Code INSEE du département'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_region IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de l´arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON.'';
	';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.4 arrondissement_municipal
nom_table := 'arrondissement_municipal';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Subdivision territoriale des communes de Lyon, Marseille et Paris'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE de l´arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_commune_de_rattach IS ''Code INSEE de la commune de rattachement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal utilisé pour l´arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de l´arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_chef_lieu IS ''Lien vers la zone d´habitation chef-lieu de l´arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers la mairie d´arrondissement (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON.'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.5 bassin_versant_topographique
nom_table := 'bassin_versant_topographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Aire de collecte (impluvium) considérée à partir d’un exutoire ou ensemble d’exutoires, limitée par le contour à l’intérieur duquel se rassemblent les eaux précipitées qui s’écoulent en surface vers cette sortie'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique du bassin versant'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''Méthode utilisée pour déterminer les coordonnées de l´objet hydrographique.'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_bassin_hydrographique IS ''Code du bassin hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.libelle_du_bassin_hydrographique IS ''Libellé du bassin hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine IS ''Origine, naturelle ou artificielle, du tronçon hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.bassin_fluvial IS ''Indique si le bassin versant est un bassin fluvial'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_bdcarthage IS ''Code de la zone BDCarthage'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau_principal IS ''Identifiant (clé absolue) du cours d´eau principal du bassin versant.'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON.'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.6 batiment
nom_table := 'batiment';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Bâtiment'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de distinguer différents types de bâtiments selon leur architecture'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine_du_batiment IS ''Attribut indiquant si la géométrie du bâtiment est issue de l´imagerie aérienne ou du cadastre'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.usage_1 IS ''Usage principal du bâtiment'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.usage_2 IS ''Usage secondaire du bâtiment'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.construction_legere IS ''Indique qu´il s´agit d´une structure légère, non attachée au sol par l´intermédiaire de fondations, ou d´un bâtiment ou partie de bâtiment ouvert sur au moins un côté'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du bâtiment mesuré entre le sol et la gouttière (altitude maximum de la polyligne décrivant le bâtiment)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nombre_d_etages IS ''Nombre total d´étages du bâtiment'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nombre_de_logements IS ''Nombre de logements dans le bâtiment'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.materiaux_des_murs IS ''Code sur 2 caractères : http://piece-jointe-carto.developpement-durable.gouv.fr/NAT004/DTerNP/html3/annexes/desc_pb40_pevprincipale_dmatgm.html'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.materiaux_de_la_toiture IS ''Code sur 2 caractères : http://piece-jointe-carto.developpement-durable.gouv.fr/NAT004/DTerNP/html3/annexes/desc_pb40_pevprincipale_dmatto.html'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_maximale_sol IS ''Altitude maximale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_maximale_toit IS ''Altitude maximale du toit, c’est-à-dire au faîte du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_minimale_sol IS ''Altitude minimale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_minimale_toit IS ''Altitude minimale du toit, c’est-à-dire au bord du toit ou à la gouttière'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.appariement_fichiers_fonciers IS ''Indicateur relatif à la fiabilité de l´appariement avec les fichiers fonciers'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.7 canalisation
nom_table := 'canalisation';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Infrastructure dédiée au transport d’hydrocarbures liquides ou gazeux ou de matière première (tapis roulant industriel)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la matière transportée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Position de l´infrastructure par rapport au niveau du sol'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.8 cimetiere
nom_table := 'cimetiere';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Endroit où reposent les morts'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de distinguer les cimetières civils des cimetières militaires'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise du cimetière'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.9 collectivite_territoriale
nom_table := 'collectivite_territoriale';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Collectivité territoriale correspondant à l’échelon départemental et incluant les départements ainsi que les collectivités territoriales uniques et les collectivités territoriales à statut particulier'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE de la collectivité départementale (collectivité territoriale située entre la commune et la région)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_region IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de la collectivité départementale'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers le siège du conseil de la collectivité (Zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.10 commune_associee_ou_deleguee
nom_table := 'commune_associee_ou_deleguee';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Ancienne commune ayant perdu ainsi son statut de collectivité territoriale en fusionnant avec d’autres communes, mais ayant gardé son territoire et certaines spécificités comme un maire délégué ou une mairie annexe'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE de la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_commune_de_rattach IS ''Code INSEE de la commune de rattachement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal utilisé pour la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_chef_lieu IS ''Lien vers la zone d´habitation chef-lieu de la commune associée ou déléguée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers l´annexe de la mairie ou la mairie annexe de la commune déléguée (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.11 commune
nom_table := 'commune';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Plus petite subdivision du territoire, administrée par un maire, des adjoints et un conseil municipal'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code insee de la commune sur 5 caractères'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_l_arrondissement IS ''Code INSEE de l´arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_collectivite_terr IS ''Code INSEE de la collectivité territoriale incluant cette commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_du_departement IS ''Code INSEE du département sur 2 ou 3 caractères'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_region IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal utilisé pour la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.chef_lieu_d_arrondissement IS ''Indique que la commune est chef-lieu d´arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.chef_lieu_de_collectivite_terr IS ''Indique que la commune est chef-lieu d´une collectivité départementale'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.chef_lieu_de_departement IS ''Indique que la commune est chef-lieu d´un département'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.chef_lieu_de_region IS ''Indique que la commune est chef-lieu d´une région'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.capitale_d_etat IS ''Indique que la commune est la capitale d´Etat'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_recensement IS ''Date du recensement sur lequel s´appuie le chiffre de population'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.organisme_recenseur IS ''Nom de l´organisme ayant effectué le recensement de population'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.population IS ''Population sans double compte de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.surface_en_ha IS ''Superficie cadastrale de la commune telle que donnée par l´INSEE (en ha)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.codes_siren_des_epci IS ''Codes SIREN de l´EPCI ou des EPCI auxquels appartient cette commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_chef_lieu IS ''Lien vers la zone d´habitation chef-lieu de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers la mairie de cette commune (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.12 construction_lineaire
nom_table := 'construction_lineaire';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Construction dont la forme générale est linéaire'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.13 construction_ponctuelle
nom_table := 'construction_ponctuelle';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Construction de faible emprise'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.14 construction_surfacique
nom_table := 'construction_surfacique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Ouvrage de grande largeur lié au franchissement d’un obstacle par une voie de communication, ou à l’aménagement d’une rivière ou d’un canal'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.15 cours_d_eau
nom_table := 'cours_d_eau';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Ensemble de tronçons hydrographiques connexes partageant un même toponyme'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique, signifiant, défini selon une méthode d´ordination donnée '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.influence_de_la_maree IS ''Indique si l´eau de surface est affectée par la marée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.caractere_permanent IS ''Indique si le cours d´eau est permanent'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTILINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.16 departement
nom_table := 'departement';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Circonscription administrative déconcentrée de l’État, subdivision de la région et incluant un ou plusieurs arrondissements'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE du département'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_region IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel du département'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers la préfecture du département (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTILINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.17 detail_hydrographique
nom_table := 'detail_hydrographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Détail ou espace dont le nom se rapporte à l’hydrographie'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet du thème Transport qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature du détail hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise du détail hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.18 detail_orographique
nom_table := 'detail_orographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Détail ou espace dont le nom se rapporte au relief'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature du détail orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise du détail orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.19 epci
nom_table := 'epci';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Structure administrative regroupant plusieurs communes afin d’exercer certaines compétences en commun (établissement public de coopération intercommunale)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de l´EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_siren IS ''Code SIREN de l´EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom de l´EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers le siège de l´autorité administrative de l´EPCI (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.20 equipement_de_transport
nom_table := 'equipement_de_transport';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Equipement, construction ou aménagement relatif à un réseau de transport terrestre, maritime ou aérien'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec (...)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de l´équipement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise de l´équipement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.21 erp
nom_table := 'erp';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Etablissements Recevant du Public'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.id_reference IS ''Identifiant de référence unique partagé entre les acteurs '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.libelle IS ''Dénomination libre de l’établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.categorie IS ''Catégorie dans laquelle est classé l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_principal IS ''Type d´établissement principal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.types_secondaires IS ''Types d´établissement secondaires'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.activite_principale IS ''Activité principale de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.activites_secondaires IS ''Activités secondaires de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.public IS ''Etablissement public ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.ouvert IS ''Etablissement effectivement ouvert ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.capacite_d_accueil_du_public IS ''Capacité totale d´accueil au public'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.capacite_d_hebergement IS ''Capacité d´hébergement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero_siret IS ''Numéro SIRET de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_numero IS ''Numéro de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_indice_de_repetition IS ''Indice de répétition de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_designation_de_l_entree IS ''Complément d´adressage de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_nom_1 IS ''Nom de voie de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_nom_2 IS ''Elément d´adressage complémentaire de l´adresse de l´établissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.insee_commune IS ''Code INSEE de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine_de_la_geometrie IS ''Origine de la géométrie'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_localisation IS ''Type de localisation de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.validation_ign IS ''Validation par l´IGN de l´objet ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_batiment IS ''Lien vers la << Clé absolue >> du ou des bâtiments de la BDTOPO accueillant l´ERP'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_enceinte IS ''Lien vers la << Clé absolue >> de la Zone d´activité ou d´intérêt correspondant à l´ERP dans la BDTOPO''; 
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_adresse IS ''Lien vers l´objet Adresse de la BDTOPO'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.22 foret_publique
nom_table := 'foret_publique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Forêt publique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs  IS '' Identifiant unique de l´objet dans la BDTopo '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la forêt publique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.23 haie
nom_table := 'haie';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Clôture naturelle composée d’arbres, d’arbustes, d’épines ou de branchages et servant à limiter ou à protéger un champ'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.24 lieu_dit_non_habite
nom_table := 'lieu_dit_non_habite';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Lieu-dit non habité dont le nom ne se rapporte ni à un détail orographique ni à un détail hydrographique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de l´espace naturel'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.25 ligne_electrique
nom_table := 'ligne_electrique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Portion de ligne électrique homogène pour l’ensemble des attributs qui la concernent'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.voltage IS ''Tension de construction (ligne hors tension) ou d´exploitation maximum (ligne sous tension) de la ligne électrique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.26 ligne_orographique
nom_table := 'ligne_orographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Ligne de rupture de pente artificielle'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la ligne orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.27 limite_terre_mer
nom_table := 'limite_terre_mer';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Ligne au niveau de laquelle une masse continentale est en contact avec une masse d’eau, incluant en particulier le trait de côte, défini par la laisse des plus  hautes mers de vives eaux astronomiques'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_limite IS ''Type de limite (Ligne de base, 0 NGF, Limite salure eaux, Limite de compétence préfet)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine IS ''Origine de la limite terre-mer (exemple : naturel, artificiel)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.niveau IS ''Niveau d´eau définissant la limite terre-eau (exemples : hautes-eaux, basses eaux)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_pays IS ''Code du pays auquel appartient la limite'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''Mode d´obtention des coordonnées planimétriques'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.28 noeud_hydrographique
nom_table := 'noeud_hydrographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Extrémité particulière d’un tronçon hydrographique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.categorie IS ''Catégorie du nœud hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_pays IS ''Code du pays auquel appartient le tronçon hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''Mode d´obtention des coordonnées planimétriques'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_l_altitude IS ''Mode d´obtention de l´altitude'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau_amont IS ''Liens vers (clé absolue) la classe Cours d´eau définissant le ou les cours d´eau amont au niveau dupoint de confluence (Noeud hydrographique de Nature="Confluent").'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau_aval IS ''Liens vers (clé absolue) la classe Cours d´eau définissant le ou les cours d´eau aval au niveau du point de confluence (Noeud hydrographique de Nature="Confluent").'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.29 non_communication
nom_table := 'non_communication';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Nœud du réseau routier indiquant l’impossibilité d’accéder à un tronçon ou à un enchaînement de plusieurs tronçons particuliers à partir d’un tronçon de départ donné'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_troncon_entree IS ''Identifiant du tronçon à partir duquel on ne peut se rendre vers les tronçons sortants de ce nœud'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_troncon_sortie IS ''Identifiant des tronçons constituant le chemin vers lequel on ne peut se rendre à partir du tronçon entrant de ce nœud'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.30 parc_ou_reserve
nom_table := 'parc_ou_reserve';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Zone naturelle faisant l’objet d’une réglementation spécifique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précisi (...)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone réglementée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise de la zone réglementée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.31 piste_d_aerodrome
nom_table := 'piste_d_aerodrome';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Aire située sur un aérodrome, aménagée afin de servir au roulement des aéronefs, au décollage et à l’atterrissage'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut précisant le revêtement de la piste'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fonction IS ''Fonction associée à la piste'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.32 plan_d_eau
nom_table := 'plan_d_eau';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Etendue d’eau d’origine naturelle ou anthropique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature d´un objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l´objet dans le système d´information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_moyenne IS ''Altitude à la cote moyenne ou normale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.referentiel_de_l_altitude_moyenne IS ''Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_l_altitude_moy IS ''Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_de_l_altitude_moyenne IS ''Méthode d´obtention de l´altitude à la cote moyenne ou normale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur_d_eau_maximale IS ''Hauteur d’eau maximale d’un plan d’eau artificiel'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_la_hauteur IS ''Méthode d´obtention de la hauteur maximale du plan d´eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique, signifiant, défini selon une méthode d´ordination donnée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.influence_de_la_maree IS ''Indique si l´eau de surface est affectée par la marée'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.caractere_permanent IS ''Indique si le plan d´eau est permanent'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.33 point_de_repere
nom_table := 'point_de_repere';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Point de repère situé le long d’une route et utilisé pour assurer le référencement linéaire d’objets ou d’évènements le long de cette route'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_du_departement IS ''Code INSEE du département'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.route IS ''Numéro de la route classée à laquelle le PR est associé'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero IS ''Numéro du PR propre à la route à laquelle il est associé'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.abscisse IS ''Abscisse du PR le long de la route à laquelle il est associé'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cote IS ''Côté de la route où se situe le PR par rapport au sens des PR croissants '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.34 point_du_reseau
nom_table := 'point_du_reseau';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Point particulier d’un réseau de transport pouvant constituer, un obstacle permanent ou temporaire à la circulation'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature d´un point particulier situé sur un réseau de communication'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Attribut précisant la nature d´un point particulier situé sur un réseau de communication'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.35 poste_de_transformation
nom_table := 'poste_de_transformation';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Enceinte à l’intérieur de laquelle le courant transporté par une ligne électrique est transformé'';
';
RAISE NOTICE '%', req;
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.36 pylone
nom_table := 'pylone';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Support en charpente métallique ou en béton, d’une ligne électrique aérienne'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du pylône'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.37 region
nom_table := 'region';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - La région est à la fois une circonscription administrative déconcentrée de l’Etat qui englobe un ou plusieurs départements, et une collectivité territoriale décentralisée présidé par un conseil régional.'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de la région'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers la préfecture de région (zone d´activité ou d´intérêt)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.38 reservoir
nom_table := 'reservoir';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) then
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Réservoir (eau, matières industrielles,…)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature du réservoir'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du réservoir'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_maximale_sol IS ''Altitude maximale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_maximale_toit IS ''Altitude maximale du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_minimale_sol IS ''Altitude minimale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_minimale_toit IS ''Altitude minimale du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.39 route_numerotee_ou_nommee
nom_table := 'route_numerotee_ou_nommee';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Voie de communication destinée aux automobiles, aux piétons, aux cycles ou aux animaux et possédant un numéro ou un nom particulier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_route IS ''Statut d´une route numérotée ou nommée'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.gestionnaire IS ''Gestionnaire administratif de la route'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero IS ''Numéro de la route'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.40 surface_hydrographique
nom_table := 'surface_hydrographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Zone couverte d’eau douce, d’eau salée ou glacier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature d´un objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l´objet dans le système d´information'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''Méthode utilisée pour déterminer les coordonnées de l´objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_l_altitude IS ''Méthode utilisée pour établir l´altitude de l´objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.persistance IS ''Degré de persistance de l´écoulement de l´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Niveau de l’objet par rapport à la surface du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine IS ''Origine, naturelle ou artificielle, du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.salinite IS ''Permet de préciser si la surface élémentaire est de type eau salée (oui) ou eau douce (non)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_pays IS ''Code du pays auquel appartient la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_plan_d_eau IS '' Identifiant (clé absolue) de l´objet Plan d´eau parent. Une surface hydrographique peut être liée avec 0 à n objets Plan d´eau ''; 
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau IS '' Identifiant (clé absolue) de l´objet Cours d´eau traversant la Surface hydrographique. Une surface hydrographique peut être liée avec 0 à n objets Cours d´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_entite_de_transition IS '' Identifiant (clé absolue) de l´objet Entité de transition à laquelle appartient la Surface hydrographique (estuaires, deltas...). Une surface hydrographique peut être liée avec 0 ou 1 objet Entité de transition'';
 			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_de_plan_d_eau IS ''Toponyme(s) du ou des Plans d´eau constitués par la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_de_cours_d_eau IS ''Toponyme(s) du ou des Cours d´eau traversant la surface hydrographique'';
	 		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_d_entite_de_transition IS ''Toponyme(s) de l´Entité de transition traversant la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.41 terrain_de_sport
nom_table := 'terrain_de_sport';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Équipement sportif de plein air'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature du terrain de sport'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise du terrain de sport'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.42 toponymie_bati
nom_table := 'toponymie_bati';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème bâti'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.43 toponymie_hydrographie
nom_table := 'toponymie_hydrographie';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème hydrographie'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.44 toponymie_lieux_nommes
nom_table := 'toponymie_lieux_nommes';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche des lieux nommés'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.45 toponymie_services_et_activites
nom_table := 'toponymie_services_et_activites';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème services et activités'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.46 toponymie_transport
nom_table := 'toponymie_transport';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème transport'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.47 toponymie_zones_reglementees
nom_table := 'toponymie_zones_reglementees';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Toponymie riche du thème zones réglementées'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table où est situé l´objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l´objet nommé (généralement issu de l´attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour décrire l´objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut être différent de la source de l´objet topographique lui-même)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d´enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.48 transport_par_cable
nom_table := 'transport_par_cable';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Moyen de transport constitué d’un ou de plusieurs câbles porteurs'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de distinguer différents types de transport par câble'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.49 troncon_de_route
nom_table := 'troncon_de_route';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Portion de voie de communication destinée aux automobiles, aux piétons, aux cycles ou aux animaux,  homogène pour l’ensemble des attributs et des relations qui la concernent'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec précis (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de classer un tronçon de route ou de chemin suivant ses caractéristiques physiques'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Position du tronçon par rapport au niveau du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nombre_de_voies IS ''Nombre total de voies de circulation tracées au sol ou effectivement utilisées, sur une route, une rue ou une chaussée de route à chaussées séparées'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.largeur_de_chaussee IS ''Largeur de la chaussée, en mètres'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.itineraire_vert IS ''Indique l’appartenance ou non d’un tronçon routier au réseau vert'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_mise_en_service IS ''Date prévue ou la date effective de mise en service d’un tronçon de route'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.prive IS ''Indique le caractère privé d´un tronçon de route carrossable'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sens_de_circulation IS ''Sens licite de circulation sur les voies pour les véhicules légers'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.bande_cyclable IS ''Sens de circulation sur les bandes cyclables'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.reserve_aux_bus IS ''Sens de circulation sur les voies réservées au bus'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.urbain IS ''Indique que le tronçon de route est situé en zone urbaine'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.vitesse_moyenne_vl IS ''Vitesse moyenne des véhicules légers dans le sens direct'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.acces_vehicule_leger IS ''Conditions de circulation sur le tronçon pour un véhicule léger'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.acces_pieton IS ''Conditions d´accès pour les piétons'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.periode_de_fermeture IS ''Périodes pendant lesquelles le tronçon n´est pas accessible à la circulation automobile'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_la_restriction IS ''Nature précise de la restriction sur un tronçon où la circulation automobile est restreinte'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_hauteur IS ''Exprime l´interdiction de circuler pour les véhicules dépassant la hauteur indiquée'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_poids_total IS ''Exprime l´interdiction de circuler pour les véhicules dépassant le poids indiqué'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_poids_par_essieu IS ''Exprime l´interdiction de circuler pour les véhicules dépassant le poids par essieu indiqué'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_largeur IS ''Exprime l´interdiction de circuler pour les véhicules dépassant la largeur indiquée'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_longueur IS ''Exprime l´interdiction de circuler pour les véhicules dépassant la longueur indiquée'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.matieres_dangereuses_interdites IS ''Exprime l´interdiction de circuler pour les véhicules transportant des matières dangereuses'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiant_voie_1_gauche IS ''Identifiant de la voie pour le côté gauche du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiant_voie_1_droite IS ''Identifiant de la voie pour le côté droit du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_1_gauche IS ''Nom principal de la rue, côté gauche du tronçon : nom de la voie ou nom de lieu-dit le cas échéant'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_1_droite IS ''Nom principal de la rue, côté droit du tronçon : nom de la voie ou nom de lieu-dit le cas échéant'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_2_gauche IS ''Nom secondaire de la rue, côté gauche du tronçon (éventuel nom de lieu-dit)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_2_droite IS ''Nom secondaire de la rue, côté droit du tronçon (éventuel nom de lieu-dit)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.borne_debut_gauche IS ''Numéro de borne à gauche du tronçon en son sommet initial'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.borne_debut_droite IS ''Numéro de borne à droite du tronçon en son sommet initial'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.borne_fin_gauche IS ''Numéro de borne à gauche du tronçon en son sommet final'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.borne_fin_droite IS ''Numéro de borne à droite du tronçon en son sommet final'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.insee_commune_gauche IS ''Code INSEE de la commune située à droite du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.insee_commune_droite IS ''Code INSEE de la commune située à gauche du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_d_adressage_du_troncon IS ''Type d´adressage du tronçon'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.alias_gauche IS ''Ancien nom, nom en langue régionale ou désignation d’une voie communale utilisé pour le côté gauche de la rue'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.alias_droit IS ''Ancien nom, nom en langue régionale ou désignation d’une voie communale utilisé pour le côté droit de la rue'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal_gauche IS ''Code postal du bureau distributeur des adresses situées à gauche du tronçon par rapport à son sens de numérisation'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal_droit IS ''Code postal du bureau distributeur des adresses situées à droite du tronçon par rapport à son sens de numérisation'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_route_nommee IS ''Identifiant(s) (clé absolue) de l´objet Route numérotée ou nommée parent(s)''; 
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_classement_administratif IS ''Classement administratif de la route'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_numero IS ''Numéro d´une route classée'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_gestionnaire IS ''Gestionnaire d´une route classée'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_numero_route_europeenne IS ''Numéro d´une route européenne'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_route_nommee IS ''Toponyme d´une route nommée (n´inclut pas les noms de rue)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_itineraire_cyclable IS ''Nom d´un itinéraire cyclable'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_voie_verte IS ''Nom d´une voie verte'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.50 troncon_de_voie_ferree
nom_table := 'troncon_de_voie_ferree';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Portion de voie ferrée homogène pour l’ensemble des attributs qui la concernent'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou non exploité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de distinguer plusieurs types de voies ferrées selon leur fonction'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.electrifie IS ''Indique si la voie ferrée est électrifiée'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.largeur IS ''Attribut permettant de distinguer les voies ferrées de largeur standard pour la France (1,435 m), des voies ferrées plus larges ou plus étroites'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nombre_de_voies IS ''Attribut indiquant si une ligne de chemin de fer est constituée d´une seule voie ferrée ou de plusieurs'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Niveau de l’objet par rapport à la surface du sol (valeur négative pour un objet souterrain, nulle pour un objet au sol et positive pour un objet en sursol)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.usage IS ''Précise le type de transport auquel la voie ferrée est destinée'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.vitesse_maximale IS ''Vitesse maximale pour laquelle la ligne a été construite'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_voie_ferree_nommee IS ''Le cas échéant, lien vers l´identifiant (clé absolue) de l´objet Voie ferrée nommée décrivant le parcours et le toponyme de l´itinéraire ferré auquel ce tronçon appartient''; 
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme IS ''Nom de la ligne ferroviaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.51 troncon_hydrographique
nom_table := 'troncon_hydrographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='

		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Axe du lit d’une rivière, d’un ruisseau ou d’un canal, homogène pour ses attributs et ses relations et n’inclant pas de confluent en dehors de ses extrémités’'';

	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Précision altimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec  (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature d´un tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l´objet dans le système d´information'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero_d_ordre IS ''Nombre (ou code) exprimant le degré de ramification d´un tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.strategie_de_classement IS ''Stratégie de classement du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.perimetre_d_utilisation_ou_origine IS ''Périmètre d´utilisation ou origine du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sens_de_l_ecoulement IS ''Sens d´écoulement de l´eau dans le tronçon par rapport à la numérisation de sa géométrie'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''Méthode d’obtention des coordonnées d´un tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_l_altitude IS ''Mode d´obtention de l´altitude'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.reseau_principal_coulant IS ''Appartient au réseau principal coulant'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.delimitation IS ''Indique que la délimitation (par exemple, limites et autres informations) d´un objet géographique est connue'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine IS ''Origine, naturelle ou artificielle, du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_largeur IS ''Classe de largeur du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.salinite IS ''Permet de préciser si le tronçon hydrographique est de type eau salée ou eau douce'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_bras IS ''Type de bras'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.persistance IS ''Degré de persistance de l´écoulement de l´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Niveau de l’objet par rapport à la surface du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fosse IS ''Indique qu´il s´agit d´un fossé et non pas d´un cours d´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.navigabilite IS ''Navigabilité du tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_pays IS ''Code du pays auquel appartient le tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l´objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.inventaire_police_de_l_eau IS ''Classé à l´inventaire de la police de l´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiant_police_de_l_eau IS ''Identifiant police de l´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_cours_d_eau_bdcarthage IS ''Code générique du cours d´eau BDCarthage'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau IS ''Identifiant (clé absolue) du cours d´eau principal du bassin versant'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_surface_hydrographique IS ''Identifiant(s) du ou des éventuel(s) objets Surface hydrographique traversé(s) par le tronçon hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_entite_de_transition IS ''Identifiant de l´éventuel objet Entité de transition auquel appartient le tronçon hydrographique''; 
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_de_cours_d_eau IS ''Toponyme du cours d´eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_d_entite_de_transition IS ''Toponyme(s) du ou des Entité de transition traversant la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.52 voie_ferree_nommee
nom_table := 'voie_ferree_nommee';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Itinéraire ferré décrivant une voie ferrée nommée, touristique ou non, un vélo-rail'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.53 zone_d_activite_ou_d_interet
nom_table := 'zone_d_activite_ou_d_interet';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Lieu dédié à une activité particulière ou présentant un intérêt spécifique'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.categorie IS ''Attribut permettant de distinguer plusieurs types d´activité sans rentrer dans le détail de chaque nature'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone d´activité ou d´intérêt'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise de la zone d´activité ou d´intérêt'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.54 zone_d_estran
nom_table := 'zone_d_estran';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Partie du littoral située entre les limites extrêmes des plus hautes et des plus basses marées'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone d´estran'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.55 zone_d_habitation
nom_table := 'zone_d_habitation';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Zone habitée de manière permanente ou temporaire ou ruines'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d´un objet qui peut être en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l´existence de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l´objet dans les répertoires des organismes consultés pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hiérarchiser les objets d´une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilité'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la géométrie de l´objet n´est pas précise (utilisé pour assurer l´exhaustivité d´une classe ou la continuité d´un réseau même lorsque la forme de ses éléments n´est pas connu avec préci (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone d´habitation'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature précise de la zone d´habitation'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.56 zone_de_vegetation
nom_table := 'zone_de_vegetation';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO® - Edition 191 - Espace végétal naturel ou non,différencié en particulier selon le couvert forestier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Précision planimétrique de la géométrie décrivant l´objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la végétation'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l´objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date à laquelle l´objet a été saisi pour la première fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date à laquelle l´objet a été modifié pour la dernière fois dans la base de données'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de création, de construction ou d´apparition de l´objet, ou date la plus ancienne à laquelle on peut attester de sa présence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus récente à laquelle on peut attester de la présence de l´objet sur le terrain'';		
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

RETURN current_time;
END; 
$function$
;
