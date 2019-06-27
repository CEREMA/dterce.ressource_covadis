--CREATE SCHEMA w_adl_delegue;
--> Finish time	Sat May 18 09:55:41 CEST 2019

CREATE OR REPLACE FUNCTION w_adl_delegue.set_comment_bdtopo_30(emprise character varying, millesime character varying, projection integer DEFAULT 2154)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/*
[ADMIN - BDTOPO] - Administration d�un millesime de la BDTOPO 30 une fois son import r�alis�

Taches r�alis�es :
---- D. Mise en place des commentaires 


Tables concern�es :
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

am�lioration � faire :
---- A Create Schema : verification que le sch�ma n'existe pas et le cr��er
---- C.5.1 Ajout de la clef primaire sauf si doublon d?identifiant notamment n_troncon_cours_eau_bdt
erreur : 
ALTER TABLE r_bdtopo_2018.n_toponymie_bati_bdt_000_2018 ADD CONSTRAINT n_toponymie_bati_bdt_000_2018_pkey PRIMARY KEY;
Sur la fonction en cours de travail : D�tail :Key (cleabs_de_l_objet)=(CONSSURF0000002000088919) is duplicated..

derni�re MAJ : 21/06/2019
*/

declare
nom_schema 					character varying;		-- Sch�ma du r�f�rentiel en text
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
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Point mat�rialisant une adresse postale'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='	
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero IS ''Num�ro de l�adresse dans la voie, sans indice de r�p�tition'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero_fictif IS ''Vrai si le num�ro n�est pas un num�ro d�finitif ou significatif'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.indice_de_repetition IS ''Indice de r�p�tition'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.designation_de_l_entree IS ''D�signation de l�entr�e pr�cisant l�adresse dans les habitats collectifs'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_1 IS ''Nom principal de l�adresse : nom de la voie ou nom de lieu-dit le cas �ch�ant'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_2 IS ''Nom secondaire de l�adresse : un �ventuel nom de lieu-dit'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.insee_commune IS ''Num�ro INSEE de la commune de l�adresse'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cote IS ''C�t� du tron�on de route o� est situ�e l�adresse (� droite ou � gauche) en fonction de son sens de num�risation du tron�on dans la base'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_localisation IS ''Localisation de l�adresse'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.methode IS ''M�thode de positionnement de l�adresse'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.alias IS ''D�nomination ancienne de la voie, un nom de la voie en langue r�gionale, une voie communale, ou un nom du lieu-dit relatif � l�adresse en usage local'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_objet_support_1 IS ''Identifiant de l�objet support 1 (Tron�on de route, Zone d�habitation, ...) de l�adresse'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_objet_support_2 IS ''Identifiant de l�objet support 2 (Tron�on de route, Zone d�habitation, ...) de l�adresse'';		
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT.'';
	';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.2 aerodrome
nom_table := 'aerodrome';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Tout terrain ou plan d�eau sp�cialement am�nag� pour l�atterrissage, le d�collage et les manoeuvres des a�ronefs y compris les installations annexes qu�il peut comporter pour les besoins du trafic et le service des a�ronefs'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou non exploit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la g�om�trie de l�objet n�est pas pr�cise (utilis� pour assurer l�exhaustivit� d�une classe ou la continuit� d�un r�seau m�me lorsque la forme de ses �l�ments n�est pas connu avec pr�cision)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de l�a�rodrome (A�rodrome, Altiport, H�liport, Hydrobase)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.categorie IS ''Cat�gorie de l�a�rodrome en fonction de la circulation a�rienne'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.usage IS ''Usage de l�a�rodrome (civil, militaire, priv�)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_icao IS ''Code ICAO (Organisation de l�Aviation Civile Internationale) de l�a�rodrome '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_iata IS ''Code IATA (International Air Transport Association) de l�a�rodrome'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude IS ''Altitude moyenne de l�a�rodrome'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON.'';
	';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.3 arrondissement
nom_table := 'arrondissement';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Circonscription administrative d�concentr�e de l��tat, subdivision du d�partement'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_l_arrondissement IS ''Code INSEE de l�arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_du_departement IS ''Code INSEE du d�partement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_region IS ''Code INSEE de la r�gion'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de l�arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON.'';
	';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.4 arrondissement_municipal
