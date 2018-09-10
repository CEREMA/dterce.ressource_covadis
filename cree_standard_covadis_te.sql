CREATE OR REPLACE FUNCTION cree_standard_covadis_te(
    nom_schema text,
    ddd character,
    enumeree boolean DEFAULT true)
  RETURNS text AS
$BODY$
DECLARE
	req text;
	nom_table char(30);
	liste_table char(30) [] := ARRAY['n_te_franchissement_p', 'n_te_prescription', 'n_te_rel_franpres', 'n_te_rel_tronpres', 'n_te_troncon_l'];
	liste_enumeree char(30) [];
BEGIN
---- Suppression des tables
---- Choix de la liste des tables à supprimer
	CASE enumeree
		WHEN 't' THEN liste_enumeree := ARRAY['te_enum_reseaux', 'te_codes_nature_franchissement', 'te_enum_categories','te_enum_types_franchissement', 'te_enum_types_prescription', 'te_codes_vigilance'];
		ELSE liste_enumeree := ARRAY['table_qui_nexiste_pas'];
	END CASE;

---- Boucle de suppression des tables d'enumération
    FOREACH nom_table IN ARRAY liste_enumeree
    LOOP
	---- Suppression des tables
	req := 'DROP TABLE IF EXISTS '||$1||'.'||nom_table||' CASCADE;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
    END LOOP ;

---- Boucle de suppression des tables
    FOREACH nom_table IN ARRAY liste_table
    LOOP
	---- Suppression des tables
	req := 'DROP TABLE IF EXISTS '||$1||'.'||nom_table||'_'||$2||' CASCADE;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
    END LOOP ;

---- Création des types enumérés :
	CASE enumeree
		WHEN 't' THEN req = '
		CREATE TABLE '||$1||'.te_enum_reseaux (code char(3) PRIMARY KEY, libelle char(24) NOT NULL);
		INSERT INTO '||$1||'.te_enum_reseaux VALUES (''48'',''RESEAU_48T'');
		INSERT INTO '||$1||'.te_enum_reseaux VALUES (''72'',''RESEAU_72T'');
		INSERT INTO '||$1||'.te_enum_reseaux VALUES (''94'',''RESEAU_94T'');
		INSERT INTO '||$1||'.te_enum_reseaux VALUES (''120'',''RESEAU_120T'');

		CREATE TABLE '||$1||'.te_codes_nature_franchissement (code char(12) PRIMARY KEY, libelle char(32) NOT NULL);
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''OA'',''Ouvrage d''''Art'');
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''PN'',''Passage à Niveau'');
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''PORTIQUE'',''Portique'');
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''FEUX'',''Feux de signalisation'');
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''AERIEN'',''Ouvrage aérien'');
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''GIR'',''Giratoire'');
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''RETR'',''Rétrécissement'');
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''AV'',''Aménagement voirie'');
		INSERT INTO '||$1||'.te_codes_nature_franchissement VALUES (''AUTRE'',''Autre'');

		CREATE TABLE '||$1||'.te_enum_categories (code char(4) PRIMARY KEY, libelle char(12) NOT NULL);
		INSERT INTO '||$1||'.te_enum_categories VALUES (''CAT1'',''Catégorie 1'');
		INSERT INTO '||$1||'.te_enum_categories VALUES (''CAT2'',''Catégorie 2'');
		INSERT INTO '||$1||'.te_enum_categories VALUES (''CAT3'',''Catégorie 3'');
		
		CREATE TABLE '||$1||'.te_enum_types_franchissement (code char(1) PRIMARY KEY, libelle char(16) NOT NULL);
		INSERT INTO '||$1||'.te_enum_types_franchissement VALUES (''F'',''Voie franchie'');
		INSERT INTO '||$1||'.te_enum_types_franchissement VALUES (''P'',''Voie portée'');

		CREATE TABLE '||$1||'.te_enum_types_prescription (code char(2) PRIMARY KEY, libelle char(32) NOT NULL);
		INSERT INTO '||$1||'.te_enum_types_prescription VALUES (''PG'',''Prescription Générale'');
		INSERT INTO '||$1||'.te_enum_types_prescription VALUES (''PP'',''Prescription Particulière'');

		CREATE TABLE '||$1||'.te_codes_vigilance (code char(10) PRIMARY KEY, libelle char(48) NOT NULL);
		INSERT INTO '||$1||'.te_codes_vigilance VALUES (''CONSULT'',''Consultation obligatoire'');
		INSERT INTO '||$1||'.te_codes_vigilance VALUES (''ACCOMP'',''Forces de l''''ordre obligatoires'');
		INSERT INTO '||$1||'.te_codes_vigilance VALUES (''GABARIT'',''Gabarit très particulier'');
		INSERT INTO '||$1||'.te_codes_vigilance VALUES (''SCHEMA'',''Schéma(s) de passage'');

		COMMENT ON COLUMN '||$1||'.te_enum_reseaux.code IS ''Entier identifiant de manière unique chaque valeur de la liste énumérée'';
		COMMENT ON COLUMN '||$1||'.te_enum_reseaux.libelle IS ''Libellé associé au code :
