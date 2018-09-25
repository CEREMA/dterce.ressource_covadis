CREATE OR REPLACE FUNCTION w_adl_delegue.set_adm_bdtopo_22(
    nom_schema character varying,
    emprise character varying,
    millesime character varying)
  RETURNS void AS
$BODY$
/*
[ADMIN - BDTOPO] - Administration d'un millesime de la BDTOPO 2.2 une fois son import réalisé et les couches mises à la COVADIS

Taches réalisées :
- Suppression des colonnes gid (import via shp2pgsql)
- Ajout d'une clé primaire sur le champs [id]
- Ajout des contraintes
- Commentaires des tables
- Commentaires des colonnes
- Index Géométriques & attributaire

Tables concernées :
n_canalisation_bdt_ddd_aaaa
n_chemin_bdt_ddd_aaaa
n_conduite_bdt_ddd_aaaa
n_contruction_lineaire_bdt_ddd_aaaa
n_ligne_electrique_bdt_ddd_aaaa
n_ligne_orographique_bdt_ddd_aaaa
n_route_bdt_ddd_aaaa
n_route_nommee_bdt_ddd_aaaa
n_route_primaire_bdt_ddd_aaaa
n_route_secondaire_bdt_ddd_aaaa
n_transport_cable_bdt_ddd_aaaa
n_troncon_cours_eau_bdt_ddd_aaaa
n_troncon_voie_ferree_bdt_ddd_aaaa
n_aire_triage_bdt_ddd_aaaa
n_bati_indifferencie_bdt_ddd_aaaa
n_bati_industriel_bdt_ddd_aaaa
n_bati_remarquable_bdt_ddd_aaaa
n_cimetiere_bdt_ddd_aaaa
n_commune_bdt_ddd_aaaa
n_construction_legere_bdt_ddd_aaaa
n_construction_surfacique_bdt_ddd_aaaa
n_gare_bdt_ddd_aaaa
n_piste_aerodrome_bdt_ddd_aaaa
n_poste_transformation_bdt_ddd_aaaa
n_reservoir_bdt_ddd_aaaa
n_reservoir_eau_bdt_ddd_aaaa
n_surface_activite_bdt_ddd_aaaa
n_surface_eau_bdt_ddd_aaaa
n_surface_route_bdt_ddd_aaaa
n_terrain_sport_bdt_ddd_aaaa
n_zone_vegetation_bdt_ddd_aaaa
n_administratif_militaire_bdt_ddd_aaaa
n_chef_lieu_bdt_ddd_aaaa
n_construction_ponctuelle_bdt_ddd_aaaa
n_hydronyme_bdt_ddd_aaaa
n_lieu_dit_habite_bdt_ddd_aaaa
n_lieu_dit_non_habite_ddd_aaaa
n_oronyme_bdt_ddd_aaaa
n_pai_culture_loisirs_bdt_ddd_aaaa
n_pai_espace_naturel_bdt_ddd_aaaa
n_pai_gestion_eaux_bdt_ddd_aaaa
n_pai_hydrographie_bdt_ddd_aaaa
n_pai_industriel_commercial_bdt_ddd_aaaa
n_pai_orographie_bdt_ddd_aaaa
n_pai_religieux_bdt_ddd_aaaa
n_pai_sante_bdt_ddd_aaaa
n_pai_science_enseignement_bdt_ddd_aaaa
n_pai_sport_bdt_ddd_aaaa
n_pai_transport_bdt_ddd_aaaa
n_pai_zone_habitation_bdt_ddd_aaaa
n_point_eau_bdt_ddd_aaaa
n_pylone_bdt_ddd_aaaa
n_toponyme_communication_bdt_ddd_aaaa
n_toponyme_divers_bdt_ddd_aaaa
n_toponyme_ferre_bdt_ddd_aaaa


amélioration à faire :
---- B.3 Ajout de la clef primaire sauf si doublon d'identifiant
---- ajout d'un test de presence du champs gid

dernière MAJ : 25/09/2018
*/

DECLARE
object 						text;
r 						record;
req 						text;
veriftable 					character varying;
tb_table character varying[]; 			-- Tables faites d'objets ponctuels
nb_table integer;				-- Nombre de tables
nom_table character varying;			-- nom de la table en text
i_table int2; 					-- Nombre de table dans la boucle Tables
tb_index character varying[]; 			-- Index à créer
nb_index integer;				-- Nombre d'index à créér
nom_index character varying;			-- nom du champs àindexer en text
i_index int2; 					-- Nombre d'index dans la boucle des index
BEGIN


---- A - Renomage des tables :
FOR object IN
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename NOT LIKE 'n_%'-- and other conditions, if needed
	LOOP
		req :='
		ALTER TABLE '||nom_schema||'.' || object || ' RENAME TO n_' || object || '_bdt_'  || emprise || '_'  || millesime  || ';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- B. Optimisation de la base
---- B.1 Suppression du champs gid créée et de la séquence correspondante
FOR object IN
	SELECT tablename::text from pg_tables where (schemaname LIKE nom_schema) AND right(tablename,12) = 'bdt_' || emprise || '_' || millesime
	LOOP 
		req := '
		ALTER TABLE ' || nom_schema || '.' || object || ' DROP COLUMN IF EXISTS gid;
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- B.2 Ajout des contraintes :
---- Contraintes sur le type de géométrie et index spatiaux
---- 2D
FOR r IN SELECT tablename, schemaname from pg_tables where schemaname LIKE nom_schema  AND right(tablename,12) = 'bdt_' || emprise || '_' || millesime
LOOP 
	req := '
		ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_dims_geom CHECK (ST_NDims(geom)=2);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 

---- Lambert93 (2154)
FOR r IN SELECT tablename, schemaname from pg_tables where schemaname LIKE nom_schema AND right(tablename,12) = 'bdt_' || emprise || '_' || millesime
LOOP 
	req := '
		ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)=2154);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 

---- 'POINT' : Tables BDTOPO faites d'objets ponctuels
tb_table := array[
		'administratif_militaire',
		'chef_lieu',
		'construction_ponctuelle',
		'hydronyme',
		'lieu_dit_habite',
		'lieu_dit_non_habite',
		'oronyme',
		'pai_culture_loisirs',
		'pai_espace_naturel',
		'pai_gestion_eaux',
		'pai_hydrographie',
		'pai_industriel_commercial',
		'pai_orographie',
		'pai_religieux',
		'pai_sante',
		'pai_science_enseignement',
		'pai_sport',
		'pai_transport',
		'pai_zone_habitation',
		'point_eau',
		'pylone',
		'toponyme_communication',
		'toponyme_divers',
		'toponyme_ferre'
		];

nb_table := array_length(tb_table, 1);

FOR i_table IN 1..nb_table LOOP
	nom_table:=tb_table[i_table];
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = nom_table INTO veriftable;
	IF LEFT(veriftable,length (nom_table)) = nom_table
	THEN
	req := '
		ALTER TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POINT''::text OR geom IS NULL);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 

---- 'MULTILINESTRING' : Tables BDTOPO faites d'objets linéaires
tb_table := array[
		'canalisation',
		'chemin',
		'conduite',
		'contruction_lineaire',
		'ligne_electrique',
		'ligne_orographique',
		'route',
		'route_nommee',
		'route_primaire',
		'route_secondaire',
		'transport_cable',
		'troncon_cours_eau',
		'troncon_voie_ferree'
		];

nb_table := array_length(tb_table, 1);

FOR i_table IN 1..nb_table LOOP
	nom_table:=tb_table[i_table];
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = nom_table INTO veriftable;
	IF LEFT(veriftable,length (nom_table)) = nom_table
	THEN
	req := '
		ALTER TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTILINESTRING''::text OR geom IS NULL);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 

---- ''MULTIPOLYGON'': Tables BDTOPO faites d'objets polygones
tb_table := array[
		'aire_triage',
		'bati_indifferencie',
		'bati_industriel',
		'bati_remarquable',
		'cimetiere',
		'commune',
		'construction_legere',
		'construction_surfacique',
		'gare',
		'piste_aerodrome',
		'poste_transformation',
		'reservoir',
		'reservoir_eau',
		'surface_activite',
		'surface_eau',
		'surface_route',
		'terrain_sport',
		'zone_vegetation'
		];

nb_table := array_length(tb_table, 1);

FOR i_table IN 1..nb_table LOOP
	nom_table:=tb_table[i_table];
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = nom_table INTO veriftable;
	IF LEFT(veriftable,length (nom_table)) = nom_table
	THEN
	req := '
		ALTER TABLE ' || nom_schema || '.n_' || nom_table || '_bdt_' || emprise || '_' || millesime || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text OR geom IS NULL);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.' || nom_table || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;
END LOOP; 


---- B.3 Ajout de la clef primaire
FOR object IN SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND right(tablename,12) = 'bdt_' || emprise || '_' || millesime AND right(tablename,32) != 'n_troncon_cours_eau_bdt_' || emprise || '_' || millesime
LOOP
	--nom_table := nom_schema || '.' || object;
	--SELECT count(id) FROM tablename GROUP BY id HAVING count(id) > 1 LIMIT 1 INTO veriftable;
	--IF veriftable > 1
	--	THEN
			req := '
				ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT ' || object || '_pkey PRIMARY KEY (id);
			';
			EXECUTE(req);
			RAISE NOTICE '%', req;
	--	ELSE
	--		req :='La table ' || schemaname || object || ' n’a pas un champs identifiant unique !';
	--		RAISE NOTICE '%', req;
	--	END IF;
END LOOP; 

---- B.4 Ajout des index spatiaux
    FOR object IN SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND right(tablename,12) = 'bdt_' || emprise || '_' || millesime
    LOOP
        req := '
	DROP INDEX IF EXISTS ' || nom_schema || '.' || object || '_geom_gist;
	CREATE INDEX ' || object || '_geom_gist ON ' || nom_schema || '.' || object || ' USING gist (geom) TABLESPACE index;
        ALTER TABLE ' || nom_schema || '.' || object || ' CLUSTER ON ' || object || '_geom_gist;
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
    END LOOP;