nom_table := 'arrondissement_municipal';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Subdivision territoriale des communes de Lyon, Marseille et Paris'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE de l�arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_commune_de_rattach IS ''Code INSEE de la commune de rattachement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal utilis� pour l�arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de l�arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_chef_lieu IS ''Lien vers la zone d�habitation chef-lieu de l�arrondissement municipal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers la mairie d�arrondissement (zone d�activit� ou d�int�r�t)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON.'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.5 bassin_versant_topographique
nom_table := 'bassin_versant_topographique';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Aire de collecte (impluvium) consid�r�e � partir d�un exutoire ou ensemble d�exutoires, limit�e par le contour � l�int�rieur duquel se rassemblent les eaux pr�cipit�es qui s��coulent en surface vers cette sortie'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l�objet dans le syst�me d�information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique du bassin versant'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''M�thode utilis�e pour d�terminer les coordonn�es de l�objet hydrographique.'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l�objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_bassin_hydrographique IS ''Code du bassin hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.libelle_du_bassin_hydrographique IS ''Libell� du bassin hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine IS ''Origine, naturelle ou artificielle, du tron�on hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.bassin_fluvial IS ''Indique si le bassin versant est un bassin fluvial'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_bdcarthage IS ''Code de la zone BDCarthage'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau_principal IS ''Identifiant (cl� absolue) du cours d�eau principal du bassin versant.'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON.'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.6 batiment
nom_table := 'batiment';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - B�timent'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de distinguer diff�rents types de b�timents selon leur architecture'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine_du_batiment IS ''Attribut indiquant si la g�om�trie du b�timent est issue de l�imagerie a�rienne ou du cadastre'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.usage_1 IS ''Usage principal du b�timent'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.usage_2 IS ''Usage secondaire du b�timent'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.construction_legere IS ''Indique qu�il s�agit d�une structure l�g�re, non attach�e au sol par l�interm�diaire de fondations, ou d�un b�timent ou partie de b�timent ouvert sur au moins un c�t�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du b�timent mesur� entre le sol et la goutti�re (altitude maximum de la polyligne d�crivant le b�timent)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nombre_d_etages IS ''Nombre total d��tages du b�timent'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nombre_de_logements IS ''Nombre de logements dans le b�timent'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.materiaux_des_murs IS ''Code sur 2 caract�res : http://piece-jointe-carto.developpement-durable.gouv.fr/NAT004/DTerNP/html3/annexes/desc_pb40_pevprincipale_dmatgm.html'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.materiaux_de_la_toiture IS ''Code sur 2 caract�res : http://piece-jointe-carto.developpement-durable.gouv.fr/NAT004/DTerNP/html3/annexes/desc_pb40_pevprincipale_dmatto.html'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_maximale_sol IS ''Altitude maximale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_maximale_toit IS ''Altitude maximale du toit, c�est-�-dire au fa�te du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_minimale_sol IS ''Altitude minimale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_minimale_toit IS ''Altitude minimale du toit, c�est-�-dire au bord du toit ou � la goutti�re'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.appariement_fichiers_fonciers IS ''Indicateur relatif � la fiabilit� de l�appariement avec les fichiers fonciers'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.7 canalisation
nom_table := 'canalisation';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Infrastructure d�di�e au transport d�hydrocarbures liquides ou gazeux ou de mati�re premi�re (tapis roulant industriel)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la mati�re transport�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Position de l�infrastructure par rapport au niveau du sol'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.8 cimetiere
nom_table := 'cimetiere';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Endroit o� reposent les morts'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de distinguer les cimeti�res civils des cimeti�res militaires'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise du cimeti�re'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.9 collectivite_territoriale
nom_table := 'collectivite_territoriale';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Collectivit� territoriale correspondant � l��chelon d�partemental et incluant les d�partements ainsi que les collectivit�s territoriales uniques et les collectivit�s territoriales � statut particulier'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE de la collectivit� d�partementale (collectivit� territoriale situ�e entre la commune et la r�gion)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_region IS ''Code INSEE de la r�gion'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de la collectivit� d�partementale'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers le si�ge du conseil de la collectivit� (Zone d�activit� ou d�int�r�t)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.10 commune_associee_ou_deleguee
nom_table := 'commune_associee_ou_deleguee';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Ancienne commune ayant perdu ainsi son statut de collectivit� territoriale en fusionnant avec d�autres communes, mais ayant gard� son territoire et certaines sp�cificit�s comme un maire d�l�gu� ou une mairie annexe'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la commune associ�e ou d�l�gu�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE de la commune associ�e ou d�l�gu�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_commune_de_rattach IS ''Code INSEE de la commune de rattachement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal utilis� pour la commune associ�e ou d�l�gu�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de la commune associ�e ou d�l�gu�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_chef_lieu IS ''Lien vers la zone d�habitation chef-lieu de la commune associ�e ou d�l�gu�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers l�annexe de la mairie ou la mairie annexe de la commune d�l�gu�e (zone d�activit� ou d�int�r�t)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.11 commune
nom_table := 'commune';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Plus petite subdivision du territoire, administr�e par un maire, des adjoints et un conseil municipal'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code insee de la commune sur 5 caract�res'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_l_arrondissement IS ''Code INSEE de l�arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_collectivite_terr IS ''Code INSEE de la collectivit� territoriale incluant cette commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_du_departement IS ''Code INSEE du d�partement sur 2 ou 3 caract�res'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_region IS ''Code INSEE de la r�gion'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal utilis� pour la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.chef_lieu_d_arrondissement IS ''Indique que la commune est chef-lieu d�arrondissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.chef_lieu_de_collectivite_terr IS ''Indique que la commune est chef-lieu d�une collectivit� d�partementale'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.chef_lieu_de_departement IS ''Indique que la commune est chef-lieu d�un d�partement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.chef_lieu_de_region IS ''Indique que la commune est chef-lieu d�une r�gion'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.capitale_d_etat IS ''Indique que la commune est la capitale d�Etat'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_recensement IS ''Date du recensement sur lequel s�appuie le chiffre de population'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.organisme_recenseur IS ''Nom de l�organisme ayant effectu� le recensement de population'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.population IS ''Population sans double compte de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.surface_en_ha IS ''Superficie cadastrale de la commune telle que donn�e par l�INSEE (en ha)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.codes_siren_des_epci IS ''Codes SIREN de l�EPCI ou des EPCI auxquels appartient cette commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_chef_lieu IS ''Lien vers la zone d�habitation chef-lieu de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers la mairie de cette commune (zone d�activit� ou d�int�r�t)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.12 construction_lineaire
nom_table := 'construction_lineaire';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Construction dont la forme g�n�rale est lin�aire'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.13 construction_ponctuelle
nom_table := 'construction_ponctuelle';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Construction de faible emprise'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.14 construction_surfacique
nom_table := 'construction_surfacique';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Ouvrage de grande largeur li� au franchissement d�un obstacle par une voie de communication, ou � l�am�nagement d�une rivi�re ou d�un canal'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.15 cours_d_eau
nom_table := 'cours_d_eau';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Ensemble de tron�ons hydrographiques connexes partageant un m�me toponyme'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l�objet dans le syst�me d�information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique, signifiant, d�fini selon une m�thode d�ordination donn�e '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l�objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.influence_de_la_maree IS ''Indique si l�eau de surface est affect�e par la mar�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.caractere_permanent IS ''Indique si le cours d�eau est permanent'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTILINESTRING'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.16 departement
nom_table := 'departement';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Circonscription administrative d�concentr�e de l��tat, subdivision de la r�gion et incluant un ou plusieurs arrondissements'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE du d�partement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_de_la_region IS ''Code INSEE de la r�gion'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel du d�partement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers la pr�fecture du d�partement (zone d�activit� ou d�int�r�t)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTILINESTRING'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.17 detail_hydrographique
nom_table := 'detail_hydrographique';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - D�tail ou espace dont le nom se rapporte � l�hydrographie'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet du th�me Transport qui peut �tre en projet, en construction, en service ou non exploit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature du d�tail hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise du d�tail hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.18 detail_orographique
nom_table := 'detail_orographique';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - D�tail ou espace dont le nom se rapporte au relief'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature du d�tail orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise du d�tail orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.19 epci
nom_table := 'epci';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Structure administrative regroupant plusieurs communes afin d�exercer certaines comp�tences en commun (�tablissement public de coop�ration intercommunale)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de l�EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_siren IS ''Code SIREN de l�EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom de l�EPCI'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers le si�ge de l�autorit� administrative de l�EPCI (zone d�activit� ou d�int�r�t)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.20 equipement_de_transport
nom_table := 'equipement_de_transport';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Equipement, construction ou am�nagement relatif � un r�seau de transport terrestre, maritime ou a�rien'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou non exploit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la g�om�trie de l�objet n�est pas pr�cise (utilis� pour assurer l�exhaustivit� d�une classe ou la continuit� d�un r�seau m�me lorsque la forme de ses �l�ments n�est pas connu avec (...)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de l��quipement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise de l��quipement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.21 erp
nom_table := 'erp';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Etablissements Recevant du Public'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.id_reference IS ''Identifiant de r�f�rence unique partag� entre les acteurs '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.libelle IS ''D�nomination libre de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.categorie IS ''Cat�gorie dans laquelle est class� l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_principal IS ''Type d��tablissement principal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.types_secondaires IS ''Types d��tablissement secondaires'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.activite_principale IS ''Activit� principale de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.activites_secondaires IS ''Activit�s secondaires de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.public IS ''Etablissement public ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.ouvert IS ''Etablissement effectivement ouvert ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.capacite_d_accueil_du_public IS ''Capacit� totale d�accueil au public'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.capacite_d_hebergement IS ''Capacit� d�h�bergement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero_siret IS ''Num�ro SIRET de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_numero IS ''Num�ro de l�adresse de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_indice_de_repetition IS ''Indice de r�p�tition de l�adresse de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_designation_de_l_entree IS ''Compl�ment d�adressage de l�adresse de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_nom_1 IS ''Nom de voie de l�adresse de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.adresse_nom_2 IS ''El�ment d�adressage compl�mentaire de l�adresse de l��tablissement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.insee_commune IS ''Code INSEE de la commune'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal IS ''Code postal'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine_de_la_geometrie IS ''Origine de la g�om�trie'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_localisation IS ''Type de localisation de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.validation_ign IS ''Validation par l�IGN de l�objet ou non'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_batiment IS ''Lien vers la << Cl� absolue >> du ou des b�timents de la BDTOPO accueillant l�ERP'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_enceinte IS ''Lien vers la << Cl� absolue >> de la Zone d�activit� ou d�int�r�t correspondant � l�ERP dans la BDTOPO''; 
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_adresse IS ''Lien vers l�objet Adresse de la BDTOPO'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.22 foret_publique
nom_table := 'foret_publique';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - For�t publique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs  IS '' Identifiant unique de l�objet dans la BDTopo '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la for�t publique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.23 haie
nom_table := 'haie';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Cl�ture naturelle compos�e d�arbres, d�arbustes, d��pines ou de branchages et servant � limiter ou � prot�ger un champ'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.24 lieu_dit_non_habite
nom_table := 'lieu_dit_non_habite';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Lieu-dit non habit� dont le nom ne se rapporte ni � un d�tail orographique ni � un d�tail hydrographique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de l�espace naturel'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.25 ligne_electrique
nom_table := 'ligne_electrique';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Portion de ligne �lectrique homog�ne pour l�ensemble des attributs qui la concernent'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.voltage IS ''Tension de construction (ligne hors tension) ou d�exploitation maximum (ligne sous tension) de la ligne �lectrique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.26 ligne_orographique
nom_table := 'ligne_orographique';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Ligne de rupture de pente artificielle'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la ligne orographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.27 limite_terre_mer
nom_table := 'limite_terre_mer';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Ligne au niveau de laquelle une masse continentale est en contact avec une masse d�eau, incluant en particulier le trait de c�te, d�fini par la laisse des plus  hautes mers de vives eaux astronomiques'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l�objet dans le syst�me d�information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_limite IS ''Type de limite (Ligne de base, 0 NGF, Limite salure eaux, Limite de comp�tence pr�fet)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine IS ''Origine de la limite terre-mer (exemple : naturel, artificiel)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.niveau IS ''Niveau d�eau d�finissant la limite terre-eau (exemples : hautes-eaux, basses eaux)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_pays IS ''Code du pays auquel appartient la limite'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''Mode d�obtention des coordonn�es planim�triques'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l�objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.28 noeud_hydrographique
nom_table := 'noeud_hydrographique';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Extr�mit� particuli�re d�un tron�on hydrographique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l�objet dans le syst�me d�information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.categorie IS ''Cat�gorie du n�ud hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l�objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_pays IS ''Code du pays auquel appartient le tron�on hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''Mode d�obtention des coordonn�es planim�triques'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_l_altitude IS ''Mode d�obtention de l�altitude'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau_amont IS ''Liens vers (cl� absolue) la classe Cours d�eau d�finissant le ou les cours d�eau amont au niveau dupoint de confluence (Noeud hydrographique de Nature="Confluent").'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau_aval IS ''Liens vers (cl� absolue) la classe Cours d�eau d�finissant le ou les cours d�eau aval au niveau du point de confluence (Noeud hydrographique de Nature="Confluent").'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.29 non_communication
nom_table := 'non_communication';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - N�ud du r�seau routier indiquant l�impossibilit� d�acc�der � un tron�on ou � un encha�nement de plusieurs tron�ons particuliers � partir d�un tron�on de d�part donn�'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_troncon_entree IS ''Identifiant du tron�on � partir duquel on ne peut se rendre vers les tron�ons sortants de ce n�ud'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_troncon_sortie IS ''Identifiant des tron�ons constituant le chemin vers lequel on ne peut se rendre � partir du tron�on entrant de ce n�ud'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.30 parc_ou_reserve
nom_table := 'parc_ou_reserve';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Zone naturelle faisant l�objet d�une r�glementation sp�cifique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la g�om�trie de l�objet n�est pas pr�cise (utilis� pour assurer l�exhaustivit� d�une classe ou la continuit� d�un r�seau m�me lorsque la forme de ses �l�ments n�est pas connu avec pr�cisi (...)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone r�glement�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise de la zone r�glement�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.31 piste_d_aerodrome
nom_table := 'piste_d_aerodrome';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Aire situ�e sur un a�rodrome, am�nag�e afin de servir au roulement des a�ronefs, au d�collage et � l�atterrissage'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou non exploit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut pr�cisant le rev�tement de la piste'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fonction IS ''Fonction associ�e � la piste'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.32 plan_d_eau
nom_table := 'plan_d_eau';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Etendue d�eau d�origine naturelle ou anthropique'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature d�un objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l�objet dans le syst�me d�information'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_moyenne IS ''Altitude � la cote moyenne ou normale du plan d�eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.referentiel_de_l_altitude_moyenne IS ''M�thode d�obtention de l�altitude � la cote moyenne ou normale du plan d�eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_l_altitude_moy IS ''M�thode d�obtention de l�altitude � la cote moyenne ou normale du plan d�eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_de_l_altitude_moyenne IS ''M�thode d�obtention de l�altitude � la cote moyenne ou normale du plan d�eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur_d_eau_maximale IS ''Hauteur d�eau maximale d�un plan d�eau artificiel'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_la_hauteur IS ''M�thode d�obtention de la hauteur maximale du plan d�eau'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique, signifiant, d�fini selon une m�thode d�ordination donn�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l�objet hydrographique'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.influence_de_la_maree IS ''Indique si l�eau de surface est affect�e par la mar�e'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.caractere_permanent IS ''Indique si le plan d�eau est permanent'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.33 point_de_repere
nom_table := 'point_de_repere';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Point de rep�re situ� le long d�une route et utilis� pour assurer le r�f�rencement lin�aire d�objets ou d��v�nements le long de cette route'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee_du_departement IS ''Code INSEE du d�partement'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.route IS ''Num�ro de la route class�e � laquelle le PR est associ�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero IS ''Num�ro du PR propre � la route � laquelle il est associ�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.abscisse IS ''Abscisse du PR le long de la route � laquelle il est associ�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cote IS ''C�t� de la route o� se situe le PR par rapport au sens des PR croissants '';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.34 point_du_reseau
nom_table := 'point_du_reseau';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Point particulier d�un r�seau de transport pouvant constituer, un obstacle permanent ou temporaire � la circulation'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou non exploit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature d�un point particulier situ� sur un r�seau de communication'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Attribut pr�cisant la nature d�un point particulier situ� sur un r�seau de communication'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.35 poste_de_transformation
nom_table := 'poste_de_transformation';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Enceinte � l�int�rieur de laquelle le courant transport� par une ligne �lectrique est transform�'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.36 pylone
nom_table := 'pylone';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Support en charpente m�tallique ou en b�ton, d�une ligne �lectrique a�rienne'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du pyl�ne'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.37 region
nom_table := 'region';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - La r�gion est � la fois une circonscription administrative d�concentr�e de l�Etat qui englobe un ou plusieurs d�partements, et une collectivit� territoriale d�centralis�e pr�sid� par un conseil r�gional.'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_insee IS ''Code INSEE de la r�gion'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_officiel IS ''Nom officiel de la r�gion'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_autorite_administrative IS ''Lien vers la pr�fecture de r�gion (zone d�activit� ou d�int�r�t)'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.38 reservoir
nom_table := 'reservoir';
---- Commentaire Table
req :='
	COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - R�servoir (eau, mati�res industrielles,�)'';
';
RAISE NOTICE '%', req;
EXECUTE(req);
---- Commentaire colonnes
req :='
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature du r�servoir'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du r�servoir'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_maximale_sol IS ''Altitude maximale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_maximale_toit IS ''Altitude maximale du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_minimale_sol IS ''Altitude minimale au pied de la construction'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.altitude_minimale_toit IS ''Altitude minimale du toit'';
	COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- D.39 route_numerotee_ou_nommee
nom_table := 'route_numerotee_ou_nommee';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Voie de communication destin�e aux automobiles, aux pi�tons, aux cycles ou aux animaux et poss�dant un num�ro ou un nom particulier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_route IS ''Statut d�une route num�rot�e ou nomm�e'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.gestionnaire IS ''Gestionnaire administratif de la route'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero IS ''Num�ro de la route'';
		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.40 surface_hydrographique
nom_table := 'surface_hydrographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Zone couverte d�eau douce, d�eau sal�e ou glacier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature d�un objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l�objet dans le syst�me d�information'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''M�thode utilis�e pour d�terminer les coordonn�es de l�objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_l_altitude IS ''M�thode utilis�e pour �tablir l�altitude de l�objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.persistance IS ''Degr� de persistance de l��coulement de l�eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Niveau de l�objet par rapport � la surface du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine IS ''Origine, naturelle ou artificielle, du tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.salinite IS ''Permet de pr�ciser si la surface �l�mentaire est de type eau sal�e (oui) ou eau douce (non)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_pays IS ''Code du pays auquel appartient la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l�objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_plan_d_eau IS '' Identifiant (cl� absolue) de l�objet Plan d�eau parent. Une surface hydrographique peut �tre li�e avec 0 � n objets Plan d�eau ''; 
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau IS '' Identifiant (cl� absolue) de l�objet Cours d�eau traversant la Surface hydrographique. Une surface hydrographique peut �tre li�e avec 0 � n objets Cours d�eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_entite_de_transition IS '' Identifiant (cl� absolue) de l�objet Entit� de transition � laquelle appartient la Surface hydrographique (estuaires, deltas...). Une surface hydrographique peut �tre li�e avec 0 ou 1 objet Entit� de transition'';
 			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_de_plan_d_eau IS ''Toponyme(s) du ou des Plans d�eau constitu�s par la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_de_cours_d_eau IS ''Toponyme(s) du ou des Cours d�eau traversant la surface hydrographique'';
	 		COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_d_entite_de_transition IS ''Toponyme(s) de l�Entit� de transition traversant la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.41 terrain_de_sport
nom_table := 'terrain_de_sport';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - �quipement sportif de plein air'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature du terrain de sport'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise du terrain de sport'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.42 toponymie_bati
nom_table := 'toponymie_bati';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Toponymie riche du th�me b�ti'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table o� est situ� l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l�objet nomm� (g�n�ralement issu de l�attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour d�crire l�objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut �tre diff�rent de la source de l�objet topographique lui-m�me)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d�enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.43 toponymie_hydrographie
nom_table := 'toponymie_hydrographie';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Toponymie riche du th�me hydrographie'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table o� est situ� l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l�objet nomm� (g�n�ralement issu de l�attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour d�crire l�objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut �tre diff�rent de la source de l�objet topographique lui-m�me)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d�enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.44 toponymie_lieux_nommes
nom_table := 'toponymie_lieux_nommes';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Toponymie riche des lieux nomm�s'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table o� est situ� l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l�objet nomm� (g�n�ralement issu de l�attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour d�crire l�objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut �tre diff�rent de la source de l�objet topographique lui-m�me)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d�enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.45 toponymie_services_et_activites
nom_table := 'toponymie_services_et_activites';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Toponymie riche du th�me services et activit�s'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table o� est situ� l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l�objet nomm� (g�n�ralement issu de l�attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour d�crire l�objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut �tre diff�rent de la source de l�objet topographique lui-m�me)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d�enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.46 toponymie_transport
nom_table := 'toponymie_transport';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Toponymie riche du th�me transport'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table o� est situ� l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l�objet nomm� (g�n�ralement issu de l�attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour d�crire l�objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut �tre diff�rent de la source de l�objet topographique lui-m�me)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d�enregistrement ou de validation du toponyme'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.47 toponymie_zones_reglementees
nom_table := 'toponymie_zones_reglementees';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Toponymie riche du th�me zones r�glement�es'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs_de_l_objet IS ''Identifiant de l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_l_objet IS ''Classe ou table o� est situ� l�objet topographique auquel se rapporte ce toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_l_objet IS ''Nature de l�objet nomm� (g�n�ralement issu de l�attribut nature de cet objet)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.graphie_du_toponyme IS ''Une des graphies possibles pour d�crire l�objet topographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.source_du_toponyme IS ''Source de la graphie (peut �tre diff�rent de la source de l�objet topographique lui-m�me)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_du_toponyme IS ''Date d�enregistrement ou de validation du toponyme'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.48 transport_par_cable
nom_table := 'transport_par_cable';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Moyen de transport constitu� d�un ou de plusieurs c�bles porteurs'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou non exploit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de distinguer diff�rents types de transport par c�ble'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en POINT'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.49 troncon_de_route
nom_table := 'troncon_de_route';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Portion de voie de communication destin�e aux automobiles, aux pi�tons, aux cycles ou aux animaux,  homog�ne pour l�ensemble des attributs et des relations qui la concernent'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la g�om�trie de l�objet n�est pas pr�cise (utilis� pour assurer l�exhaustivit� d�une classe ou la continuit� d�un r�seau m�me lorsque la forme de ses �l�ments n�est pas connu avec pr�cis (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de classer un tron�on de route ou de chemin suivant ses caract�ristiques physiques'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Position du tron�on par rapport au niveau du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nombre_de_voies IS ''Nombre total de voies de circulation trac�es au sol ou effectivement utilis�es, sur une route, une rue ou une chauss�e de route � chauss�es s�par�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.largeur_de_chaussee IS ''Largeur de la chauss�e, en m�tres'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.itineraire_vert IS ''Indique l�appartenance ou non d�un tron�on routier au r�seau vert'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_mise_en_service IS ''Date pr�vue ou la date effective de mise en service d�un tron�on de route'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.prive IS ''Indique le caract�re priv� d�un tron�on de route carrossable'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sens_de_circulation IS ''Sens licite de circulation sur les voies pour les v�hicules l�gers'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.bande_cyclable IS ''Sens de circulation sur les bandes cyclables'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.reserve_aux_bus IS ''Sens de circulation sur les voies r�serv�es au bus'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.urbain IS ''Indique que le tron�on de route est situ� en zone urbaine'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.vitesse_moyenne_vl IS ''Vitesse moyenne des v�hicules l�gers dans le sens direct'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.acces_vehicule_leger IS ''Conditions de circulation sur le tron�on pour un v�hicule l�ger'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.acces_pieton IS ''Conditions d�acc�s pour les pi�tons'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.periode_de_fermeture IS ''P�riodes pendant lesquelles le tron�on n�est pas accessible � la circulation automobile'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_de_la_restriction IS ''Nature pr�cise de la restriction sur un tron�on o� la circulation automobile est restreinte'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_hauteur IS ''Exprime l�interdiction de circuler pour les v�hicules d�passant la hauteur indiqu�e'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_poids_total IS ''Exprime l�interdiction de circuler pour les v�hicules d�passant le poids indiqu�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_poids_par_essieu IS ''Exprime l�interdiction de circuler pour les v�hicules d�passant le poids par essieu indiqu�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_largeur IS ''Exprime l�interdiction de circuler pour les v�hicules d�passant la largeur indiqu�e'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.restriction_de_longueur IS ''Exprime l�interdiction de circuler pour les v�hicules d�passant la longueur indiqu�e'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.matieres_dangereuses_interdites IS ''Exprime l�interdiction de circuler pour les v�hicules transportant des mati�res dangereuses'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiant_voie_1_gauche IS ''Identifiant de la voie pour le c�t� gauche du tron�on'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiant_voie_1_droite IS ''Identifiant de la voie pour le c�t� droit du tron�on'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_1_gauche IS ''Nom principal de la rue, c�t� gauche du tron�on : nom de la voie ou nom de lieu-dit le cas �ch�ant'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_1_droite IS ''Nom principal de la rue, c�t� droit du tron�on : nom de la voie ou nom de lieu-dit le cas �ch�ant'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_2_gauche IS ''Nom secondaire de la rue, c�t� gauche du tron�on (�ventuel nom de lieu-dit)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nom_2_droite IS ''Nom secondaire de la rue, c�t� droit du tron�on (�ventuel nom de lieu-dit)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.borne_debut_gauche IS ''Num�ro de borne � gauche du tron�on en son sommet initial'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.borne_debut_droite IS ''Num�ro de borne � droite du tron�on en son sommet initial'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.borne_fin_gauche IS ''Num�ro de borne � gauche du tron�on en son sommet final'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.borne_fin_droite IS ''Num�ro de borne � droite du tron�on en son sommet final'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.insee_commune_gauche IS ''Code INSEE de la commune situ�e � droite du tron�on'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.insee_commune_droite IS ''Code INSEE de la commune situ�e � gauche du tron�on'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_d_adressage_du_troncon IS ''Type d�adressage du tron�on'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.alias_gauche IS ''Ancien nom, nom en langue r�gionale ou d�signation d�une voie communale utilis� pour le c�t� gauche de la rue'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.alias_droit IS ''Ancien nom, nom en langue r�gionale ou d�signation d�une voie communale utilis� pour le c�t� droit de la rue'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal_gauche IS ''Code postal du bureau distributeur des adresses situ�es � gauche du tron�on par rapport � son sens de num�risation'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_postal_droit IS ''Code postal du bureau distributeur des adresses situ�es � droite du tron�on par rapport � son sens de num�risation'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_route_nommee IS ''Identifiant(s) (cl� absolue) de l�objet Route num�rot�e ou nomm�e parent(s)''; 
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_classement_administratif IS ''Classement administratif de la route'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_numero IS ''Num�ro d�une route class�e'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_gestionnaire IS ''Gestionnaire d�une route class�e'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_numero_route_europeenne IS ''Num�ro d�une route europ�enne'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_route_nommee IS ''Toponyme d�une route nomm�e (n�inclut pas les noms de rue)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_itineraire_cyclable IS ''Nom d�un itin�raire cyclable'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_voie_verte IS ''Nom d�une voie verte'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.50 troncon_de_voie_ferree
nom_table := 'troncon_de_voie_ferree';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Portion de voie ferr�e homog�ne pour l�ensemble des attributs qui la concernent'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou non exploit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Attribut permettant de distinguer plusieurs types de voies ferr�es selon leur fonction'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.electrifie IS ''Indique si la voie ferr�e est �lectrifi�e'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.largeur IS ''Attribut permettant de distinguer les voies ferr�es de largeur standard pour la France (1,435 m), des voies ferr�es plus larges ou plus �troites'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nombre_de_voies IS ''Attribut indiquant si une ligne de chemin de fer est constitu�e d�une seule voie ferr�e ou de plusieurs'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Niveau de l�objet par rapport � la surface du sol (valeur n�gative pour un objet souterrain, nulle pour un objet au sol et positive pour un objet en sursol)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.usage IS ''Pr�cise le type de transport auquel la voie ferr�e est destin�e'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.vitesse_maximale IS ''Vitesse maximale pour laquelle la ligne a �t� construite'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_voie_ferree_nommee IS ''Le cas �ch�ant, lien vers l�identifiant (cl� absolue) de l�objet Voie ferr�e nomm�e d�crivant le parcours et le toponyme de l�itin�raire ferr� auquel ce tron�on appartient''; 
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme IS ''Nom de la ligne ferroviaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.50 troncon_hydrographique
nom_table := 'troncon_hydrographique';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='

		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Axe du lit d�une rivi�re, d�un ruisseau ou d�un canal, homog�ne pour ses attributs et ses relations et n�inclant pas de confluent en dehors de ses extr�mit�s�'';

	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction ou en service'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_altimetrique IS ''Pr�cision altim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la g�om�trie de l�objet n�est pas pr�cise (utilis� pour assurer l�exhaustivit� d�une classe ou la continuit� d�un r�seau m�me lorsque la forme de ses �l�ments n�est pas connu avec  (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature d�un tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut IS ''Statut de l�objet dans le syst�me d�information'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.numero_d_ordre IS ''Nombre (ou code) exprimant le degr� de ramification d�un tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.strategie_de_classement IS ''Strat�gie de classement du tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.perimetre_d_utilisation_ou_origine IS ''P�rim�tre d�utilisation ou origine du tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sens_de_l_ecoulement IS ''Sens d��coulement de l�eau dans le tron�on par rapport � la num�risation de sa g�om�trie'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_des_coordonnees IS ''M�thode d�obtention des coordonn�es d�un tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.mode_d_obtention_de_l_altitude IS ''Mode d�obtention de l�altitude'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.reseau_principal_coulant IS ''Appartient au r�seau principal coulant'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.delimitation IS ''Indique que la d�limitation (par exemple, limites et autres informations) d�un objet g�ographique est connue'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.origine IS ''Origine, naturelle ou artificielle, du tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.classe_de_largeur IS ''Classe de largeur du tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.salinite IS ''Permet de pr�ciser si le tron�on hydrographique est de type eau sal�e ou eau douce'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.type_de_bras IS ''Type de bras'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.persistance IS ''Degr� de persistance de l��coulement de l�eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.position_par_rapport_au_sol IS ''Niveau de l�objet par rapport � la surface du sol'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fosse IS ''Indique qu�il s�agit d�un foss� et non pas d�un cours d�eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.navigabilite IS ''Navigabilit� du tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_pays IS ''Code du pays auquel appartient le tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_hydrographique IS ''Code hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.commentaire_sur_l_objet_hydro IS ''Commentaire sur l�objet hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.inventaire_police_de_l_eau IS ''Class� � l�inventaire de la police de l�eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiant_police_de_l_eau IS ''Identifiant police de l�eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.code_du_cours_d_eau_bdcarthage IS ''Code g�n�rique du cours d�eau BDCarthage'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_cours_d_eau IS ''Identifiant (cl� absolue) du cours d�eau principal du bassin versant'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.liens_vers_surface_hydrographique IS ''Identifiant(s) du ou des �ventuel(s) objets Surface hydrographique travers�(s) par le tron�on hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.lien_vers_entite_de_transition IS ''Identifiant de l��ventuel objet Entit� de transition auquel appartient le tron�on hydrographique''; 
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_de_cours_d_eau IS ''Toponyme du cours d�eau'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cpx_toponyme_d_entite_de_transition IS ''Toponyme(s) du ou des Entit� de transition traversant la surface hydrographique'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.51 voie_ferree_nommee
nom_table := 'voie_ferree_nommee';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Itin�raire ferr� d�crivant une voie ferr�e nomm�e, touristique ou non, un v�lo-rail'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en LINESTRING'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.52 zone_d_activite_ou_d_interet
nom_table := 'zone_d_activite_ou_d_interet';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Lieu d�di� � une activit� particuli�re ou pr�sentant un int�r�t sp�cifique'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la g�om�trie de l�objet n�est pas pr�cise (utilis� pour assurer l�exhaustivit� d�une classe ou la continuit� d�un r�seau m�me lorsque la forme de ses �l�ments n�est pas connu (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.categorie IS ''Attribut permettant de distinguer plusieurs types d�activit� sans rentrer dans le d�tail de chaque nature'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone d�activit� ou d�int�r�t'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise de la zone d�activit� ou d�int�r�t'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.53 zone_d_estran
nom_table := 'zone_d_estran';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Partie du littoral situ�e entre les limites extr�mes des plus hautes et des plus basses mar�es'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone d�estran'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.54 zone_d_habitation
nom_table := 'zone_d_habitation';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Zone habit�e de mani�re permanente ou temporaire ou ruines'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.etat_de_l_objet IS ''Etat ou stade d�un objet qui peut �tre en projet, en construction, en service ou en ruines'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.sources IS ''Organismes attestant l�existence de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.identifiants_sources IS ''Identifiants de l�objet dans les r�pertoires des organismes consult�s pour leur inventaire'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.importance IS ''Attribut permettant de hi�rarchiser les objets d�une classe en fonction de leur importance relative'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme de l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.statut_du_toponyme IS ''Information relative au processus de validation de la graphie du toponyme et donnant une indication sur sa fiabilit�'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.fictif IS ''Indique que la g�om�trie de l�objet n�est pas pr�cise (utilis� pour assurer l�exhaustivit� d�une classe ou la continuit� d�un r�seau m�me lorsque la forme de ses �l�ments n�est pas connu avec pr�ci (...)'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone d�habitation'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature_detaillee IS ''Nature pr�cise de la zone d�habitation'';	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

---- D.55 zone_de_vegetation
nom_table := 'zone_de_vegetation';
IF EXISTS (SELECT relname FROM pg_class where relname='n_' || nom_table || '_bdt_' || emprise || '_' || millesime ) THEN
	---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' IS ''IGN BDTOPO� - Edition 191 - Espace v�g�tal naturel ou non,diff�renci� en particulier selon le couvert forestier'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
	---- Commentaire colonnes
	req :='	
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.precision_planimetrique IS ''Pr�cision planim�trique de la g�om�trie d�crivant l�objet'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.nature IS ''Nature de la v�g�tation'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.cleabs IS ''Identifiant unique de l�objet dans la BDTopo'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_creation IS ''Date � laquelle l�objet a �t� saisi pour la premi�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_modification IS ''Date � laquelle l�objet a �t� modifi� pour la derni�re fois dans la base de donn�es'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_d_apparition IS ''Date de cr�ation, de construction ou d�apparition de l�objet, ou date la plus ancienne � laquelle on peut attester de sa pr�sence sur le terrain'';
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.date_de_confirmation IS ''Date la plus r�cente � laquelle on peut attester de la pr�sence de l�objet sur le terrain'';		
			COMMENT ON COLUMN ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || '.geom IS ''Champs g�om�trique en MULTIPOLYGON'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
END IF;

RETURN current_time;
END; 
$function$
;