RESEAU_48T
RESEAU_72T,
RESEAU_94T,
RESEAU_120T'';

		COMMENT ON COLUMN '||$1||'.te_codes_nature_franchissement.code IS ''Code alphanumérique identifiant de manière unique chaque valeur de la liste énumérée'';
		COMMENT ON COLUMN '||$1||'.te_codes_nature_franchissement.libelle IS ''Libellé associé au code :
Ouvrage d''''Art,
Portique,
Feux de signalisation,
Passage à Niveau,
Ouvrage Aérien,
Aménagement voirie,
Autre
'';

		COMMENT ON COLUMN '||$1||'.te_enum_categories.code IS ''Code alphanumérique identifiant de manière unique chaque valeur de la liste énumérée'';
		COMMENT ON COLUMN '||$1||'.te_enum_categories.libelle IS ''Libellé associé au code :
Catégorie 1
Catégorie 2,
Catégorie 3
'';
		COMMENT ON COLUMN '||$1||'.te_enum_types_franchissement.code IS ''Code alphanumérique identifiant de manière unique chaque valeur de la liste énumérée'';
		COMMENT ON COLUMN '||$1||'.te_enum_types_franchissement.libelle IS ''Libellé associé au code :
Voie franchie,
Voie portée
'';

		COMMENT ON COLUMN '||$1||'.te_enum_types_prescription.code IS ''Code alphanumérique identifiant de manière unique chaque valeur de la liste énumérée'';
		COMMENT ON COLUMN '||$1||'.te_enum_types_prescription.libelle IS ''Libellé associé au code :
Consultation obligatoire
Forces de l''''ordre obligatoires
Gabarit très particulier
Schéma(s) de passage
'';
		';

		ELSE req = 'SELECT version();';
	END CASE;
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;