----------------------------
---- B.5 Travail à la Table
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de voie de communication de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Voie de communication destinée aux automobiles, aux piétons, aux cycles ou aux animaux, homogène pour l’ensemble des attributs et des relations qui la concerne.
Le tronçon de route peut être revêtu ou non revêtu (pas de revêtement de surface ou revêtement de surface fortement dégradé).
Dans le cas d’un tronçon de route revêtu, on représente uniquement la chaussée, délimitée par les bas-côtés ou les trottoirs (cf. Modélisation géométrique).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.ALIAS_D IS ''Dénomination ancienne ou autre nom voie droite.  Une voie est un ensemble de tronçons de route associés à un même nom. Une voie est  identifiée par son nom dans une commune donnée.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.ALIAS_G IS ''Dénomination ancienne ou autre nom voie gauche.  Une voie est un ensemble de tronçons de route associés à un même nom. Une voie est  identifiée par son nom dans une commune donnée.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.BORNEDEB_D IS ''Borne début droite.  Numéro de borne à droite du tronçon en son sommet initial.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.BORNEDEB_G IS ''Borne fin gauche.  Numéro de borne à gauche du tronçon en son sommet final.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.BORNEFIN_D IS ''Borne droite de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.BORNEFIN_G IS ''Borne fin droite.  Numéro de borne à droite du tronçon en son sommet final.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CL_ADMIN IS ''Attribut permettant de préciser le statut d''''une route'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CODEPOST_D IS ''Code postal du côté droit de la voie  Code postal de la commune à droite du tronçon par rapport à son sens de numérisation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CODEPOST_G IS ''Code postal du côté gauche de la voie  Code postal de la commune à gauche du tronçon par rapport à son sens de  numérisation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CODEVOIE_D IS ''Identifiant du coté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.CODEVOIE_G IS ''Identifiant droite.  Identifiant de la voie associée au côté droit du tronçon.  Identifiant de la voie associée au côté gauche du tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.ETAT IS ''Indique si le tronçon est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.FICTIF IS ''Indique la nature fictive ou réelle du tronçon - V'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.FRANCHISST IS ''Franchissement.  Cet attribut informe sur le niveau de l''''objet par rapport à la surface du sol.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.GESTION IS ''Définit le gestionnaire administratif d''''une route. Toutes les routes classées possèdent un  Gestionnaire.  Il existe différentes catégories de routes pour lesquelles le gestionnaire diffère.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.ID IS ''Cet identifiant est unique. Il est stable d''''une édition à l''''autre. Il permet aussi d''''établir un  lien entre le ponctuel de la classe « ADRESSE » des produits BD ADRESSE® et POINT  ADRESSE®'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.IMPORTANCE IS ''Cet attribut matérialise une hiérarchisation du réseau routier fondée, non  pas sur un critère administratif, mais sur l''''importance des tronçons de route pour le trafic  routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.INSEECOM_D IS ''INSEE Commune droite.  Numéro d''''INSEE de la commune à droite du tronçon par rapport à son sens de  numérisation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.INSEECOM_G IS ''Numéro INSEE de la commune à droite de la voie  Numéro d''''INSEE de la commune à gauche du tronçon par rapport à son sens de  numérisation.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.IT_EUROP IS ''Itinéraire européen.  Numéro de route européenne : une route européenne emprunte en général le réseau  autoroutier ou national.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.IT_VERT IS ''Itinéraire vert.  Indique l''''appartenance ou non d''''un tronçon routier au réseau vert.  Le réseau vert, composé de pôles verts et de liaisons vertes, couvre l''''ensemble du  territoire français.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.LARGEUR IS ''Largeur de chaussée.  Largeur de chaussée (d''''accotement à accotement) exprimée en mètres.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.MISE_SERV IS ''Date de mise en service.  Définit la date prévue ou la date effective de mise en service d''''un tronçon de route.  Cet attribut n''''est rempli que pour les tronçons en construction, il est à “NR“ dans les autres cas.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NATURE IS ''Attribut permettant de distinguer différentes natures de tronçon de route.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NB_VOIES IS ''Nombre de voies.  Nombre total de voies d''''une route, d''''une rue ou d''''une chaussée de route à chaussées séparées.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NOM_ITI IS ''Nom de l''''itinéraire ou "Valeur non renseignée"'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NOM_VOIE_D IS ''Une voie est un ensemble de tronçons de route associés à un même nom. Une voie est  identifiée par son nom dans une commune donnée.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NOM_VOIE_G IS ''Nom voie à gauche. Le nom de voie est celui qui sert à l''''adressage.  Une voie est un ensemble de tronçons de route associés à un même nom. Une voie est  identifiée par son nom dans une commune donnée.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.NUMERO IS ''Numéro de la voie (D50,N106…) (NR pour Non renseigné'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.POS_SOL IS ''Position par rapport au sol.  Donne le niveau de l''''objet par rapport à la surface du sol (valeur négative pour un objet  souterrain, nulle pour un objet au sol et positive pour un objet en sursol).'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.PREC_ALTI IS ''Précision géométrique altimétrique.  Attribut précisant la précision géométrique en altimétrie de la donnée.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.PREC_PLANI IS ''Précision géométrique planimétrique.  Attribut précisant la précision géométrique en planimétrie de la donnée.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.SENS IS ''Sens de circulation autorisée pour les automobiles sur les voies.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.TYP_ADRES IS ''Type d''''adressage.  Renseigne sur le type d''''adressage du tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.Z_FIN IS ''Altitude finale : c''''est l''''altitude du sommet final du tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.Z_INI IS ''c''''est l''''altitude du sommet initial du tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Voie de communication terrestre non ferrée destinée aux piétons, aux cycles ou aux animaux, de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Voie de communication terrestre non ferrée destinée aux piétons, aux cycles ou aux animaux, ou route sommairement revêtue (pas de revêtement de surface ou revêtement de surface fortement dégradé).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_iti IS ''Nom d’itinéraire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS '' Portion de voie de communication destinée aux automobiles, aux piétons, qui possèdent réellement un nom de rue de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
1.  Portion de voie de communication destinée aux automobiles, aux piétons, aux cycles ou aux animaux, homogène pour l’ensemble des attributs et des relations qui la concerne, et qui possèdent réellement un nom de rue droit ou un nom de rue gauche (d’où le nom de la classe ROUTE_NOMMEE). 
2.  Le  tronçon  de  route  peut  être  revêtu  ou  non  revêtu  (pas  de  revêtement  de surface ou revêtement de surface fortement dégradé). Dans le cas d’un tronçon de route revêtu, on représente uniquement la chaussée, délimitée par les bas-côtés ou les trottoirs (cf. Modélisation géométrique). '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.numero IS ''Numéro de la voie (D50, N106…)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_g IS ''Nom du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_d IS ''Nom du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.cl_admin IS ''Classement administratif'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.gestion IS ''Gestionnaire de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.mise_serv IS ''Date de mise en service'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_vert IS ''Appartenance à un itinéraire vert'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_europ IS ''Numéro de l’itinéraire européen'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.fictif IS ''Indique la nature fictive ou réel du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.largeur IS ''Largeur de la chaussée'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_iti IS ''Nom d’itinéraire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.sens IS ''Sens de circulation de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_g IS ''Numéro Insee de la commune à gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_d IS ''Numéro Insee de la commune à droite de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_g IS ''Identifiant du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_d IS ''Identifiant du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.typ_adres IS ''Type d’adressage de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_g IS ''Borne gauche de début de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_d IS ''Borne droite de début de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_g IS ''Borne gauche de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_d IS ''Borne droite de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.etat IS ''Indique si le tronçon est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_g IS ''Ancien ou autre nom utilisé côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_d IS ''Ancien ou autre nom utilisé côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_g IS ''Code postal du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_d IS ''Code postal du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de voie de communication primaire destinée aux automobiles, aux piétons ou aux cycles, la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Portion de voie de communication destinée aux automobiles, aux piétons ou aux cycles, homogène pour l’ensemble des attributs et des relations qui la concerne. 
Cette  classe  est  un  sous-ensemble  de  la  classe  ROUTE,  et  comprend uniquement les tronçons de route d’importance 1 ou 2. 
Cela  permet  de  n’utiliser  ou  de  n’afficher  que  le  réseau  dit  principal, pour des raisons de faciliter de manipulation ou de lisibilité à l’écran suivant l’échelle.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.numero IS ''Numéro de la voie (D50, N106…)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_g IS ''Nom du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_d IS ''Nom du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.cl_admin IS ''Classement administratif'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.gestion IS ''Gestionnaire de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.mise_serv IS ''Date de mise en service'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_vert IS ''Appartenance à un itinéraire vert'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_europ IS ''Numéro de l’itinéraire européen'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.fictif IS ''Indique la nature fictive ou réel du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.largeur IS ''Largeur de la chaussée'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_iti IS ''Nom d’itinéraire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.sens IS ''Sens de circulation de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_g IS ''Numéro Insee de la commune à gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_d IS ''Numéro Insee de la commune à droite de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_g IS ''Identifiant du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_d IS ''Identifiant du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.typ_adres IS ''Type d’adressage de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_g IS ''Borne gauche de début de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_d IS ''Borne droite de début de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_g IS ''Borne gauche de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_d IS ''Borne droite de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.etat IS ''Indique si le tronçon est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_g IS ''Ancien ou autre nom utilisé côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_d IS ''Ancien ou autre nom utilisé côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_g IS ''Code postal du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_d IS ''Code postal du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de voie de communication primaire destinée aux automobiles, aux piétons ou aux cycles, la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Portion de voie de communication destinée aux automobiles, aux piétons ou aux cycles, homogène pour l’ensemble des attributs et des relations qui la concerne. 
Cette  classe  est  un  sous-ensemble  de  la  classe  ROUTE,  et  comprend uniquement les tronçons de route d’importance 1 ou 2. 
Cela  permet  de  n’utiliser  ou  de  n’afficher  que  le  réseau  dit  principal, pour des raisons de faciliter de manipulation ou de lisibilité à l’écran suivant l’échelle.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.numero IS ''Numéro de la voie (D50, N106…)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_g IS ''Nom du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_voie_d IS ''Nom du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.cl_admin IS ''Classement administratif'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.gestion IS ''Gestionnaire de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.mise_serv IS ''Date de mise en service'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_vert IS ''Appartenance à un itinéraire vert'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.it_europ IS ''Numéro de l’itinéraire européen'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.fictif IS ''Indique la nature fictive ou réel du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.largeur IS ''Largeur de la chaussée'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom_iti IS ''Nom d’itinéraire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.sens IS ''Sens de circulation de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_g IS ''Numéro Insee de la commune à gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.inseecom_d IS ''Numéro Insee de la commune à droite de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_g IS ''Identifiant du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codevoie_d IS ''Identifiant du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.typ_adres IS ''Type d’adressage de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_g IS ''Borne gauche de début de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornedeb_d IS ''Borne droite de début de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_g IS ''Borne gauche de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.bornefin_d IS ''Borne droite de fin de voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.etat IS ''Indique si le tronçon est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_g IS ''Ancien ou autre nom utilisé côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.alias_d IS ''Ancien ou autre nom utilisé côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_g IS ''Code postal du côté gauche de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.codepost_d IS ''Code postal du côté droit de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Partie de la chaussée d’une route caractérisée par une largeur exceptionnelle de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Zone à trafic non structuré.
Sélection : Toutes les zones revêtues pour le roulage ou le parcage des automobiles, et faisant plus  de  50 m  de  large  sont  incluses  (environ  ½  ha  pour  les  parkings).  Les  zones  revêtues  de moins de 50 m de large sont exclues (pour les zones de moins de 50 m de large réservées à la circulation automobile, voir classe ROUTE). 
Modélisation géométrique : Contours de la chaussée, au sol. La surface peut être trouée.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la surface_route.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_moyen IS ''Altitude moyenne des points composants la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.n_toponyme_communication_bdt_' || emprise || '_' || millesime || ' IS ''Objet nommé du thème routier de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Tous les noms liés à un réseau routier.
Modélisation géométrique : Centre du lieu nommé. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la surface_route.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Aire de triage, faisceau de voies de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Surface qui englobe l’ensemble des tronçons de voies, voies de garage, aiguillages permettant le tri des wagons et la composition des trains.
Sélection  :  Les  faisceaux  de  voies  de  moins  de  25  m  de  large  sont  exclus  (voir  la  classe TRONÇON_VOIE_FERREE). 
Modélisation  géométrique  :  Contour  du  faisceau,  en  s’appuyant  sur  les  voies  les  plus 
extérieures, au sol. À l’intérieur d’un faisceau de voies, un espace sans voie de plus de 25 m de 
large est modélisé par un trou dans la surface.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de l’aire de triage.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS '' Gares ferroviaires de voyageurs de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Bâtiment  servant  à  l’accueil,  à  l’embarquement  et  au  débarquement  des voyageurs en train. 
Remarque :  Ces  bâtiments  sont  également  présents  dans  la  classe  des bâtiments fonctionnels BATI_REMARQUABLE (catégorie transport, nature gare).
Modélisation géométrique : Voir chapitre sur la modélisation des bâtiments en général § 8.1.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de l’aire de triage.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Objet nommé du thème ferré de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Tous les noms liés au réseau ferré et dont le nom figure sur la carte au 1 : 25 000 en service. 
Modélisation géométrique : Centre du lieu nommé. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du toponyme.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Moyen de transport constitué d’un ou de plusieurs câbles porteurs de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Tous les noms liés au réseau ferré et dont le nom figure sur la carte au 1 : 25 000 en service. 
Modélisation géométrique : Centre du lieu nommé. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Type de voies ferrées selon leur fonction et leur état'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale de l’objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale de l’objet'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de voie ferrée homogène de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Portion de voie ferrée homogène pour l’ensemble des attributs qui la concernent. 
Dans le cas d’une ligne composée de deux à quatre voies parallèles, l’ensemble des voies est modélisé par un seul objet.
Sélection : Voir les différentes valeurs de l’attribut NATURE. 
 
Modélisation géométrique : A l’axe de la ou de l’ensemble des voies de la ligne, au sol. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Type de voies ferrées selon leur fonction et leur état'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.electrifie IS ''Énergie servant à la propulsion des locomotives'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.largeur IS ''Largeur de la voie'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.etat IS ''Indique si le tronçon est en construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Conduite utilisé pour le transport de matière première de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Conduite (autre que canalisation d’eau) ou tapis roulant utilisés pour le transport de matière première (gaz, hydrocarbure, minerai, etc.) ou canalisation de nature inconnue.
Sélection : Conduites aériennes issues de restitution, et conduites souterraines qui figurent sur la carte au 1 : 25 000. 
 
Modélisation géométrique : À l’axe.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Conduite utilisé pour le transport de matière première de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Conduite (autre que canalisation d’eau) ou tapis roulant utilisés pour le transport de matière première (gaz, hydrocarbure, minerai, etc.) ou canalisation de nature inconnue.
Sélection : Conduites aériennes issues de restitution, et conduites souterraines qui figurent sur la carte au 1 : 25 000. 
 
Modélisation géométrique : À l’axe.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon de la ligne électrique.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.voltage IS ''Tension de la ligne électrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Poste de transformation électrique de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Enceinte à l’intérieur de laquelle le courant transporté par une ligne électrique est transformé.
Sélection  :  Tous  les  postes  de  transformation  situés  sur  le  réseau  de  lignes  à  haute  ou  très haute tension. 
 
Modélisation  géométrique  :  Contour  du  poste,  au  sol  lorsque  le  poste  est  délimité  par  un grillage, ou en haut des bâtiments lorsque ceux-ci constituent la limite du poste.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du poste de transformation .
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Support de ligne électrique. Pylône, portique de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Les pylônes et portiques soutenant des lignes de 63 KV et plus. 
 
Modélisation géométrique : À l’axe et en haut du pylône. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du poste de transformation .
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Canalisation d’eau de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Uniquement  les  canalisations  aériennes  et  celles  qui  figurent  sur  la  carte  au 1 : 25 000 en service. 
 
Modélisation géométrique : À l’axe et sur le dessus de la canalisation.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la canalisation.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Nom se rapportant à un détail hydrographique de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Tous les détails hydrographiques dont le nom figure sur la carte au 1 : 25 000. 
 
Modélisation géométrique : Centre du détail nommé.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du toponyme.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Source, point de production d’eau ou point de stockage d’eau de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Source (captée ou non), point de production d’eau (pompage, forage, puits,…) ou point de stockage d’eau de petite dimension (citerne, abreuvoir, lavoir, bassin).
Sélection  :  Tous  les  points  d’eau  mentionnés  sur  la  carte  au  1 : 25 000,  sauf  ceux  dont  la disparition  est  attestée  par  l’examen  des  photographies  aériennes  ou  d’autres  sources d’information. 
Les abreuvoirs, les puits et les lavoirs sont généralement exclus. 
 
Modélisation géométrique : Au centre. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du toponyme.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du point d’eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.D_HYDROGRAPHIE 
---- B.5.D.4 RESERVOIR_EAU
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_reservoir_eau_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_point_eau_bdt_')) = 'n_reservoir_eau_bdt_'
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Réservoir d’eau de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Tous les réservoirs de plus de 10 m de diamètre sont inclus, sauf les réservoirs d’eau non couverts (classe SURFACE_EAU), les citernes (classe POINT_EAU), et les bassins (classe SURFACE_EAU). 
 
Modélisation géométrique : Contour extérieur du réservoir, à l’altitude de ce contour. 
Un  groupe  de  petits  réservoirs  (<10  m)  peut  être  modélisé  par  l’enveloppe  convexe  de l’ensemble. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du réservoir.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du réservoir d’eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du réservoir d’eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du réservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du réservoir d’eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du réservoir d’eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Surface d’eau terrestre, naturelle ou artificielle de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Toutes les surfaces d’eau de plus de 20 m de long sont incluses, ainsi que les cours d’eau de plus de 7,5 m de large. Les cours d’eau de plus de 5 m de large sont ajoutés lorsqu’ils sont situés entre deux surfaces d’eau, ou en prolongation d’une surface d’eau vers la source. 
 
Tous les bassins maçonnés de plus de 10 m sont inclus. Les zones inondables périphériques (zone périphérique d’un lac de barrage, d’un étang à niveau variable) de plus de 20 m de large sont incluses (attribut REGIME = Intermittent). 
 
 
Modélisation géométrique : La modélisation est fonction de la valeur de l’attribut REGIME : 
•  Pour l’hydrographie permanente : contours de la surface, au niveau de l’eau apparent sur les photographies aériennes de référence. 
•  Pour  l’hydrographie  temporaire  :  contours  de  la  surface  marquée  de  manière  permanente par la présence répétée de l’eau. 
 
Contrainte de modélisation : 
Une surface d’eau inscrite dans la continuité d’un cours d’eau est toujours doublée d’un objet de classe TRONCON_COURS_EAU et d’attribut FICTIF = Oui. 
Dans  leur  partie  aval,  les  surfaces  d’eau  représentant  des  cours  d’eau  sont  représentées  au moins jusqu’à la laisse des plus hautes mers.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la surface d’eau.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.regime IS ''Régime des eaux'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_moyen IS ''Altitude moyenne des points composants la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Portion de cours d’eau, réel ou fictif, permanent ou temporaire de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : 
Le réseau hydrographique composé des objets TRONCON_COURS_EAU est décrit de manière continue. 
La continuité du réseau n’est toutefois pas toujours assurée dans les cas suivants : 
•  arrivée d’un cours d’eau en ville ; 
•  infiltration d’un cours d’eau (ex. perte en terrain calcaire) ; 
•  arrivée d’un petit ruisseau temporaire dans une large plaine où son tracé se perd ; 
•  zones de marais où les connexions et interruptions du réseau restent indicatives. 
 
Tous les cours d’eau permanents, naturels ou artificiels, sont inclus. 
 
Les cours d’eau temporaires naturels sont inclus, à l’exception des tronçons de moins de 100 m situés aux extrémités amont du réseau. 
 
Les  cours  d’eau  temporaires  artificiels  ou  artificialisés  sont  sélectionnés  en  fonction  de  leur importance et de l’environnement (les tronçons longeant une voie de communication sont exclus, ainsi que les fossés). 
 
Les talwegs qui ne sont pas marqués par la présence régulière de l’eau sont exclus. 
 
Tous les cours d’eau nommés de plus de 7,5 m de large (éventuellement 5 m de large dans les cas  expliqués  au  chapitre  7.5.1  Définition)  sont  inclus  (TRONCON_COURS_EAU  d’attribut FICTIF = Oui superposé à un objet de classe SURFACE_EAU) 
 
Fossé  :  Les  gros  fossés  de  plus  de  2  m  de  large  sont  inclus  lorsqu’ils  coulent  de  manière permanente.  Les  fossés  dont  le  débit  n’est  pas  permanent  sont  sélectionnés  en  fonction  de l’environnement. Ils sont généralement exclus lorsqu’ils longent une voie de communication.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.artif IS ''Artificiel'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.fictif IS ''Indique la nature fictive ou réel du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.franchisst IS ''Nature du franchissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du cours d eau'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.pos_sol IS ''Position par rapport au sol'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.regime IS ''Régime des eaux'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_ini IS ''Altitude du sommet initial du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_fin IS ''Altitude du sommet final du tronçon'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Limite de l’estran de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Laisse des plus hautes mers et laisse des plus basses mers. 
 
Avertissement :  la  laisse  des  plus  basses  mers  est  issue  à  l’origine  de  cartes  du  SHOM (Service Hydrographique et Océanographique de la Marine). Cette laisse n’est pas mise à jour, elle ne doit en aucun cas être utilisée pour la navigation. Les utilisateurs qui voudraient pratiquer des activités assimilables à la navigation sont priés de se reporter aux dernières documentations, notamment les cartes papier ou électroniques, du SHOM. 
 
Modélisation  géométrique  :  La  laisse  des  plus  hautes  mers  est  modélisée  par  une  ligne d’altitude constante (de type courbe de niveau) dont l’altitude est calculée. 
La laisse des plus basses mers est modélisée par une ligne correspondant à l’isobathe 0 (0 des cartes marines). 
 
Contrainte  de  modélisation  :  Les  deux  laisses  ne  se  croisent  pas.  Elles  peuvent  être confondues (ex : Méditerranée).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon de laisse.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '..prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la surface'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Bâtiment ne possédant pas de fonction particulière de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Bâtiment ne possédant pas de fonction particulière pouvant être décrit dans les autres classes de bâtiments surfaciques  (voir 8.2, 8.3, 8.4) : bâtiments d’habitation, d’enseignement… (voir détails dans les § Sélection et Modélisation géométrique). 

Sélection  :  Bâtiments  d’habitation,  bergeries,  bories,  bungalows,  bureaux,  chalets,  bâtiments d’enseignement,  garages  individuels,  bâtiments  hospitaliers,  immeubles  collectifs,  lavoirs couverts, musées, prisons, refuges, villages de vacances. 
 
La  modélisation  géométrique  peut  être  de  deux  types  suivant  que  le  bâtiment  est  issu initialement  de  la  BD  TOPO® (c’est-à-dire  principalement  obtenu  par  restitution photogrammétrique  à  partir  d’une  prise  de  vue  aérienne),  ou  que  celui-ci  est  obtenu  après intégration  des  données  du  cadastre.  Les  deux  possibilités  coexistent  actuellement  dans  la BD TOPO®, jusqu’à intégration complète des bâtiments du cadastre. 
 
Intégration du bâti du cadastre ou « unification » : L’objectif de l’unification est de créer une nouvelle  couche  « bâti »  en  utilisant  les  points  forts  de  la  BD  TOPO® et de la BD PARCELLAIRE®.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du bâtiment.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Bâtiment à caractère industriel, commercial ou agricole de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Bâtiment ne possédant pas de fonction particulière pouvant être décrit dans les autres classes de bâtiments surfaciques  (voir 8.2, 8.3, 8.4) : bâtiments d’habitation, d’enseignement… (voir détails dans les § Sélection et Modélisation géométrique). 

Sélection  :
- Bâtiment agricole : Bâtiment  réservé  à  des  activités  agricoles :  bâtiment  d’élevage industriel, hangar agricole (grand), minoterie. 
- Bâtiment commercial : Bâtiment  de  grande  surface  réservé  à  des  activités commerciales :  centre  commercial,  hypermarché,  magasin (grand, isolé), parc des expositions (bâtiment). 
- Bâtiment industriel : Bâtiment  réservé  à  des  activités  industrielles :  abattoir,  atelier (grand),  auvent  de  quai  de  gare),  auvent  de  péage,  bâtiment industriel  (grand),  centrale  électrique  (bâtiment),  construction technique, entrepôt, hangar industriel (grand), scierie, usine. 
- Serre : Abri clos à parois translucides destiné à protéger les végétaux du froid : jardinerie, serre. Les serres en arceaux de moins de 20 m de long sont exclues. Les  serres  situées  à  moins  de  3  m  les  unes  des  autres  sont modélisées  par  un  seul  objet  englobant  l’ensemble  des  serres en s’appuyant au maximum sur leurs contours. 
- Silo : Réservoir, qui chargé par le haut se vide par le bas, et qui sert de dépôt, de magasin, etc. Le silo est exclusivement destiné aux produits agricoles : cuve à vin, silo 
 
La  modélisation  géométrique  peut  être  de  deux  types  suivant  que  le  bâtiment  est  issu initialement  de  la  BD  TOPO® (c’est-à-dire  principalement  obtenu  par  restitution photogrammétrique  à  partir  d’une  prise  de  vue  aérienne),  ou  que  celui-ci  est  obtenu  après intégration  des  données  du  cadastre.  Les  deux  possibilités  coexistent  actuellement  dans  la BD TOPO®, jusqu’à intégration complète des bâtiments du cadastre. 
 
Intégration du bâti du cadastre ou « unification » : L’objectif de l’unification est de créer une nouvelle  couche  « bâti »  en  utilisant  les  points  forts  de  la  BD  TOPO® et de la BD PARCELLAIRE®.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du bâtiment.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Bâtiment possédant une fonction, contrairement aux bâtiments indifférenciés, et dont la fonction est autre qu’industrielle de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Bâtiment possédant une fonction, contrairement aux bâtiments indifférenciés, et dont la fonction est autre qu’industrielle (ces derniers sont regroupés dans la classe BATI_INDUSTRIEL). Il s’agit des bâtiments administratifs, religieux, sportifs, et relatifs au transport. 
Sélection  :
- Aérogare : Ensemble des bâtiments d’un aéroport réservés aux voyageurs et aux marchandises. 
- Arc de triomphe : Portique monumental : arc de triomphe, porte de ville. 
- Arène ou théâtre antique : Vaste  édifice  à  gradins,  de  forme  en  partie  ou  totalement  ronde  ou elliptique : amphithéâtre, arène, théâtre antique, théâtre de plein air. 
- Bâtiment religieux divers : Bâtiment  réservé  à  l’exercice  d’un  culte  religieux,  autre  qu’une chapelle  ou  qu’une  église  (voir  ces  valeurs) :  mosquée, synagogue, temple. 
- Bâtiment sportif : Bâtiment  réservé  à  la  pratique  sportive :  gymnase,  piscine  couverte, salle de sport, tennis couvert. 
- Chapelle : Petit édifice religieux catholique de forme caractéristique 
- Château : Habitation  ou  ancienne  habitation  féodale,  royale  ou  seigneuriale :château, château fort, citadelle 
- Eglise : Édifice religieux catholique de forme caractéristique : basilique,cathédrale, église. 
- Fort, blockhaus, casemate : Ouvrage militaire : blockhaus, casemate, fort, ouvrage fortifié. 
- Gare : Bâtiment servant à l’embarquement et au débarquement des voyageurs en train. 
- Mairie : Édifice  où  se  trouvent  les  services  de  l’administration municipale, appelé aussi hôtel de ville. 
- Monument : Monument commémoratif quelconque, à l’exception des arcs de triomphe (voir cette valeur d’attribut). 
- Péage : Bâtiment où sont perçus les droits d‘usage. 
- Préfecture : Bâtiment où sont installés les services préfectoraux. 
- Sous-préfecture : Bâtiment  où  sont  les  bureaux  du  sous-préfet :  chef-lieu d’arrondissement. 
- Tour, donjon, moulin : Bâtiment remarquable dans le Paysage par sa forme élevée : donjon, moulin à vent, tour, tour de contrôle. 
- Tribune : Tribune de terrain de sport (stade, hippodrome, vélodrome,…).

La  modélisation  géométrique  peut  être  de  deux  types  suivant  que  le  bâtiment  est  issu initialement  de  la  BD  TOPO® (c’est-à-dire  principalement  obtenu  par  restitution photogrammétrique  à  partir  d’une  prise  de  vue  aérienne),  ou  que  celui-ci  est  obtenu  après intégration  des  données  du  cadastre.  Les  deux  possibilités  coexistent  actuellement  dans  la BD TOPO®, jusqu’à intégration complète des bâtiments du cadastre. 
 
Intégration du bâti du cadastre ou « unification » : L’objectif de l’unification est de créer une nouvelle  couche  « bâti »  en  utilisant  les  points  forts  de  la  BD  TOPO® et de la BD PARCELLAIRE®.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du bâtiment.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les bâtiments'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Cimetière de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Lieu où l’on enterre les morts. 
Cimetière communal, islamique, israélite, ou militaire.

Sélection : Tous les cimetières sont inclus. 
Les crématoriums, funérariums, ossuaires, … situés hors cimetière sont exclus. 
 
Modélisation géométrique : Le contour de la surface représente l’enceinte du cimetière (haut du mur si c’est un mur, bord de toit si c’est un bâtiment, sol s’il s’agit d’une simple clôture). 
 
Contrainte de modélisation : 
Un objet de classe CIMETIERE peut englober des bâtiments (la surface n’est pas trouée). 
La  géométrie  d’un  cimetière  peut  être  partiellement  identique  à  celle  d’un  bâtiment  (bâtiment mitoyen).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du cimetiere.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du cimetiere'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Structure légère de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Structure légère non attachée au sol par l’intermédiaire de fondations (cabanes, abris de jardins…) ou bâtiment quelconque ouvert sur au moins un côté (préaux, auvents, tribunes).

Sélection : Baraquements, cabanes, granges, préaux, auvents, tribunes. 
 
Modélisation géométrique : Voir paragraphe 8.1.1 Définition de la classe .BATI_INDIFFENCIE. 
 
Disponibilité : La classe d’objets CONSTRUCTION_LEGERE sera disponible au fur et à mesure de  l’avancement  de  la  production  du  bâti  unifié  qui  reprend  la  géométrie  de  toutes  les constructions  de  la  BD  PARCELLAIRE®,  sauf  celles  manifestement  détruites  au  moment  du processus d’unification. 
 
Avant unification des bâtiments, il n’y a pas d’objets CONSTRUCTION_LEGERE. 
Après  unification,  tous  les  bâtiments  qui  ont  été  appariés  avec  une  construction  légère  de  la BD PARCELLAIRE® sont transférés dans la classe CONSTRUCTION_LEGERE.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction legère.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source de la construction'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Construction linéaire de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Construction dont la forme générale est linéaire.Exemples : barrage, mur anti-bruit, ruines, etc.

Sélection : Indifférencié, Barrage, Mur anti-bruit, Pont, Ruines, Quai.
 
Modélisation géométrique : Voir pour chaque valeur de l’attribut NATURE.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction linéaire.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les constructions'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du bâtiment'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Construction ponctuelle de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Construction de faible emprise et de grande hauteur de plus de 50 m de haut et de moins de 20 m2.

Sélection : Toutes les constructions de plus de 50 m de haut et de moins de 20 m2. 
Les constructions de grande hauteur et de plus de 20 m² sont exclues (elles sont représentées par un objet de classe <bâtiment>). 
 
Les constructions de moins de 20 m2 et de moins de 50 m de haut sont incluses : 
•  lorsque leur taille ou leur forme font d’elles des constructions à la fois bien identifiables et caractéristiques dans le paysage ; 
•  pour permettre de coter le sommet d’un bâtiment dont la base large impose une saisie au niveau du sol et empêche de récupérer l’altitude du faîte élevé (ex. bâtiment de forme pyramidale, surmonté d’une tour,…). 
 
Modélisation géométrique : Centre de l’objet, altitude maximum. 
 
Contrainte de modélisation : Dans le cas d’un clocher, d’un minaret ou d’une cheminée, l’objet de classe CONSTRUCTION_PONCTUELLE peut être superposé à un objet surfacique.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction linéaire.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les constructions'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale de la construction linéaire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale de la construction linéaire'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Ouvrage surfacique de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Ouvrage de grande surface lié au franchissement d’un obstacle par une voie de communication, ou à l’aménagement d’une rivière ou d’un canal.

Sélection :
- Barrage : Grand barrage en maçonnerie apparente. Ex : barrage-voûte 
Tous les barrages maçonnés dont la surface projetée au sol dépasse 25 m de large sont inclus. Les autres barrages (barrages plus étroits ou barrages en terre) sont modélisés par la classe CONSTRUCTION_LINEAIRE. 
Modélisation : Contours de l’ouvrage défini par l’axe de la partie horizontale supérieure, et par le pied du barrage. 
- Dalle  de protection :Dalle  (ou  auvent)  horizontale  protégeant  une  voie  de  communication  des chutes de pierres, des coulées de neige, ou protégeant le voisinage du bruit. 
Toutes les dalles de protection de plus de 100 m de long sont incluses (une suite  de  dalles  se  succédant  à  moins  de  20 m  les  unes  des  autres  est considérée comme une seule dalle). 
Modélisation : Limite extérieure de la dalle, altitude de sa face supérieure. 
- Ecluse : Ouvrage  hydraulique  formé  essentiellement  de  portes  munies  de  vannes destiné à retenir ou à lâcher l’eau selon les besoins : ascenseur à bateaux, 
cale sèche, écluse, radoub. 
Toutes les écluses, cales sèches et radoubs possédant leurs portes et tous les ascenseurs à bateaux sont inclus lorsqu’ils sont situés sur un cours d’eau de plus de 7,5 m de large (Si le cours d’eau est plus étroit, la modélisation de l’écluse  se  fait  uniquement  par  changement  d’attribut  du TRONCON_COURS_EAU).
Modélisation : Contours de la chambre d’écluse, de la cale ou de la pente de l’ascenseur. L’altitude est celle du bord du quai. 
- Pont : Pont supportant plusieurs objets linéaires, un objet surfacique, ou pont dont l’emprise  dépasse  largement  celle  des  voies  qu’il  supporte.  Il  peut  être mobile. 
Tous  les  ponts  supportant  un  objet  surfacique  ou  plusieurs  objets  linéaires sont inclus. 
Les ponts dont les parapets se trouvent  à 20 m ou  plus du bord des  voies supportées sont inclus. 
Les  ponts  ne  supportant  qu’un  objet  linéaire  sont  modélisés  par  un changement  de  valeur  de  l’attribut  <position  par  rapport  au  sol>  (qui  prend une valeur strictement positive sur le pont). 
Modélisation : Surface définie par les deux parapets du pont et deux lignes joignant les extrémités des parapets. 
- : Escalier  Escalier monumental uniquement (contours de l’escalier). 
Modélisation : Contours de la chambre d’écluse, de la cale ou de la pente de l’ascenseur. L’altitude est celle du bord du quai.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction surfacique.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les constructions surfaciques'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale de la construction surfacique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale de la construction surfacique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Piste d’aérodrome de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Aire  située  sur  un  aérodrome,  aménagée  afin  de  servir  au  roulement  des aéronefs, au décollage et à l’atterrissage, en dur ou en herbe.

Sélection : Tous les aérodromes sont inclus, y compris les héliports, que la piste soit revêtue ou en herbe. 
 
Modélisation géométrique : Contour de l’ensemble des pistes et des aires de roulement, au sol.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la piste.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Permet de distinguer les constructions surfaciques'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_moyen IS ''Altitude moyenne de la piste'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Réservoir de plus de 10m de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Réservoir (eau, matières industrielles,…) de plus de 10m de diamètre. 
Remarque : les réservoirs d’eau et château d’eau sont également présents dans la classe RESERVOIR_EAU du thème hydrographique.

Sélection : Tous les réservoirs de plus de 10 m de diamètre sont inclus sauf : 
•  les réservoirs souterrains sont exclus ; les citernes sont dans la  classe POINT_EAU ; 
•  les réservoirs d’eau non couverts sont exclus (voir classe SURFACE_EAU, NATURE =Bassin). 
 
Modélisation géométrique : Contour extérieur du réservoir, à l’altitude de ce contour (altitude de l’arête supérieure en cas de face verticale). 
Un groupe de petits réservoirs (<10 m) peut être modélisé par un rectangle englobant l’ensemble. 
 
L’altitude correspondant au contour est une altitude toit médiane, calculée par interpolation sur un MNE  (Modèle  Numérique  d’Élévation)  ou  par  rapport  au  Z  du  toit  BD  TOPO®,  en  prenant  en compte les altitudes des contours des bâtiments directement contigus s’ils existent.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du reservoir.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_bat IS ''Source du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.hauteur IS ''Hauteur du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale du reservoir'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Équipement sportif de plein air de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection :
- Indifférencié : Grand terrain découvert servant à la pratique de sports collectifs tels  que  le  football,  le  rugby,  etc. :  plate-forme  multisports, terrain d’entraînement, terrain de football, terrain de rugby. 
Plate-forme multisports : Seules les plates-formes aménagées (revêtement,  panneaux  de  baskets,  marquage  au  sol,…), réservées à la pratique sportive, équipées de plusieurs terrains de  jeux,  et  d’une  longueur  totale  de  50 m  au  moins  sont incluses. Les cours de récréation plus ou moins équipées pour la pratique sportive sont exclues. 
Terrain  d’entraînement : Seuls  les  terrain  d’entraînement  de football  ou  de  rugby  dont  la  taille  et  l’aspect  sont  proches  de ceux des terrains réglementaires sont inclus (marquage au sol, présence de tribunes ou de vestiaires, etc.). Les petits terrains mal délimités sont exclus. 
Modélisation : Surface s’appuyant sur l’aire de jeu. Dans le cas des plates-formes multisports, c’est l’emprise globale de la partie aménagée  qui  est  représentée.  L’altitude  est  toujours  celle  du sol. 
- Piste de sport : Large piste réservée à la course : autodrome (piste), circuit auto-moto (piste), cynodrome (piste), hippodrome (piste), vélodrome (piste). 
Sélection : Toutes les pistes de sport de plus de 10 m de large environ  sont  incluses  sauf  celles  qui  sont  situées  en  salle (vélodrome…). 
Les  pistes  de  sport  de  moins  de  10  m  de  large  environ  sont exclues  
Les pistes d’athlétisme sont exclues. 
Modélisation : Contours de la piste, au sol. 
- Terrain de tennis : Terrain spécialement aménagé pour la pratique du tennis. 
Sélection : Tous  les  terrains  de  tennis  extérieurs  entretenus sont inclus. 
Modélisation : Contours  du  terrain  (grillage  en  planimétrie,  sol en altimétrie). 
Contrainte  de  modélisation : Plusieurs  terrains  de  tennis contigus  sont  modélisés  par  un  seul  objet  englobant  les différents terrains. 
- Bassin de natation : Bassin  de  natation  d’une  piscine  découverte :  bassin  de natation, piscine (découverte). 
Sélection : Tous les bassins de natation de piscine découverte dont la longueur est supérieure ou égale à 25 m sont inclus. 
Modélisation : Surface s’appuyant sur les rebords du bassin.  
 
Modélisation géométrique : Voir les différentes valeurs de l’attribut NATURE.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du terrain de sport.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du terrain de sport'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_moyen IS ''Altitude moyenne du terrain de sport'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Zone de végétation de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Espace végétal naturel ou non différencié selon le couvert forestier.
Sélection : Bois de plus de 500m2 ; forêts ouvertes, landes, vignes et vergers de plus de 5000m2. 
L’exhaustivité ne pouvant être assurée en dessous de ces seuils, les sélections sont effectuées de façon à donner une vision représentative du paysage : 
•  structure principale d’un réseau dense de haies ou rangées d’arbres ; 
•  sélection d’arbres isolés et bosquets en zone urbaine et en zone de végétation clairsemée (maquis, jardins ouvriers…). 
 
Définitions du couvert : 
o   Couvert absolu d’un peuplement : surface planimétrique de la projection verticale des houppiers des arbres du peuplement. 
o   Taux de couvert absolu : quotient du couvert absolu du peuplement par la surface du site. 
o   Taux de couvert relatif d’un sous-peuplement : quotient du couvert absolu du sous-peuplement par le couvert absolu du peuplement. 
 
Modélisation  géométrique  :  Contour  extérieur  de  la  zone.  Voir  détail  pour  chaque  valeur  de l’attribut NATURE. 
 
Contrainte de modélisation : Voir le détail par valeur de l’attribut NATURE. 
 
Disponibilité : Dans un premier temps, l’attribut NATURE de la classe ZONE_VEGETATION du produit BD TOPO® n’est rempli que par la valeur « Zone arborée » ; au fur et à mesure de l’avancement de la production multi-thème (qui permet de distinguer différents types de végétation), cette valeur disparaît au profit de 12 postes distincts (la valeur « Zone arborée » sera exclusive de toutes les autres).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du terrain de sport.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du terrain de sport'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Ligne de rupture de pente artificielle de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Voir chaque valeur de l’attribut NATURE. 

Levée 
Définition : Digue  en  terre  (levée  de  terre)  ou  en  maçonnerie  de  faible  largeur : crassier, levée de terre, digue en terre, remblai, terril.
Sélection :
•Remblai : Tous les remblais de voies de communication de plus de 200 m de long, 2 m de haut et de moins de 20 m de large sont inclus.
•Digue : Toutes les digues en terre ou en pierres de plus de 200 m de long et 2 m de haut sont incluses.
•Levée de terre : Toutes les levées de terre ou de pierres isolées de plus de 200 m de long et 3 m de haut sont incluses.
Modélisation : Axe et sommet de la levée.
Contrainte   de   modélisation:   Une   levée   supportant   une   voie   de   communication  (ou  un  canal)  est  décrite  par  une  géométrie  identique  à  celle-ci.   
Pour cet objet, l’orientation n’est pas significative.

Mur de soutènement
Définition : Mur épaulant un remblai, une terrasse.
Sélection :  Tous  les  murs  de  soutènement  de  plus  de  200  m  de  long  et  2  m  de haut situés le long d’une voie de communication sont inclus.
Tous les murs de soutènement de plus de 3 m de haut et 100 m de long sont inclus (fortifications, terrasse,...).
Modélisation géométrique : Rebord du mur. L’objet est orienté de manière à ce que le coté aval soit sur sa droite.

Talus 
Définition : Ligne de rupture de pente : crassier, déblai, remblai, talus.
Sélection : Tous les talus de plus de 200 m de long et 2 m* de haut situés le long  d’une  voie  de  communication  sont  inclus,  qu’ils  soient  en  terre  ou  rocheux (voir aussi <ligne orographique> pour les voies de communication en remblai).
Les talus naturels de plus de 200 m de long et de 3 m de haut sont retenus.
Les    talus    de    carrière    prennent    une    autre    valeur    d’attribut    (voirNATURE = Carrière). 
* Le  long  des  routes  situées  à  flanc  de  montagne,  le  critère  de  hauteur  est  relevé en fonction de la pente, de manière à exclure tous les talus de 2 à 5 m qui  font  partie  du  profil  normal  de  la  route,  et  qui  bordent  celle-ci  de  manière  continue.
Modélisation  géométrique :  Ligne  de  rupture  de  pente  amont  (la  limite  aval  d’un talus n’est jamais représentée). L’objet est orienté de manière à ce que le coté aval soit sur sa droite.

Carrière
Définition :  Grand  talus  marquant  le  front  et  la  structure  principale  d’une  carrière : gravière (talus), mine à ciel ouvert (talus), talus de carrière.
Sélection : Les talus de carrière principaux sont inclus.
Modélisation  géométrique  :  Ligne  de  rupture  de  pente  amont  (la  limite  aval  d’un talus n’est jamais représentée). L’objet est orienté de manière à ce que le coté aval soit sur sa droite.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la ligne orographique.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_alti IS ''Précision altimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature de la ligne de rupture de pente'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_min IS ''Altitude minimale de la ligne orographique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.z_max IS ''Altitude maximale de la ligne orographique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Détail du relief portant un nom de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection :  Tous  les  détails  orographiques  dont  le  nom  figure  sur  la  carte  au  1 : 25 000  en  service.
- Cap : Prédominance dans le contour d’une côte : cap, pointe, promontoire.
- Cirque : Dépression semi-circulaire, à bords raides.
- Col : Point de passage imposé par la configuration du relief : col, passage.
- Crête : Ligne de partage des eaux : crête, arête, ligne de faîte.
- Dépression : Dépression naturelle du sol : cuvette, bassin fermé, dépression, doline.
- Dune : Monticule de sable sur les bords de la mer.
- Escarpement : Escarpement  du  relief :  barre  rocheuse,  escarpement  rocheux,  face  abrupte, falaise.
- Gorge : Vallée étroite et encaissée : canyon, cluse, défilé, gorge.
- Grotte : Grotte naturelle ou excavation : aven, cave, gouffre, grotte.
- Ile : Île, îlot ou presqu’île.
- Isthme : Bande de terre étroite entre deux mers, réunissant deux terres : cordon littoral, isthme.
- Montagne : Désigne  une  montagne  ou  un  massif  de  manière  globale  et  non  un  sommet en particulier (voir sommet).
- Pic : Sommet pointu d’une montagne : aiguille, pic, piton.
- Plage : Zone littorale marquée par le flux et le reflux des marées : grève, plage.
- Plaine : Zone de surface terrestre caractérisée par une relative planéité : plaine, plateau.
- Récif : Rocher   situé   en   mer   ou   dans   un   fleuve,   mais   dont   une   partie, faiblement émergée, peut constituer un obstacle ou un repère : brisant, récif, rocher marin.
- Rochers : Zone ou détail caractérisé par une nature rocheuse mais non verticale : chaos, éboulis, pierrier, rocher.
- Sommet : Point  haut  du  relief  non  caractérisé  par  un  profil  abrupt  (voir  la  nature  Pic) : colline, mamelon, mont, sommet.
- Vallée : Espace  entre  deux  ou  plusieurs  montagnes. Forme  définie  par  la  convergence  des  versants  et  qui  est,  ou  a  été  parcourue  par  un  cours  d’eau : combe, ravin, val, vallée, vallon, thalweg.
- Versant : Plan incliné joignant une ligne de crête à un thalweg : coteau, versant.
- Volcan : Toute  forme  de  relief  témoignant  d’une  activité  volcanique :  cratère, volcan.

Modélisation géométrique : Centre du détail nommé.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du toponyme.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.5.H_ADMINISTRATIF  
---- B.5.H.1 ARRONDISSEMENT
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_arondissement_bdt_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_arondissement_bdt_')) = 'n_arondissement_bdt_'
	THEN
--- Index
	nom_table := 'n_arondissement_bdt';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Arrondissement municipal pour Lyon, Paris & Marseille de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Arrondissement municipal: subdivision administrative de certaines communes.
Les arrondissements municipaux sont gérés par l’INSEE comme des communes.

Sélection : Arrondissements municipaux de Paris, Lyon et Marseille.
Remarque  sur  la  modélisation  géométrique :  Les  contours  des  arrondissements  de  la  BD TOPO®  et  de  la  BD  PARCELLAIRE®  ne  sont  pas  exactement  superposables;  en  effet, 
l’origine   de   la   donnée   n’est   pas   la   même   pour   ces   deux   bases   (cadastre   pour   la   BD PARCELLAIRE®).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de l’arrondissement.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom de l’arrondissement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.code_insee IS ''Code Insee'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Chef-lieu de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Centre de la zone d’habitat dans laquelle se trouve la mairie de la commune. 
Dans certains cas, le chef-lieu n’est pas dans la commune.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du chef-lieu.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id_com IS ''Identifiant de la commune à laquelle se rapporte le chef-lieu'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du chef lieu (commune, canton, préfecture, sous-préfecture)'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du chef lieu'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Commune de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Plus  petite  subdivision  du  territoire,  administrée  par  un  maire,  des  adjoints  et  un  conseil municipal.

Sélection : Toutes les communes sont retenues.
Remarque sur la modélisation géométrique : Les contours des communes de la BD TOPO® et de  la  BD  PARCELLAIRE®  ne  sont  pas  exactement  superposables;  en  effet,  l’origine  de  la donnée n’est pas la même pour ces deux bases (cadastre pour la BD PARCELLAIRE®).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant de la commune.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.prec_plani IS ''Précision planimétrique'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.code_insee IS ''Code Insee de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.statut IS ''Statut de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.arrondisst IS ''Nom de l’arrondissement de rattachement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.depart IS ''Nom du département de rattachement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.region IS ''Nom de la région de rattachement'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.popul IS ''Population de la commune'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt administratif ou militaire de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation d’un  établissement,  site  ou  zone  ayant  un  caractère  public  ou  administratif ou militaire.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Borne : Borne nommée :  borne  frontière,  point  de  triangulation,  point  frontière.
- Bureau ou hôtel des postes : Bureau  de  poste  ouvert  au  public:  Bureau  de  poste,  hôtel  des  postes, agence postale.
Seuls  les  bureaux  de  poste  ouverts  en  permanence  sont  inclus.  En général, dans les agglomérations, seules les postes centrales sont incluses.
- Caserne de pompiers : Bâtiment ayant ou non un bureau ou une permanence et qui est entièrement   concerné   par   l’activité   du   corps   des   Sapeurs-Pompiers.
- Divers public ou administratif : Bâtiment ou zone à caractère public ou administratif, qui n’est ni défini  par  une  autre  classe  de  PAI,  ni  par  une  autre  valeur  d’attribut NATUREde   la   présente   classe   (administratif   ou   militaire):  UNESCO,  Parlement  Européen,  ministère,  direction  ministérielle,  Assemblée  nationale,  Sénat,  cité  administrative,  poste de douane, capitainerie, salle de spectacle, ...
En  général  les  établissements  et  les  sites  retenus  ont  une  importance  ou  une  notoriété  d’ordre  national  ou  régional  ou  une  surface au sol d’au moins 1000 m2 environ. 
- Enceinte militaire : Zone  en  permanence  réservée  pour  les  rassemblements  de  troupes  de  toutes  les  armes,  soit  pour  des  manœuvres,  des  exercices (camp d’instruction), soit pour des essais, des études : base,  camp,  caserne,  dépôt  de  matériels,  terrain  permanent  d’entraînement,   caserne   de   CRS,   caserne   de   gendarmes   mobiles, ...
Les champs de tir sont exclus ainsi que les propriétés de l’armée qui ne sont indiquées d’aucune manière sur le terrain (ni clôtures, ni   barrière,   ni   pancartes,...)   et   ne   faisant   l’objet   d’aucune  restriction particulière.  

- Etablissement pénitentiaire : Établissement   clos   aménagé   pour   recevoir   des   délinquants   condamnés  à  une  peine  privative  de  liberté  ou  des  détenus  en  instance de jugement : maison d’arrêt, prison.
Les annexes sont exclues.
- Gendarmerie : Caserne   où   les   gendarmes   sont   logés;  bureaux  où  ils remplissent    leurs    fonctions    administratives    :    gendarmerie,    gendarmerie d’autoroute.
Définition  de  l’emprise  du  site : surface  de  l’ensemble  de  la  caserne,  généralement  délimitée  par  une  clôture  et  incluant  logements et bureaux. 
- Hôtel de département : Bâtiment où siège le conseil général.
Seul le bâtiment principal est inclus. Les annexes ne le sont pas, sauf   éventuellement   une   annexe   située   dans   une   autre   agglomération  lorsqu’elle  a une  fonction  proche  de  celle  du  siège.
- Hôtel de région : Bâtiment où siège le conseil régional.
Seul le bâtiment principal est inclus. Les annexes ne le sont pas, sauf   éventuellement   une   annexe   située   dans   une   autre   agglomération  lorsqu’elle  a  une  fonction proche  de  celle  du  siège.
- Mairie : Bâtiment  où  se  trouvent  le  bureau  du  maire,  les  services  de  l’administration  municipale  et  où  siège  normalement  le  conseil  municipal : mairie, mairie annexe, hôtel de ville.
Les mairies annexes sont incluses (fréquentes dans les grandes villes   ou   dans   les   anciens   chefs-lieux   de   commune   ayant   fusionné,   elles   offrent   des   services   similaires   aux   mairies   principales).
Les annexes de la mairie (services techniques,...) sont exclues.
En général le bâtiment saisi est celui de l’accueil du public.
- Maison forestière : Maison gérée par l’office national des forêts. Les maisons de garde occupées par au moins un agent de l’ONF sont incluses. 
Les  bureaux  de  l’ONF,  les  domiciles  d’agents  servant  aussi  de  bureau,  sont  exclus  lorsqu’ils  ne  sont  pas  situés  dans  une  maison forestière.
- Ouvrage militaire : Ouvrages et installations militaires.
- Palais de justice : Bâtiment où l’on rend la justice : palais de justice, tribunal. Seule  la  justice  pénale  est  traitée.  Les  tribunaux  administratifs  sont exclus.
- Poste ou hôtel de police : Établissement  occupé  par  un  commissaire  de  police  (officier  de  police judiciaire chargé de faire observer les règlements de police et  de  veiller  au  maintien  de  la  paix  publique):  hôtel  de  police  nationale, commissariat, CRS d’autoroute, de port ou d’aéroport.
Les  bâtiments  hébergeant  uniquement  la  police  municipale  sont  
exclus. Les casernes de CRS et de gendarmes mobiles prennent la  valeur  «enceinte  militaire»  et  les  gendarmeries  la  valeur  « gendarmerie ». 
- Préfecture : Établissement qui abrite l’ensemble des services de l’administration   préfectorale :   préfecture,   préfecture   annexe,   préfecture maritime.
- Préfecture de région : Établissement  qui  abrite  le  siège  de  l’administration  civile  de  la  région.
- Sous-préfecture : Établissement  qui  abrite  les  services  administratifs  du  sous-préfet.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt culture ou loisir de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation  d’un  établissement  ou  lieu  spécialement  aménagé  pour  une  activité  culturelle, touristique ou de loisirs

Sélection : Voir les différentes valeurs de l’attribut NATURE :  
- Camping : Emplacement   aménagé   pour   la   pratique   du   camping   d’une superficie de plus de 2 ha.
- Construction : Construction   nommée   habitée   ou   associée   à   un   groupe   d’habitations : construction diverse, pigeonnier, moulin à vent.
- Digue : Digue, môle, jetée.
- Dolmen : Monument  mégalithique  formé  d’une  grande  pierre  plate  posée  sur d’autres pierres dressées verticalement. Les allées couvertes sont incluses.
- Espace public : Large  espace  découvert  urbain  désigné  par  un  toponyme  où  aboutissent  plusieurs  rues,  fermé  à  la  circulation  automobile,  constituant un lieu remarquable : place, square, jardin, parc, parc communal,    parc    intercommunal,    parc    départemental,    parc interdépartemental.
Seuls les espaces publics possédant un toponyme sont retenus. Les  parcs  à  vocation  commerciale  sont  exclus  (voir  la  valeur  Parc  de  loisirsci-dessous),  de  même  que  les  parcs  naturels  (réserves,  parcs  nationaux,  parcs  naturels  régionaux)  qui  sont  traités en PAI_ESPACE_NATUREL.
- Habitation troglodytique : Excavation   naturelle   ou   creusée   dans   le   roc   (caverne,   grotte), habitée ou anciennement habitée.
- Maison du parc : Bâtiment  ouvert  au  public  et  géré  par  un  Parc  National  ou  Régional.
- Menhir : Pierre allongée, dressée verticalement.Les alignements en cromlech sont inclus.
- Monument : Monument   sans   caractère   religieux   particulier:   monument,   statue, stèle.
- Musée : Établissement  ouvert  au  public  exposant  une  grande  collection  d’objets,  de  documents,  etc.,  relatifs  aux  arts  et  aux  sciences  et  pouvant servir à leur histoire.
Sont inclus : tous  les  musées  contrôlés  ou  supervisés  par  le  ministère  de  la  Culture (musées nationaux, classés, contrôlés,...) ;les  musées  relevant  de  certains  ministères  techniques  ou  de  l’assistance publique (musée de l’armée, de la marine) ;les musées privés ou associatifs ayant une grande notoriété ;les écomusées.
- Parc des expositions : Lieu   d’exposition   ou   de   culture   :   centre   culturel,   parc   des   expositions.
- Parc de loisirs : Parc  à  caractère  commercial  spécialement  aménagé  pour  les  loisirs:  centre  permanent  de  jeux,  parc  d’attraction,  parc  de  détente, centre de loisirs.
Seuls   les   parcs   dont   la   superficie   excède   4ha   et   dotés   d’équipements conséquents sont inclus. 
Les       parcs       publics       (jardins,       parcs       communaux,       départementaux...)  sont  exclus  (voir  la  valeur  Espacepublicci-dessus).
- Parc zoologique : Parc  ouvert  au  public,  où  il  est  possible  de  voir  des  animaux  sauvages vivant en captivité ou en semi-liberté.
Tous les parcs ouverts au public sont inclus.
- Refuge : Refuge, refuge gardé, abri de montagne nommé.
- Vestiges archéologiques : Vestiges archéologiques, fouilles, tumulus, oppidum.
- Village de vacances : Établissement   de   vacances,   comprenant   des   équipements   sportifs ou de détente conséquents dont le gestionnaire est privé ou public : village de vacances, colonie de vacances. 
Les  hôtels  et  les  « camps  de  vacances»  sont  exclus,  ainsi  que  les  établissementsdont  la  capacité  de  prise  en  charge  est  inférieure à 300 personnes.
- NR :  
Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt espace naturel de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation  d’un  lieu-dit  non  habité  dont  le  nom  se  rapporte  ni  à  un  détail  orographique ni à un détail hydrographique.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Arbre : Arbre nommé isolé, arbre remarquable.
- Bois : Bois ou forêt.
- Lieu-dit non habité : Lieu-dit quelconque,  dont  le  nom  est  généralement  attaché  à  des terres : lieu-dit non habité, plantation, espace cultivé.
- Parc : Espace réglementé, généralement libre d’accès pour le public et  où  la  nature  fait  l’objet  d’une  protection  spéciale :  parc  naturel  régional,  parc  national,  réserve  naturelle nationale  ou  régionale, parc naturel marin.
Les parcs à vocation commerciale ne sont pas pris en compte dans cet attribut.
- Pare-feu : Dispositif  destiné  à  empêcher  la  propagation  d’un  incendie  (généralement,  ouverture  pratiquée  dans  le  massif  forestier  menacé).
- Point de vue : Endroit  d’où  l’on  jouit  d’une  vue  pittoresque :  point  de  vue,  table d’orientation, belvédère.
Seuls   les   points   de   vue   aménagés   (table   d’orientation,   bancs,...) sont inclus
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt pour la gestion de l’eau de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation d’une construction ou site liés à l’approvisionnement, au traitement de l’eau pour différents besoins (agricole, industriel, consommation) ou à l’épuration des eaux usées avant rejet dans la nature.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Station de pompage : Site  incluant  au  moins  une  construction  abritant  une  installation  de  captage  ou  de  pompage  des  eaux : captage, pompage pour besoins agricole ou industriel, pompage pour production eau potable.
Toutes    les    stations    de    pompage    servant    à    l’alimentation  en  eau  potable  d’une  collectivité  sont  incluses.
- Usine de traitement des eaux : Établissement  comprenant  des  installations  destinées  à  rendre  l’eau  propre  à  la  consommation  (usine  de  traitement  des  eaux)  ou  à  épurer  des  eaux  usées  avant  leur  rejet  dans  la  nature  (stations  d’épuration,  de  lagunage) :  usine  de  traitement  des  eaux,  station  d’épuration, station de lagunage.
Les stations d’épuration et de lagunage sont incluses. Les stations traitant l’eau afin de la rendre propre à la consommation sont incluses lorsqu’elles comprennent des  installations  conséquentes  (usines  comprenant  bassins, filtrages, traitements mécaniques).
Sont  exclues  les  stations  lorsqu’il  s’agit  uniquement  d’un traitement chimique d’appoint effectué au niveau d’un captage ou d’un réservoir. 
Les stations de relèvement sont également exclues.
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt hydrographique de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation se rapportant à un détail hydrographique.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Amer : Point  de  repère  visible  de  la mer:  amer,  bouée,  balise,  phare,  feu,  tourelle.
- Baie : Espace marin pénétrant entre les terres : anse, baie, calanque, crique, golfe.
- Banc : En  mer  ou  sur  un  fleuve,  relief  sous-marin  non  rocheux  représentant  un danger potentiel pour la navigation : banc, hauts-fonds.
- Cascade : Cascade, chute d’eau
- Embouchure : Embouchure d’un fleuve : delta, embouchure, estuaire.
- Espace maritime : Espace maritime, mer, océan, passe.
- Glacier : Nom  d’un  glacier  ou  d’un  détail  relatif  à  un  glacier :  crevasse,  glacier,  moraine,  névé, sérac.
- Lac : Étendue d’eau terrestre : bassin, étang, lac, mare.
- Marais : Zone humide : marais, marécage, saline.
- Perte : Lieu où disparaît, où se perd un cours d’eau, qui réapparaît ensuite, en formant une résurgence, après avoir effectué un trajet souterrain. 
- Point d’eau : Tout  point  d’eau  naturel  ou  artificiel :  citerne,  fontaine,  lavoir, puits, résurgence, source, source captée. 
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt industriel et commercial de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation d’un bâtiment, site ou zone à caractère industriel ou commercial.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Aquaculture : Site aménagé pour l’élevage piscicole ou la culture d’espèces animales  marines  (coques,  coquilles  Saint-Jacques,  huîtres,  moules,   palourdes,...):   bouchot,   parc   à   huîtres,   zone   conchylicole, zone mytilicole, zone ostréicole.
Toutes les zones de plus de 3 ha possédant des installations fixes de pêche et délimitées par des alignements de pieux, les parcs à huîtres, les bassins.
Les installations de pêche au carrelet sont exclues.
- Carrière : Lieu   d’où   l’on   extrait   à   ciel   ouvert   des   matériaux   de   construction  (pierre,  roche):  carrière,  sablière,  ballastière,  gravière.
Toutes  les  carrières  de  plus  de  3  ha  en  exploitation  sont  incluses.
La  définition  de  l’enceinte  s’appuie  sur  les  fronts  de  taille (voir aussi la classe LIGNE_OROGRAPHIQUE) et sur la zone d’exploitation visible sur les photographies aériennes.
- Centrale électrique : Usine   où   l’on   produit   de   l’énergie   électrique : centrale   hydroélectrique,  centrale  thermique,  centrale  nucléaire,  parc  éolien, centrale photovoltaïque.
Les centrales électriques souterraines sont exclues.
- Divers commercial : Bâtiment  ou  zone  à  caractère  commercial:  hypermarché,  grand    magasin,    centre    commercial,    zone    à    caractère    commercial.
Au  moins  tous  les  sites  incluant  un  « grand  magasin 
»,  un  
hypermarché, ou une zone d’activité commerciale d’au moins 5 ha. Les hypermarchés isolés ayant une surface de vente de plus   de   4000 m2 sont   inclus.   (voir   également   la   valeur   d’attribut Marché ci-dessous).
- Divers industriel : Organisme  ou  entreprise  à  caractère  industriel  non  distingué  de façon spécifique : centre de recherche, dépôt, coopérative (vinicole,   céréalière...),   élevage   avicole,   haras,   abattoir,   déchèterie.
Tous  les  sites  d’importance  ou  de  notoriété  nationale  ou  régionale,   confirmée   par   un   toponyme,   et   de   surface   supérieure   à   3   ha   sont   retenus   (le   toponyme   n’est   pas   nécessairement retenu).
- Haras national : Lieu  ou  établissement  destiné  à  la  reproduction  de  l’espèce  chevaline,   à   l’amélioration   des   races   de   chevaux   par   la   sélection des étalons. Tous les haras nationaux sont inclus.
L’enceinte  comprend  l’ensemble  des  installations  (manège,  écuries, piste d’entraînement,...).
- Marais salants : Zone  constituée  de  bassins  creusés  à  proximité  des  côtes  pour extraire le sel de l’eau de mer par évaporation.
Les  zones  de  marais  salants  de  moins  de  3  ha  sont  exclues.  Les  anciens  marais  salants  qui  ne  sont  plus  en  activité  sont  exclus.
- Marché : Tout     ensemble     construit     dont     la     finalité     est     la     commercialisation    de    gros    ou    de    détail    de    denrées    alimentaires:   marché   couvert,   marché   d’intérêt   national,   marché  d’intérêt  régional,  halle,  foire,  zone  d’exposition  à  caractère permanent, criée couverte.
- Mine : Lieu  d’où  l’on  extrait  des  minerais :  mine  de  houille,  mine  de  lignite, crassier, entrée de mine, terril.
Les mines à ciel ouvert de plus de 10 ha sont incluses.  Les mines souterraines sont exclues.
- Usine : Établissement  dominé  par  une  activité  industrielle  (fabrication  d’objets  ou  de  produits,  transformation  ou  conservation  de  matières   premières):   atelier,   fabrique,   manufacture,   mine   avec infrastructure bâtie, usine, scierie.
Les   sites   dont   la   superficie   est   inférieure   à   5   ha   sont   généralement exclus.
- Zone industrielle : Regroupement  d’activités  de  production  sur  l’initiative  des  collectivités  locales  ou  d’organismes  parapublics  (chambres  de   commerce   et   d’industrie)   et   portant   un   nom : zone artisanale, zone industrielle.
Les   sites   dont   la   superficie   est   inférieure   à   5   ha   sont généralement exclus
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt orographique de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation d’un détail du relief.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Cap : Prédominance dans le contour d’une côte : cap, pointe, promontoire.
- Cirque : Dépression semi-circulaire, à bords raides.
- Col : Point de passage imposé par la configuration du relief : col, passage.
- Crête : Ligne de partage des eaux : crête, arête, ligne de faîte.
- Dépression : Dépression naturelle du sol : cuvette, bassin fermé, dépression, doline.
- Dune : Monticule de sable sur les bords de la mer.
- Escarpement : Escarpement  du  relief :  barre  rocheuse,  escarpement  rocheux,  face abrupte, falaise.
- Gorge : Vallée étroite et encaissée : canyon, cluse, défilé, gorge.
- Grotte : Grotte naturelle ou excavation : aven, cave, gouffre, grotte.
- Ile : Île, îlot ou presqu’île.
- Isthme : Bande de terre étroite entre deux mers, réunissant deux terres : cordon littoral, isthme.
- Montagne : Désigne  une  montagne  ou  un  massif  de  manière  globale  et  non  un  sommet en particulier (voir sommet).
- Pic : Sommet pointu d’une montagne : aiguille, pic, piton. 
- Plage : Zone littorale marquée par le flux et le reflux des marées : grève, plage.
- Plaine : Zone de surface terrestre caractérisée par une relative planéité : plaine, plateau.
- Récif : Rocher   situé   en   mer   ou   dans   un   fleuve,   mais   dont   une   partie, faiblement émergée, peut constituer un obstacle ou un repère : brisant, récif, rocher marin.
- Rochers : Zone ou détail caractérisé par une nature rocheuse mais non verticale : chaos, éboulis, pierrier, rocher.
- Sommet : Point  haut  du  relief  non  caractérisé  par  un  profil  abrupt  (voir  la  nature  Pic)  : colline, mamelon, mont, sommet.
- Vallée : Espace  entre  deux  ou  plusieurs  montagnes. Forme  définie  par  la  convergence  des  versants  et  qui  est,  ou  a  été  parcourue  par  un  cours  d’eau : combe, ravin, val, vallée, vallon, thalweg.
- Versant : Plan incliné joignant une ligne de crête à un thalweg : coteau, versant.
- Volcan : Toute  forme  de  relief  témoignant  d’une  activité  volcanique :  cratère,  volcan.
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt religieu de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation d’un bâtiment réservé à la pratique d’une religion.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Croix : Monument religieux : croix, calvaire, vierge, statue religieuse.
- Culte catholique ou orthodoxe : Bâtiment   réservé   à   l’exercice   du   culte   catholique   ou   orthodoxe :  église,  cathédrale,  basilique,  chapelle,  abbaye,  oratoire.
- Culte protestant : Bâtiment  réservé  à  l’exercice  du  culte  protestant:  temple  (protestant), église réformée.
- Culte israélite : Bâtiment réservé à l’exercice du culte israélite : synagogue.
- Culte islamique : Bâtiment réservé à l’exercice du culte islamique : mosquée.
- Culte divers : Bâtiment  réservé  à  l’exercice  d’un  culte  religieux  autre  que  chrétien,  islamique  ou  israélite :  temple  bouddhiste,  temple  hindouiste.
- Tombeau : Cimetière,  tombe  ou  tombeau  nommé :  cimetière,  tombe,  tombeau, ossuaire.
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt de santé de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation d’un établissement thermal ou de type hospitalier.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Etablissement hospitalier : Autres    établissements    relevant    de    la    loi    hospitalière : sanatorium,  aérium,hospice,  maison  de  retraite  (MAPA  et  EHPA), établissements de convalescence ou de repos.
Tous  les  établissements  assurant  les  soins  et  l’hébergement  ou les soins seulement sont inclus.
- Etablissement thermal
Établissement   où   l’on   utilise   les   eaux   médicinales   (eaux   minérales,  chaudes  ou  non):  établissement  thermal,  centre  de thalassothérapie.
Seuls  sont  inclus  les  établissements  agréés  par  la  Sécurité  Sociale.
- Hôpital : Établissement public ou privé, où sont effectués tous les soins médicaux  et  chirurgicauxlourds  et/ou  de  longue  durée,  ainsi  que  les  accouchements:  centre  hospitalier,  hôpital,  hôpital  psychiatrique, CHU, hôpital militaire, clinique.
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt de santé de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation d’un établissement d’enseignement ou de recherche.

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Enseignement primaire : Établissement    consacré    à    l’enseignement    maternel    et  primaire:  école  primaire,  école  maternelle,  groupe  scolaire,  Institut Médico-Pédagogique (I.M.P.).
Tous  les  établissements  d’enseignement  primaire,  publics,  confessionnels   ou   privés,   ayant   un   contrat   simple   ou   d’association avec l’État sont inclus. Les crèches sont exclues.
- Enseignement secondaire : Établissement    consacré    à    l’enseignement    secondaire : collège, lycée.
Tous  les  établissements  d’enseignement  secondaire  publics,  confessionnels   ou   privés,   ayant   un   contrat   simple   ou   d’association avec l’État sont inclus.
- Enseignement supérieur : Établissement  consacré  à  l’enseignement  supérieur:  faculté,  centre universitaire, institut, grande école, ...
Tous  les  établissements  d’enseignement  supérieur  publics,  confessionnels   ou   privés,   ayant   un   contrat   simple   ou   d’association avec l’État sont inclus. 
Les  cours  du  soir,  les  cités  et  les  restaurants  universitaires  sont exclus.
- Science : Établissement  scientifique  ou  technique  nommé  :  centre  de  recherche, laboratoire, observatoire, station scientifique.
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt transport de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation  d’un établissement ou lieu spécialement aménagé pour la pratique d’une ou de plusieurs activités sportives. 

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Golf :Terrain ouvert au public et consacré à la pratique du golf.  
Les terrains de moins de 6 trous et les minigolfs sont exclus. 
- Hippodrome : Lieu  ouvert  au  public  et  consacré  aux  courses  de  chevaux. 
Seuls  les  hippodromes  possédant  des  aménagements conséquents (tribunes, bâtiments spécifiques) sont inclus. 
- Piscine : Grand  bassin  de  natation,  et  ensemble  des  installations  qui l’entourent : piscine couverte, piscine découverte. 
Toutes les piscines ouvertes au public et ayant un bassin au moins de 25 m ou plus sont incluses.  
Les  piscines  des  centres  de  vacances  ou  des  hôtels  sont exclues (voir la classe TERRAIN_SPORT). 
- Stade : Grande enceinte, terrain aménagé pour la pratique des sports, et  le  plus  souvent  entouré  de  gradins,  de  tribunes :  stade, terrain  de  sports,  vélodrome  découvert,  circuit  auto-moto, complexe sportif pluridisciplinaire. 
Seules  les  enceintes  incluant  des  aménagements conséquents (piste « construite », tribunes,…) sont incluses. 
Les terrains d’entraînement incluant seulement 2 ou 3 terrains de  football  et  de  petits  vestiaires  sont  exclus  (voir  aussi  la classe TERRAIN_SPORT) 
- NR : Non renseignée, l’information est manquante dans la base.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt zone d’habitation de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation  d’un établissement ou lieu spécialement aménagé pour la pratique d’une ou de plusieurs activités sportives. 

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Aérodrome militaire : Tout terrain ou plan d’eau réservés à l’armée spécialement aménagé pour l’atterrissage, le décollage et les manœuvres des  aéronefs  y  compris  les  installations  annexes  qu’il  peut comporter  pour  les  besoins  du  trafic  et  le  service  des aéronefs : aérodrome militaire, héliport militaire. 
- Aérodrome non militaire : Tout  terrain  ou  plan  d’eau  spécialement  aménagé  pour l’atterrissage, le décollage et les manœuvres des aéronefs y compris  les  installations  annexes  qu’il  peut  comporter  pour les  besoins  du  trafic  et  le  service  des  aéronefs  : altiport, aérodrome non militaire, héliport.  
Ne  sont  pas  pris  en  compte  les  aéro-clubs,  les  terrains  de vol à voile, les pistes d’ULM. 
- Aéroport international : Aérodrome de statut international sur lequel ont été prévues des  installations  en  vue  de  l’abri,  de  l’entretien  ou  de  la répartition  des  aéronefs,  ainsi  que  pour  la  réception, l’embarquement  et  le  débarquement  des  passagers,  le chargement et le déchargement des marchandises. 
- Aéroport quelconque : Aérodrome  sur  lequel  ont  été  prévues  des  installations  en vue de l’abri, de l’entretien ou de la répartition des aéronefs, ainsi  que  pour  la  réception,  l’embarquement  et  le débarquement  des  passagers,  le  chargement  et  le déchargement des marchandises. 
- Aire de service : Espace  aménagé  à  l’écart  des  chaussées,  notamment  des autoroutes, pour permettre aux usagers de se ravitailler en carburant. 
Emprise de l’aire. Les contours de la surface ne s’appuient jamais sur des tronçons de route (qui représentent l’axe des chaussées). 
- Aire de repos : Espace  aménagé  (présence  d’un  point  d’eau  obligatoire)  à l‘écart  des  chaussées,  notamment  des  autoroutes,  pour permettre aux usagers de s’arrêter et de se reposer. 
Emprise de l’aire. Les contours de la surface ne s’appuient jamais sur des tronçons de route qui représentent l’axe des chaussées. 
- Barrage : Obstacle  artificiel  placé  en  travers  d’un  cours  d’eau : barrage, écluse, vanne. 
- Carrefour : Nœud du réseau routier : carrefour nommé. 
- Echangeur : Échangeur autoroutier portant un nom ou un numéro. 
- Gare routière : Ensemble  des  installations  destinées  à  l’embarquement  et au  débarquement  de  voyageurs  en  car  ou  en  bus  en  un point déterminé. 
Ne  sont  pas  retenues  les  gares  routières  des  bus  de  ville, des bus scolaires, de la RATP et les dépôts de bus. 
- Gare voyageurs uniquement : Établissement ferroviaire ou de transport par câble assurant avec  ou  sans  personnel  un  service  commercial  de voyageurs :  gare,  station,  point  d’arrêt,  station  réseau  ferré urbain, gare téléphérique. 
Toutes les gares et arrêts ferroviaires en service sont inclus. Modélisation géométrique : Point centré sur la gare ou sur la ligne ferroviaire dans le cas d’un arrêt. 
- Gare voyageurs et fret : Établissement ferroviaire assurant un service commercial de voyageurs et de marchandises. (Uniquement le bâtiment principal ouvert au public.) 
- Gare fret uniquement : Établissement ferroviaire assurant un service commercial de marchandises : gare de fret, point de desserte. Le fret aérien ou maritime est exclu. 
- Parking : Une  aire  de  stationnement  ou  parking  est  une  zone aménagée  pour  le  stationnement  des  véhicules :  aire  de stationnement, parking, parking souterrain, parking à étages. 
Tous  les  parkings  publics  nommés  de  plus  de  100  places sont inclus qu’ils soient souterrains ou aériens (ex. parkings municipaux), Les parkings de plus de 100 places associés à des  services  de  transport  (gares,  aéroports)  sont  retenus même s’ils n’ont pas de nom propre. 
Les  parkings  d’aires  de  repos  ou  de  service  ne  sont  pas retenus  (voir  les  valeurs  <Aire  de  repos>  et  <Aire  de service>). 
Les  parkings  appartenant  à  des  établissements  purement commerciaux  (ex :  parking  de  supermarché)  sont  exclus (pour ces derniers, voir aussi la classe SURFACE_ROUTE). 
Un Parking est un objet ponctuel situé au centre de l’aire de stationnement, ou à l’entrée pour les parkings souterrains. Il est généralement associé à une surface pour des parkings aériens de plus de 5 ha.
- Péage : Barrière  de  péage.  Toutes  les  barrières  de  péage  sont représentées,  qu’elles  soient  ou  non  accompagnées  d’un élargissement  de  la  chaussée  ou  d’un  bâtiment :  péage d’autoroute, de pont, de route. 
Si aucun objet de la base n’est associé au péage (ni surface de route ni bâtiment), le point d’activité est saisi sur l’axe de la route au niveau de la barrière de péage.
Le  péage  est  modélisé  par  une  surface  incluant  tous  les objets  associés  à  cette  fonction :  SURFACE_ROUTE BATI_REMARQUABLE ou les deux. 
- Pont : Ouvrage d’art permettant le franchissement d’une vallée ou d’une voie de communication : pont, passerelle, viaduc, gué, pont mobile. 
Seuls les ponts nommés sont saisis. 
- Port : Abri naturel ou artificiel aménagé pour recevoir les navires, pour  l’embarquement  et  le  débarquement  de  leur chargement : port de plaisance, port de pêche, port national, port privé, port international, port militaire. 
- Rond-point : Rond-point,  place  de  forme  circulaire,  ovale  ou  semi-circulaire, ou carrefour giratoire. Un giratoire est formé d’un anneau central qui permet aux usagers de prendre n’importe quelle direction, y compris de faire un demi-tour. 
Seuls les ronds-points nommés sont retenus. 
- Station de métro : Station où il est possible d’accéder à un réseau de métro ou de tramway : station de métro, arrêt de tramway.
On  saisit  un  seul  objet  "Station  de  métro"  même  s’il  y  a plusieurs  entrées  distinctes,  éventuellement  plusieurs ponctuels  "Station  de  métro"  pour  les  correspondances importantes  (ex :  Bastille) mais  un  seul  ponctuel  pour  une station de métro qui n’est pas une correspondance. 
- Téléphérique : Système de transport à traction par câble nommé : remonte-pente, télécabine, télésiège, téléphérique, téléski. 
- Tunnel : Tunnel nommé. 
- Voie ferrée : Voie ferrée nommée 
- NR : Non renseignée, l’information est manquante dans la base. 
Aire d’accueil des gens du voyage, passage à niveau.

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Point d’intérêt du sport de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Désignation  d’un établissement ou lieu spécialement aménagé pour la pratique d’une ou de plusieurs activités sportives. 

Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Château : Château ou tour. Le lieu-dit, toujours nommé, peut ne pas être habité  ou  ne  plus  être  habité  mais  n’est  pas  totalement  en ruines. 
- Grange : Construction  légère :  abri,  baraquement,  cabane,  grange, hangar. 
Voir également la classe CONSTRUCTION_LEGERE. 
- Lieu-dit habité : Groupe d’habitations nommé situé en dehors du chef-lieu de commune :  hameau,  habitation  isolée,  ancien  chef-lieu  de commune. 
- Moulin : Moulin ou ancien moulin à eau. 
- Quartier : Quartier nommé : cité, faubourg, lotissement. 
- Ruines : Bâtiment ou construction en ruines. 
- NR : Non renseignée, l’information est manquante dans la base.  

Modélisation  géométrique  :  Au  centre  de  l’objet  ponctuel,  du  bâtiment  ou  au  centroïde  de  la  zone d’activité.

Commentaires : La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité  particulière (notamment à travers un toponyme éventuel).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine du PAI'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.toponyme IS ''Nom'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du toponyme'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Surface d’activité de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Définition : Enceinte  d’un  équipement  public,  d’un  site  ou  d’une  zone  ayant  un  caractère administratif, culturel, sportif, industriel ou commercial. 

Sélection : Les sites ayant perdu leur fonction administrative, industrielle ou commerciale sont exclus (ancienne école, ancienne carrière, …). 
Les enceintes limitées à un seul bâtiment sont exclues. 
En général, la surface minimum pour une enceinte est de l’ordre de 1000m2. 
 
Modélisation géométrique : Limite apparente du site, seulement indicative. 
La  géométrie  de  l’enceinte  ne  saurait,  en  aucun  cas,  donner  la  limite  de  propriété  foncière  de l’organisme  décrit.  La  prise  en  compte  de  toute  institution  ou  organisme  exclut  la  publicité particulière (notamment à travers un toponyme éventuel). 
Toute surface d’activité contient un point d’activité ou d’intérêt mais un point d’activité ou d’intérêt ne  se  rapporte  pas  nécessairement  à  une  surface  qui  est  indicative  et  doit  répondre  à  des critères de sélection.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du PAI.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origine IS ''Origine de la surface d’activité '';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.categorie IS ''Catégorie ou fonction de la surface d’activité '';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Lieu-dit habité de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Château : Château ou tour. Le lieu-dit, toujours nommé, peut ne pas être habité  ou  ne  plus  être  habité  mais  n’est  pas  totalement  en ruines. 
- Grange : Construction  légère :  abri,  baraquement,  cabane,  grange, hangar. 
- Lieu-dit habité : Groupe d’habitations nommé situé en dehors du chef-lieu de commune :  hameau,  habitation  isolée,  ancien  chef-lieu  de commune. 
- Moulin : Moulin ou ancien moulin à eau. 
- Quartier : Quartier nommé : cité, faubourg, lotissement. 
- Ruines : Bâtiment ou construction en ruines.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du lieu-dit.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du lieu-dit habité'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Lieu-dit non habité de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sélection : Voir les différentes valeurs de l’attribut NATURE : 
- Barrage : Obstacle  artificiel  placé  en  travers  d’un  cours  d’eau :  barrage, écluse, vanne. 
- Croix : Monument religieux : croix, calvaire, vierge, statue religieuse. 
- Digue : Digue, môle, jetée. 
- Dolmen : Monument mégalithique formé d’une grande pierre plate posée sur d’autres pierres dressées verticalement. Les allées couvertes sont incluses. 
- Espace public : Large  espace  découvert  urbain  désigné  par  un  toponyme  où aboutissent  plusieurs  rues,  fermé  à  la  circulation  automobile, constituant  un  lieu  remarquable :  place,  square,  jardin,  parc, parc communal, parc intercommunal, parc départemental, parc interdépartemental. 
Seuls  les  espaces  publics  possédant  un  toponyme  sont retenus.  Les  parcs  à  vocation  commerciale  sont  exclus,  de même que les parcs naturels (réserves, parcs nationaux, parcs naturels régionaux) qui sont traités en PAI_ESPACE_NATUREL. 
- Habitation troglodytique : Excavation naturelle ou creusée  dans  le roc (caverne, grotte), habitée ou anciennement habitée. 
- Lieu-dit non habité : Lieu-dit quelconque, dont le nom est généralement attaché à des terres : lieu-dit non habité, plantation, espace cultivé. 
- Marais salants : Zone constituée de bassins creusés à proximité des côtes pour extraire le sel de l’eau de mer par évaporation. 
Les  zones  de  marais  salants  de  moins  de  3  ha  sont  exclues. Les  anciens  marais  salants  qui  ne  sont  plus  en  activité  sont exclus. 
- Mine : Lieu  d’où  l’on  extrait  des  minerais :  mine  de  houille,  mine  de lignite, crassier, entrée de mine, terril. 
Les mines à ciel ouvert de plus de 10 ha sont incluses.  Les mines souterraines sont exclues. 
- Ouvrage : militaire  Ouvrages et installations militaires. 
- Point de vue : Endroit d’où l’on jouit d’une vue pittoresque : point de vue, table d’orientation, belvédère. 
Seuls  les  points  de  vue  aménagés  (table  d’orientation, bancs,…) sont inclus 
- Tombeau : Cimetière,  tombe  ou  tombeau  nommé :  cimetière,  tombe, tombeau, ossuaire. 
- Vestiges archéologiques : Vestiges archéologiques, fouilles, tumulus, oppidum.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du lieu-dit.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du lieu-dit habité'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
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
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' IS ''Toponyme divers de la BDTOPO® v2.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Toponyme de nature diverse, désignant un bâtiment administratif, ou bien une école, un détail religieux, un établissement de santé…etc. 

Voir les valeurs de l’attribut NATURE : 
- Aérodrome militaire : Tout  terrain  ou  plan  d’eau  réservés  à  l’armée  spécialement aménagé  pour  l’atterrissage,  le  décollage  et  les  manœuvres des  aéronefs  y  compris  les  installations  annexes  qu’il  peut comporter pour les besoins du trafic et le service des aéronefs : aérodrome militaire, héliport militaire. 
- Aérodrome non militaire : Tout  terrain  ou  plan  d’eau  spécialement  aménagé  pour l’atterrissage,  le  décollage  et  les  manœuvres  des  aéronefs  y compris les installations annexes qu’il peut comporter pour les besoins du trafic et le service des aéronefs : altiport, aérodrome non militaire, héliport. 
Ne sont pas pris en compte les aéro-clubs, les terrains de vol à voile, les pistes d’ULM. 
- Aéroport international : Aérodrome  de  statut  international  sur  lequel  ont  été  prévues des  installations  en  vue  de  l’abri,  de  l’entretien  ou  de  la répartition  des  aéronefs,  ainsi  que  pour  la  réception, l’embarquement  et  le  débarquement  des  passagers,  le chargement et le déchargement des marchandises. 
- Aéroport quelconque : Aérodrome sur lequel ont été prévues des installations en vue de  l’abri,  de  l’entretien  ou  de  la  répartition  des  aéronefs,  ainsi que pour la réception, l’embarquement et le débarquement des passagers,  le  chargement  et  le  déchargement  des marchandises. 
- Arbre : Arbre nommé isolé, arbre remarquable. 
- Bois : Bois ou forêt. 
- Camping : Emplacement  aménagé  pour  la  pratique  du  camping  d’une superficie de plus de 2 ha. 
- Centrale électrique : Usine  où  l’on  produit  de  l’énergie  électrique :  centrale hydroélectrique,  centrale  thermique,  centrale  nucléaire,  parc éolien, centrale photovoltaïque. 
Les centrales électriques souterraines sont exclues. 
- Construction : Construction  nommée  habitée  ou  associée  à  un  groupe d’habitations : construction diverse, pigeonnier, moulin à vent. 
- Enceinte militaire : Zone  en  permanence  réservée  pour  les  rassemblements  de troupes  de  toutes  les  armes,  soit  pour  des  manœuvres,  des exercices  (camp  d’instruction),  soit  pour  des  essais,  des études :  base,  camp,  caserne,  dépôt  de  matériels,  terrain permanent  d’entraînement,  caserne  de  CRS,  caserne  de gendarmes mobiles, … 
Les  champs  de  tir  sont  exclus  ainsi  que  les  propriétés  de l’armée  qui  ne  sont  indiquées  d’aucune  manière  sur  le  terrain (ni  clôtures,  ni  barrière,  ni  pancartes,…)  et  ne  faisant  l’objet d’aucune restriction particulière.  
- Enseignement supérieur : Établissement  consacré  à  l’enseignement  supérieur :  faculté, centre universitaire, institut, grande école, … 
Tous  les  établissements  d’enseignement  supérieur  publics, confessionnels  ou  privés,  ayant  un  contrat  simple  ou d’association avec l’État sont inclus.  
Les cours du soir, les cités et les restaurants universitaires sont exclus. 
- Etablissement hospitalier : Autres  établissements  relevant  de  la  loi  hospitalière : sanatorium,  aérium,  hospice,  maison  de  retraite  (MAPA  et EHPA), établissements de convalescence ou de repos. 
Tous les établissements assurant les soins et l’hébergement ou les soins seulement sont inclus. 
- Etablissement pénitentiaire : Établissement  clos  aménagé  pour  recevoir  des  délinquants condamnés à une peine privative de liberté ou des détenus en instance de jugement : maison d’arrêt, prison. 
Les annexes sont exclues. 
- Etablissement thermal : Établissement  où  l’on  utilise  les  eaux  médicinales  (eaux minérales, chaudes ou non) : établissement thermal, centre de thalassothérapie. 
Seuls  sont  inclus  les  établissements  agréés  par  la  Sécurité Sociale. 
- Golf : Terrain ouvert au public et consacré à la pratique du golf.  
Les terrains de moins de 6 trous et les minigolfs sont exclus. 
- Haras national : Lieu  ou  établissement  destiné  à  la  reproduction  de  l’espèce chevaline,  à  l’amélioration  des  races  de  chevaux  par  la sélection des étalons. Tous les haras nationaux sont inclus. 
L’enceinte  comprend  l’ensemble  des  installations  (manège, écuries, piste d’entraînement,…). 
- Hippodrome : Lieu  ouvert  au  public  et  consacré  aux  courses  de  chevaux. Seuls  les  hippodromes  possédant  des  aménagements conséquents (tribunes, bâtiments spécifiques) sont inclus. 
- Hôpital : Établissement public ou privé, où sont effectués tous les soins médicaux  et  chirurgicaux  lourds  et/ou  de  longue  durée,  ainsi que  les  accouchements :  centre  hospitalier,  hôpital,  hôpital psychiatrique, CHU, hôpital militaire, clinique. 
- Maison du parc : Bâtiment  ouvert  au  public  et  géré  par  un  Parc  National  ou Régional. 
- Maison forestière : Maison gérée par l’office national des forêts. Les  maisons  de  garde  occupées  par  au  moins  un  agent  de l’ONF sont incluses.  
Les bureaux de l’ONF, les domiciles d’agents servant aussi de bureau,  sont  exclus  lorsqu’ils  ne  sont  pas  situés  dans  une maison forestière. 
- Menhir : Pierre allongée, dressée verticalement. Les alignements en cromlech sont inclus. 
- Monument : Monument  sans  caractère  religieux  particulier :  monument, statue, stèle. 
- Musée : Établissement ouvert au public exposant une grande collection d’objets, de documents, etc., relatifs aux arts et aux sciences et pouvant servir à leur histoire. Sont inclus : 
•  tous les musées contrôlés ou supervisés par le ministère de la Culture (musées nationaux, classés, contrôlés,…) ; 
•  les musées relevant de certains ministères techniques ou de  l’assistance  publique  (musée  de  l’armée,  de  la marine) ; 
•  les  musées  privés  ou  associatifs  ayant  une  grande notoriété ; 
•  les écomusées. 
- Parc : Espace  réglementé,  généralement  libre  d’accès  pour  le  public et où la nature fait l’objet d’une protection spéciale : parc naturel régional, parc national, réserve naturelle nationale ou régionale, parc naturel marin. 
Les parcs à vocation commerciale ne sont pas pris en compte dans cet attribut. 
- Parc de loisirs : Parc  à  caractère  commercial  spécialement  aménagé  pour  les loisirs :  centre  permanent  de  jeux,  parc  d’attraction,  parc  de détente, centre de loisirs. 
Seuls  les  parcs  dont  la  superficie  excède  4  ha  et  dotés d’équipements conséquents sont inclus.  Les  parcs  publics  (jardins,  parcs  communaux, départementaux…) sont exclus. 
 - Parc des expositions : Lieu  d’exposition  ou  de  culture  :  centre  culturel,  parc  des expositions. 
- Parc zoologique : Parc  ouvert  au  public,  où  il  est  possible  de  voir  des  animaux sauvages vivant en captivité ou en semi-liberté. Tous les parcs ouverts au public sont inclus. 
- Science : Établissement  scientifique  ou  technique  nommé  :  centre  de recherche, laboratoire, observatoire, station scientifique. 
- Stade : Grande enceinte, terrain aménagé pour la pratique des sports, et  le  plus  souvent  entouré  de  gradins,  de  tribunes :  stade, terrain  de  sports,  vélodrome  découvert,  circuit  auto-moto, complexe sportif pluridisciplinaire. 
Seules les enceintes incluant des aménagements conséquents (piste « construite », tribunes,…) sont incluses. 
Les terrains d’entraînement incluant seulement 2 ou 3 terrains de football et de petits vestiaires sont exclus. 
- Village de vacances : Établissement  de  vacances,  comprenant  des  équipements sportifs  ou  de  détente  conséquents  dont  le  gestionnaire  est privé ou public : village de vacances, colonie de vacances.  
Les hôtels et les « camps de vacances » sont exclus, ainsi que les  établissements  dont  la  capacité  de  prise  en  charge  est inférieure à 300 personnes. 
- Zone industrielle : Regroupement  d’activités  de  production  sur  l’initiative  des collectivités locales ou d’organismes parapublics (chambres de commerce  et  d’industrie)  et  portant  un  nom : zone  artisanale, zone industrielle. 
Les  sites  dont  la  superficie  est  inférieure  à  5  ha  sont généralement exclus.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.id IS ''Identifiant du lieu-dit.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.origin_nom IS ''Origine du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nom IS ''Nom du lieu-dit habité'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.importance IS ''Importance du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.nature IS ''Nature du lieu-dit'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

ELSE
	req :='La table ' || nom_schema || '.' || nom_table || '_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION w_adl_delegue.set_adm_bdtopo_22(character varying, character varying, character varying)
  OWNER TO postgres;
COMMENT ON FUNCTION w_adl_delegue.set_adm_bdtopo_22(character varying, character varying, character varying) IS '[ADMIN - BDTOPO] - Administration d''un millesime de la BDTOPO 2.2 une fois son import réalisé et les couches mises à la COVADIS

Taches réalisées :
- Suppression des colonnes gid (import via shp2pgsql)
- Ajout d''une clé primaire sur le champs [id]
- Ajout des contraintes
- Commentaires des tables
- Commentaires des colonnes
- Index Géométriques & attributaire

Tables concernées :
n_canalisation_bdt_ddd_aaaa
n_chemin_bdt_ddd_aaaa
n_conduite_bdt_ddd_aaaa
n_contruction_lineaire_bdt_ddd_aaaa
n_ligne_electrique_bdt_ddd_aaaa
n_ligne_orographique_bdt_ddd_aaaa
n_route_bdt_ddd_aaaa
n_route_nommee_bdt_ddd_aaaa
n_route_primaire_bdt_ddd_aaaa
n_route_secondaire_bdt_ddd_aaaa
n_transport_cable_bdt_ddd_aaaa
n_troncon_cours_eau_bdt_ddd_aaaa
n_troncon_voie_ferree_bdt_ddd_aaaa
n_aire_triage_bdt_ddd_aaaa
n_bati_indifferencie_bdt_ddd_aaaa
n_bati_industriel_bdt_ddd_aaaa
n_bati_remarquable_bdt_ddd_aaaa
n_cimetiere_bdt_ddd_aaaa
n_commune_bdt_ddd_aaaa
n_construction_legere_bdt_ddd_aaaa
n_construction_surfacique_bdt_ddd_aaaa
n_gare_bdt_ddd_aaaa
n_piste_aerodrome_bdt_ddd_aaaa
n_poste_transformation_bdt_ddd_aaaa
n_reservoir_bdt_ddd_aaaa
n_reservoir_eau_bdt_ddd_aaaa
n_surface_activite_bdt_ddd_aaaa
n_surface_eau_bdt_ddd_aaaa
n_surface_route_bdt_ddd_aaaa
n_terrain_sport_bdt_ddd_aaaa
n_zone_vegetation_bdt_ddd_aaaa
n_administratif_militaire_bdt_ddd_aaaa
n_chef_lieu_bdt_ddd_aaaa
n_construction_ponctuelle_bdt_ddd_aaaa
n_hydronyme_bdt_ddd_aaaa
n_lieu_dit_habite_bdt_ddd_aaaa
n_lieu_dit_non_habite_ddd_aaaa
n_oronyme_bdt_ddd_aaaa
n_pai_culture_loisirs_bdt_ddd_aaaa
n_pai_espace_naturel_bdt_ddd_aaaa
n_pai_gestion_eaux_bdt_ddd_aaaa
n_pai_hydrographie_bdt_ddd_aaaa
n_pai_industriel_commercial_bdt_ddd_aaaa
n_pai_orographie_bdt_ddd_aaaa
n_pai_religieux_bdt_ddd_aaaa
n_pai_sante_bdt_ddd_aaaa
n_pai_science_enseignement_bdt_ddd_aaaa
n_pai_sport_bdt_ddd_aaaa
n_pai_transport_bdt_ddd_aaaa
n_pai_zone_habitation_bdt_ddd_aaaa
n_point_eau_bdt_ddd_aaaa
n_pylone_bdt_ddd_aaaa
n_toponyme_communication_bdt_ddd_aaaa
n_toponyme_divers_bdt_ddd_aaaa
n_toponyme_ferre_bdt_ddd_aaaa


amélioration à faire :
---- B.3 Ajout de la clef primaire sauf si doublon d''identifiant
---- ajout d''un test de presence du champs gid

dernière MAJ : 25/09/2018';