---- Création des tables
	req := 'CREATE TABLE '||$1||'.n_te_franchissement_p_'||$2||' (id_fran varchar(18) NOT NULL, nom_fran varchar(60), gest_fran varchar(20) NOT NULL, type_fran varchar(1) NOT NULL, num_ligne varchar(10), nom_ligne varchar(50), type_ligne varchar(10), pr_ligne varchar(9), dept varchar(3) NOT NULL, commune varchar(50) NOT NULL, insee varchar(5), source varchar(10), idsource varchar(30), nature varchar(10) NOT NULL, x_l93 varchar(11), y_l93 varchar(12), pr_abs varchar(9), nom_voie varchar(10) NOT NULL, gest_voie varchar(20) NOT NULL, tonnage_to int4 NOT NULL, largeur_m numeric(6,2), longueur_m numeric(6,2), hauteur_m numeric(6,2), vigilance varchar(10), recette_te date, geom geometry(POINT,2154) );';
	EXECUTE(req);
	RAISE NOTICE 'Requete executée : %', req;

	req := 'CREATE TABLE '||$1||'.n_te_prescription_'||$2||' (id_pres varchar(20) NOT NULL, typepres varchar(2) NOT NULL, dept varchar(3) NOT NULL, gestionnai varchar(20) NOT NULL, numero int4 NOT NULL, prescript text NOT NULL, uri varchar(254), nomfich varchar(254), largpres numeric(6,2), hautpres numeric(6,2), debvalid date NOT NULL, finvalid date );';
	EXECUTE(req);
	RAISE NOTICE 'Requete executée : %', req;

	req := 'CREATE TABLE '||$1||'.n_te_rel_franpres_'||$2||' (id_fran varchar(18) NOT NULL, id_pres varchar(20) NOT NULL, recette_te date );';
	EXECUTE(req);
	RAISE NOTICE 'Requete executée : %', req;

	req := 'CREATE TABLE '||$1||'.n_te_rel_tronpres_'||$2||' (id_troncon varchar(18) NOT NULL, id_pres varchar(20) NOT NULL, recette_te date );';
	EXECUTE(req);
	RAISE NOTICE 'Requete executée : %', req;

	req := 'CREATE TABLE '||$1||'.n_te_troncon_l_'||$2||' (id_troncon varchar(18) NOT NULL, reseau_te varchar(3) NOT NULL, cat_te varchar(3) NOT NULL, dept varchar(3) NOT NULL, source varchar(10), id_source varchar(24), numero varchar(10), nom_voie varchar(70), importance varchar(1), cl_admin varchar(20), gestionnai varchar(20) NOT NULL, largeur numeric(6,2) NOT NULL, recette_te date, geom geometry(LINESTRING,2154) );';
	EXECUTE(req);
	RAISE NOTICE 'Requete executée : %', req;

---- Contraintes
---- Clé primaires ARRAY['', 'n_te_prescription', 'n_te_rel_franpres', 'n_te_rel_tronpres', 'n_te_troncon_l']
	req := 'ALTER TABLE '||$1||'.n_te_franchissement_p_'||$2||' ADD CONSTRAINT n_te_franchissement_p_'||$2||'_pk PRIMARY KEY (id_fran) USING INDEX TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;

    	req := 'ALTER TABLE '||$1||'.n_te_troncon_l_'||$2||' ADD CONSTRAINT n_te_troncon_l_'||$2||'_pk PRIMARY KEY (id_troncon) USING INDEX TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;

        req := 'ALTER TABLE '||$1||'.n_te_prescription_'||$2||' ADD CONSTRAINT n_te_prescription_'||$2||'_pk PRIMARY KEY (id_pres) USING INDEX TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	---- Remarque :
	---- pas de pk pour n_te_rel_franpres & n_te_rel_tronpres

---- Contraintes de clés étrangères
	req := 'ALTER TABLE '||$1||'.n_te_franchissement_p_'||$2||' ADD CONSTRAINT n_te_franchissement_p_'||$2||'_fk_n_te_enum_types_franchissement FOREIGN KEY (type_fran) REFERENCES '||$1||'.te_enum_types_franchissement(code);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'ALTER TABLE '||$1||'.n_te_franchissement_p_'||$2||' ADD CONSTRAINT n_te_franchissement_p_'||$2||'_fk_n_te_codes_nature_franchissement FOREIGN KEY (nature) REFERENCES '||$1||'.te_codes_nature_franchissement(code);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'ALTER TABLE '||$1||'.n_te_franchissement_p_'||$2||' ADD CONSTRAINT n_te_franchissement_p_'||$2||'_fk_n_te_codes_vigilance FOREIGN KEY (vigilance) REFERENCES '||$1||'.te_codes_vigilance(code);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'ALTER TABLE '||$1||'.n_te_prescription_'||$2||' ADD CONSTRAINT n_te_prescription_'||$2||'_fk_n_te_enum_types_prescription FOREIGN KEY (typepres) REFERENCES '||$1||'.te_enum_types_prescription(code);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'ALTER TABLE '||$1||'.n_te_rel_franpres_'||$2||' ADD CONSTRAINT n_te_rel_franpres_'||$2||'_fk_n_te_franchissement_p_'||$2||' FOREIGN KEY (id_fran) REFERENCES '||$1||'.n_te_franchissement_p_'||$2||'(id_fran);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'ALTER TABLE '||$1||'.n_te_rel_franpres_'||$2||' ADD CONSTRAINT n_te_rel_franpres_'||$2||'_fk_n_te_prescription_'||$2||' FOREIGN KEY (id_pres) REFERENCES '||$1||'.n_te_prescription_'||$2||'(id_pres);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'ALTER TABLE '||$1||'.n_te_rel_tronpres_'||$2||' ADD CONSTRAINT n_te_rel_tronpres_'||$2||'_fk_n_te_troncon_l_'||$2||' FOREIGN KEY (id_troncon) REFERENCES '||$1||'.n_te_troncon_l_'||$2||'(id_troncon);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'ALTER TABLE '||$1||'.n_te_rel_tronpres_'||$2||'  ADD CONSTRAINT n_te_rel_tronpres_'||$2||'_fk_n_te_prescription_'||$2||'  FOREIGN KEY (id_pres) REFERENCES '||$1||'.n_te_prescription_'||$2||' (id_pres);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'ALTER TABLE '||$1||'.n_te_troncon_l_'||$2||' ADD CONSTRAINT n_te_troncon_l_'||$2||'_fk_n_te_enum_reseaux FOREIGN KEY (reseau_te) REFERENCES '||$1||'.te_enum_reseaux(code);';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;

-- Création des index ordinaires
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_nom_fran		ON '||$1||'.n_te_franchissement_p_'||$2||' (nom_fran) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_gest_fran	ON '||$1||'.n_te_franchissement_p_'||$2||' (gest_fran) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX in_te_franchissement_p_'||$2||'_idx_type_fran	ON '||$1||'.n_te_franchissement_p_'||$2||' (type_fran) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_num_ligne	ON '||$1||'.n_te_franchissement_p_'||$2||' (num_ligne) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_nom_ligne	ON '||$1||'.n_te_franchissement_p_'||$2||' (nom_ligne) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_dept		ON '||$1||'.n_te_franchissement_p_'||$2||' (dept) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_commune		ON '||$1||'.n_te_franchissement_p_'||$2||' (commune) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_insee		ON '||$1||'.n_te_franchissement_p_'||$2||' (insee) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_nom_voie	ON '||$1||'.n_te_franchissement_p_'||$2||' (nom_voie) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_gest_voie	ON '||$1||'.n_te_franchissement_p_'||$2||' (gest_voie) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_idx_vigilance	ON '||$1||'.n_te_franchissement_p_'||$2||' (vigilance) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_prescription_'||$2||'_idx_typepres		ON '||$1||'.n_te_prescription_'||$2||' (typepres) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_prescription_'||$2||'_idx_gestionnai		ON '||$1||'.n_te_prescription_'||$2||' (gestionnai) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_prescription_'||$2||'_idx_numero		ON '||$1||'.n_te_prescription_'||$2||' (numero) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_prescription_'||$2||'_idx_dept		ON '||$1||'.n_te_prescription_'||$2||' (dept) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_prescription_'||$2||'_idx_finvalid		ON '||$1||'.n_te_prescription_'||$2||' (finvalid) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_troncon_l_'||$2||'_idx_reseau_te		ON '||$1||'.n_te_troncon_l_'||$2||' (reseau_te) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_troncon_l_'||$2||'_idx_dept 			ON '||$1||'.n_te_troncon_l_'||$2||' (dept) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_troncon_l_'||$2||'_idx_numero			ON '||$1||'.n_te_troncon_l_'||$2||' (numero) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_troncon_l_'||$2||'_idx_nom_voie		ON '||$1||'.n_te_troncon_l_'||$2||' (nom_voie) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_troncon_l_'||$2||'_idx_gestionnai		ON '||$1||'.n_te_troncon_l_'||$2||' (gestionnai) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
        
-- Création des index spatiaux
	req := 'CREATE INDEX n_te_franchissement_p_'||$2||'_geom_gist			ON '||$1||'.n_te_franchissement_p_'||$2||' USING GIST (geom) TABLESPACE index;';
	EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;
	req := 'CREATE INDEX n_te_troncon_l_'||$2||'_geom_gist				ON '||$1||'.n_te_troncon_l_'||$2||' USING GIST (geom) TABLESPACE index;';
        EXECUTE(req);
        RAISE NOTICE 'Requete executée : %', req;

-- Création des commentaires
-- Tronçons
req := '
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.id_troncon IS ''Identifiant du tronçon
Clé primaire'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.reseau_te IS ''Réseau de transport exceptionnel auquel appartient le tronçon routier
Clé étrangère vers la table <TE_ENUM_RESEAUX>'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.cat_te IS ''Catégorie de transport exceptionnel à laquelle appartient le tronçon routier
Clé étrangère vers la table <TE_ENUM_CATEGORIES>'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.dept IS ''Code INSEE sur 3 caractères du département dans lequel est situé le tronçon'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.source IS ''Référentiel source de l''''objet'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.id_source IS ''Identifiant unique de l''''objet géographique source dans le référentiel source BDTOPO 
Note : non applicable pour des tronçons agrégés'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.numero IS ''Numéro de la voie, hérité de la BD TOPO'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.nom_voie IS ''Nom de la voie, hérité de la BD TOPO'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.importance IS ''Importance de la voie, hérité de la BD TOPO'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.cl_admin IS ''Attribut permettant de préciser le statut de la route, hérité de la BD TOPO'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.gestionnai IS ''Gestionnaire de l''''infrastructure à laquelle appartient le tronçon routier, adapté de la BD TOPO
Clé étrangère (le cas échéant) vers une table des gestionnaires, hors standard TE'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.largeur IS ''Largeur de chaussée (d''''accotement à accotement) exprimée en mètres. Hérité de la BD TOPO'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.recette_te IS ''Date de recette des données géographiques du tronçon routier, exprimée au format JJ/MM/AAAA'';
  COMMENT ON COLUMN '||$1||'.n_te_troncon_l_'||$2||'.geom IS ''Champs Géométrique : lignes  Hérité de la BD TOPO'';
  ';
 EXECUTE(req);

-- Franchissements
req := '
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.id_fran IS ''Identifiant du franchissement
Clé primaire.'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.nom_fran IS ''Nom du franchissement tel que fourni par le gestionnaire'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.gest_fran IS ''Identifiant du gestionnaire du franchissement
Clé étrangère (le cas échéant) vers une table des gestionnaires, hors standard TE'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.type_fran IS ''Type de franchissement (en voie portée ou voie franchie)'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.num_ligne IS ''Numéro de la ligne ferroviaire (le cas échéant)'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.nom_ligne IS ''Nom de la ligne ferroviaire (le cas échéant)'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.type_ligne IS ''Type de ligne ferroviaire (le cas échéant)'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.pr_ligne IS ''Référencement linéaire de l''''ouvrage par rapport aux points de référence PR du référentiel ferroviaire
Note : les PR ne font pas partie des données du présent géostandard'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.dept IS ''Code INSEE sur 3 caractères du département dans lequel est situé l''''ouvrage'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.commune IS ''Nom de la commune, tel que figurant dans le code officiel géographique (COG) à la date de recette des données'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.insee IS ''Numéro INSEE de la commune, tel que figurant dans le code officiel géographique (COG) à la date de recette des données'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.source IS ''Identifiant du fournisseur de la donnée (peut être différent du gestionnaire de l''''ouvrage)'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.idsource IS ''Identifiant dans le SI Source'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.nature IS ''Nature de l''''ouvrage
Clé étrangère vers la table <TE_CODES_NATURE_FRANCHISSEMENT>'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.x_l93 IS ''Coordonnée planimétrique X (Lambert 93) de localisation de l''''ouvrage'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.y_l93 IS ''Coordonnée planimétrique Y (Lambert 93) de localisation de l''''ouvrage'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.pr_abs IS ''Référencement linéaire de l''''ouvrage par rapport aux points de référence PR du référentiel routier
Note : les PR ne font pas partie des données du présent géostandard'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.nom_voie IS ''Nom de la voie concernée par l''''ouvrage'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.gest_voie IS ''Identifiant du gestionnaire de la voie concernée par l''''ouvrage
Clé étrangère (le cas échéant) vers une table des gestionnaires, hors standard TE'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.tonnage_to IS ''Tonnage total (exprimé en tonnes) de masse roulante supporté par l''''ouvrage'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.largeur_m IS ''Gabarit de largeur maximale (exprimée en mètres, avec 2 décimales) des convois pouvant franchir cet ouvrage'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.longueur_m IS ''Gabarit de longueur maximale (exprimée en mètres, avec 2 décimales) des convois pouvant franchir cet ouvrage'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.hauteur_m IS ''Gabarit de hauteur maximale (exprimée en mètres, 2 décimales) des convois pouvant franchir cet ouvrage'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.vigilance IS ''Vigilance liée au franchissement
Clé étrangère vers la table <TE_CODES_VIGILANCE>'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.recette_te IS ''Date de recette des données géographiques du franchissement, exprimée au format JJ/MM/AAAA'';
	COMMENT ON COLUMN '||$1||'.n_te_franchissement_p_'||$2||'.geom IS ''Champs Géométrique : points'';
  ';
 EXECUTE(req);

-- Prescriptions
req := '
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.id_pres IS ''Identifiant signifiant de la prescription
Clé primaire'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.typepres IS ''Type de prescription (générale, particulière)'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.dept IS ''Code INSEE sur 3 caractères du département dans lequel est situé le tronçon'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.gestionnai IS ''Identifiant du gestionnaire de l''''infrastructure
Clé étrangère (le cas échéant) vers une table des gestionnaires, hors standard TE'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.numero IS ''Numéro d''''ordre de la prescription'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.prescript IS ''Texte de la prescription générale'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.uri IS ''Identifiant de ressource sur un réseau Web'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.nomfich IS ''Nom du fichier pdf accessible via le Système d''''Information Géographique'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.largpres IS ''Gabarit de largeur maximale (exprimée en mètres, avec 2 décimales) telle que prescrite par le gestionnaire pour les convois de transports exceptionnels concernés par la prescription'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.hautpres IS ''Gabarit de hauteur maximale (exprimée en mètres, avec 2 décimales) telle que prescrite par le gestionnaire pour les convois de transports exceptionnels concernés par la prescription'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.debvalid IS ''Date de début de validité de la prescription'';
	COMMENT ON COLUMN '||$1||'.n_te_prescription_'||$2||'.finvalid IS ''Date de fin de validité de la prescription'';
  ';
 EXECUTE(req);

-- Table de relation entre les tables N_TE_PRESCRIPTION_GEN, N_TE_PRESCRIPTION_PART d'une part et N_TE_TRONCON_L d'autre part
req := '
	COMMENT ON COLUMN '||$1||'.n_te_rel_tronpres_'||$2||'.id_troncon IS ''Identifiant du tronçon
Clé primaire composée avec ID_PRES.
Clé étrangère vers la table N_TE_TRONCON_L'';
	COMMENT ON COLUMN '||$1||'.n_te_rel_tronpres_'||$2||'.id_pres IS ''Identifiant de la prescription
Clé primaire composée avec ID_TRONCON.
Clé étrangère vers la table N_TE_PRESCRIPTION.'';
	COMMENT ON COLUMN '||$1||'.n_te_rel_tronpres_'||$2||'.recette_te IS ''Date de recette de l''''association de la prescription au tronçon routier, exprimée au format JJ/MM/AAAA'';
  ';
 EXECUTE(req);

-- Table de relation entre les tables N_TE_PRESCRIPTION_GEN, N_TE_PRESCRIPTION_PART d'une part et N_TE_FRANCHISSEMENT_P d'autre part
req := '
	COMMENT ON COLUMN '||$1||'.n_te_rel_franpres_'||$2||'.id_fran IS ''Identifiant du tronçon
Clé primaire composée avec ID_PRES.
Clé étrangère vers la table N_TE_FRANCHISSEMENT_P'';
	COMMENT ON COLUMN '||$1||'.n_te_rel_tronpres_'||$2||'.id_pres IS ''Identifiant de la prescription
Clé primaire composée avec ID_FRAN.
Clé étrangère vers la table N_TE_PRESCRIPTION.'';
	COMMENT ON COLUMN '||$1||'.n_te_rel_tronpres_'||$2||'.recette_te IS ''Date de recette de l''''association de la prescription au franchissement, exprimée au format JJ/MM/AAAA'';
  ';
 EXECUTE(req);

Return current_time;
END ;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
