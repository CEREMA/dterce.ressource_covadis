CREATE OR REPLACE FUNCTION set_adm_bdcarto(
    nom_schema character varying,
    emprise character varying,
    millesime character varying)
  RETURNS void AS
$BODY$
/*
[ADMIN - BDCARTO] - Administration d'un millesime de la BDCARTO une fois son import réalisé

Taches réalisées :
- Renomage des tables
- Suppression des colonnes gid (import via shp2pgsql)
- Ajout d'une clé primaire sur le champs [id]
- Ajout des contraintes
- Commentaires des tables
- Commentaires des colonnes
- Index Géométriques & attributaire

Tables concernées :
- acces_equipement
- aerodrome
- arrondissement
- cimetiere
- commune
- communication_restreinte
- construction_elevee
- debut_section
- departement
- digue	postgres
- enceinte_militaire
- equipement_routier
- etablissement
- franchissement
- itineraire
- liaison_maritime
- ligne_electrique
- limite_administrative
- massif_boise
- liaison_maritime

amélioration à faire :
---- B.4 Ajout des index attributaires
---- ajout d'un test de présence du champs gid

dernière MAJ : 10/09/2018
*/

DECLARE
object 				text;
r 				record;
req 				text;
veriftable 			character varying;
BEGIN

---- A - Renomage des tables :
FOR object IN
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename NOT LIKE 'n_%'-- and other conditions, if needed
	LOOP
		req :='
		ALTER TABLE '||nom_schema||'.' || object || ' RENAME TO n_' || object || '_bdc_'  || emprise || '_'  || millesime  || ';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- POur le bug de noeud qui n'est slectionné par tablename NOT LIKE 'n_%'
---- ALTER TABLE w_adl.noeud_ferre RENAME TO n_noeud_ferre_bdc_r27_2018;
---- ALTER TABLE w_adl.noeud_routier RENAME TO n_noeud_routier_bdc_r27_2018;
FOR object IN
	SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename LIKE 'noeud_%'
	LOOP
		req :='
		ALTER TABLE '||nom_schema||'.' || object || ' RENAME TO n_' || object || '_bdc_'  || emprise || '_'  || millesime  || ';
		';
		EXECUTE(req);
		RAISE NOTICE '%', req;
	END LOOP;

---- B. Optimisation de la base
---- B.1 Suppression du champs gid créée et de la séquence correspondante
FOR object IN
	SELECT tablename::text from pg_tables where (schemaname LIKE nom_schema) AND right(tablename,4) = millesime
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
FOR r IN SELECT tablename, schemaname from pg_tables where schemaname LIKE nom_schema  AND right(tablename,8) = emprise||'_'||millesime
LOOP 
	req := '
		ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_dims_geom CHECK (ST_NDims(geom)=2);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 

---- Lambert93 (2154)
FOR r IN SELECT tablename, schemaname from pg_tables where schemaname LIKE nom_schema AND right(tablename,8) = emprise||'_'||millesime
LOOP 
	req := '
		ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_srid_geom CHECK (ST_Srid(geom)=2154);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 

---- 'MULTIPOLYGON'
FOR r IN SELECT tablename, schemaname from pg_tables where (schemaname LIKE nom_schema AND right(tablename,8) = emprise||'_'||millesime AND (
tablename LIKE 'n_aerodrome_bdc_%' OR
tablename LIKE 'n_arrondissement_bdc_%' OR
tablename LIKE 'n_cimetiere_bdc_%' OR
tablename LIKE 'n_commune_bdc_%' OR
tablename LIKE 'n_departement_bdc_%' OR
tablename LIKE 'n_enceinte_militaire_bdc_%' OR
tablename LIKE 'n_region_bdc_%' OR
tablename LIKE 'n_surface_hydrographique_bdc_%' OR
tablename LIKE 'n_zone_hydrographique_texture_bdc_%' OR
tablename LIKE 'n_zone_occupation_sol_bdc_%' OR
tablename LIKE 'n_zone_reglementee_touristique_bdc_%'))
LOOP 
	req := '
		ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOLYGON''::text OR geom IS NULL);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 

---- 'MULTILINESTRING'
FOR r IN SELECT tablename, schemaname from pg_tables where (schemaname LIKE nom_schema AND right(tablename,8) = emprise||'_'||millesime AND (
tablename LIKE 'n_debut_section_bdc_%' OR
tablename LIKE 'n_acces_equipement_bdc_%' OR
tablename LIKE 'n_digue_bdc_%' OR
tablename LIKE 'n_itineraire_bdc_%' OR
tablename LIKE 'n_ligne_electrique_bdc_%' OR
tablename LIKE 'n_limite_administrative_bdc_%' OR
tablename LIKE 'n_piste_aerodrome_bdc_%' OR
tablename LIKE 'n_transport_cable_bdc_%' OR
tablename LIKE 'n_troncon_hydrographique_bdc_%' OR
tablename LIKE 'n_troncon_route_bdc_%' OR
tablename LIKE 'n_troncon_voie_ferree_bdc_%'))
LOOP 
	req := '
		ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTILINESTRING''::text OR geom IS NULL);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 

---- 'POINT'
FOR r IN SELECT tablename, schemaname from pg_tables where (schemaname LIKE nom_schema AND right(tablename,8) = emprise||'_'||millesime AND (
tablename LIKE 'n_communication_restreinte_bdc_%' OR
tablename LIKE 'n_construction_elevee_bdc_%' OR
tablename LIKE 'n_equipement_routier_bdc_%' OR
tablename LIKE 'n_etablissement_bdc_%' OR
tablename LIKE 'n_franchissement_bdc_%' OR
tablename LIKE 'n_massif_boise_bdc_%' OR
tablename LIKE 'n_noeud_ferre_bdc_%' OR
tablename LIKE 'n_noeud_routier_bdc_%' OR
tablename LIKE 'n_point_remarquable_relief_bdc_%' OR
tablename LIKE 'n_zone_activite_bdc_%' OR
tablename LIKE 'n_zone_habitat_bdc_%'))
LOOP 
	req := '
		ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''POINT''::text OR geom IS NULL);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 

---- 'MULTIPOINT'
FOR r IN SELECT tablename, schemaname from pg_tables where (schemaname LIKE nom_schema AND right(tablename,8) = emprise||'_'||millesime AND tablename LIKE 'n_ponctuel_hydrographique_bdc_%')
LOOP 
	req := '
		ALTER TABLE ' || r.schemaname || '.' || r.tablename || ' ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ''MULTIPOINT''::text OR geom IS NULL);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 

---- B.3 Ajout de la clef primaire
/*FOR object IN SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND right(tablename,8) = emprise||'_'||millesime
LOOP
	req := '
		ALTER TABLE ' || nom_schema || '.' || object || ' ADD CONSTRAINT ' || object || '_pkey PRIMARY KEY (id);
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
END LOOP; 
*/
---- B.4 Ajout des index spatiaux
    FOR object IN SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND right(tablename,8) = emprise||'_'||millesime
    LOOP
        req := '
	CREATE INDEX ' || object || '_geom_gist ON ' || nom_schema || '.' || object || ' USING gist (geom) TABLESPACE index;
        ALTER TABLE ' || nom_schema || '.' || object || ' CLUSTER ON ' || object || '_geom_gist;
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
    END LOOP;

---- B.5 Ajout des index attributaires


---- B.6 Commentaires
---- B.6.1 n_acces_equipement_bdc

SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_acces_equipement_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,23) = 'n_acces_equipement_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_acces_equipement_bdc_' || emprise || '_' || millesime || ' IS '' Tronçon  de  route  qui permet  d’accéder  à  un  équipement routier de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || ' .'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_acces_equipement_bdc_' || emprise || '_' || millesime || '.id IS ''Définition : Identifiant de l’accès équipement. 
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
 		COMMENT ON COLUMN ' || nom_schema || '.n_acces_equipement_bdc_' || emprise || '_' || millesime || '.id_equipmt IS ''Identifiant de l’équipement routier'';
		COMMENT ON COLUMN ' || nom_schema || '.n_acces_equipement_bdc_' || emprise || '_' || millesime || '.id_troncon IS ''Identifiant du tronçon routier permettant d’accéder à l’équipement.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_acces_equipement_bdc_' || emprise || '_' || millesime || '.cote IS ''Côté du tronçon par lequel on accède à l’équipement.
La  gauche et la droite s’entendent par rapport à l’orientation du tronçon orienté dans le sens des arcs qui le composent.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_acces_equipement_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_acces_equipement_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.2 n_aerodrome_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_aerodrome_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,16) = 'n_aerodrome_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_aerodrome_bdc_' || emprise || '_' || millesime || ' IS ''Aérodromes, aéroports et hydrobases de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || ' .'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_aerodrome_bdc_' || emprise || '_' || millesime || '.id  IS ''Définition : Identifiant de l’aérodrome.
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
		COMMENT ON COLUMN ' || nom_schema || '.n_aerodrome_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de l’aérodrome.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_aerodrome_bdc_' || emprise || '_' || millesime || '.desserte IS ''Desserte de l’aérodrome :
Desservi : Desservi par au moins une ligne régulière de transport de voyageurs
Non desservi : Desservi par aucune ligne régulière de transport de voyageurs'';
		COMMENT ON COLUMN ' || nom_schema || '.n_aerodrome_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à l’aérodrome.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_aerodrome_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_aerodrome_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.3 n_arrondissement_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_arrondissement_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,21) = 'n_arrondissement_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_arrondissement_bdc_' || emprise || '_' || millesime || ' IS ''Arrondissement au sens INSEE de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || ' .
L’arrondissement est du département. Depuis le redécoupage cantonal lié aux élections départementales de mars 2015, l’arrondissement n’est plus un regroupement de cantons mais de communes.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_arrondissement_bdc_' || emprise || '_' || millesime || '.id IS ''Définition : Identifiant de l’arrondissement.
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
		COMMENT ON COLUMN ' || nom_schema || '.n_arrondissement_bdc_' || emprise || '_' || millesime || '.insee_arr IS ''Numéro INSEE de l’arrondissement.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_arrondissement_bdc_' || emprise || '_' || millesime || '.insee_dept IS ''Numéro INSEE du département auquel appartient l’arrondissement.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_arrondissement_bdc_' || emprise || '_' || millesime || '.insee_reg  IS ''Numéro INSEE de la région contenant l’arrondissement.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_arrondissement_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_arrondissement_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.4 n_cimetiere_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_cimetiere_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,16) = 'n_cimetiere_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_cimetiere_bdc_' || emprise || '_' || millesime || ' IS ''Cimetières de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || ' .'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_cimetiere_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du cimetière.
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
		COMMENT ON COLUMN ' || nom_schema || '.n_cimetiere_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature du cimetière.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_cimetiere_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé au cimetière.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_cimetiere_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_cimetiere_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.5 n_commune_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_commune_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_commune_bdc_')) = 'n_commune_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || ' IS ''Plus  petite  subdivision  du  territoire,  administrée  par  un  maire,  des  adjoints  et  un  
conseil municipal de la BDCARTO® pour le millésime ' || millesime || ' et l’emprise ' || emprise || ' .'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la commune.
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.nom_comm IS ''Nom INSEE de la commune (en majuscules non accentuées).'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.insee_comm IS ''Numéro INSEE de la commune.
Une commune nouvelle résultant d’un regroupement de communes préexistantes se voit attribuer le code INSEE de l’ancienne commune désignée comme chef lieu par l’arrêté préfectoral qui l’institue.
En conséquence une commune change de  code INSEE si un arrêté préfectoral modifie son chef-lieu.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.statut IS ''Statut administratif de la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.x_commune IS ''Abscisse d’un point à l’intérieur de la commune (en mètre, dans le système légal de référence correspondant)'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.y_commune IS ''Ordonnée d’un point à l’intérieur de la commune (en mètre, dans le système légal de référence correspondant)'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.superficie IS ''Superficie de la commune en hectares.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.population IS ''Population municipale de la commune en nombre d’habitants (au sens de l’INSEE).
INSEE : Le concept de population municipale est défini par le décret n°2003-485 publié au  Journal Officiel le 8 juin 2003, relatif au recensement de la population. La population municipale comprend les personnes ayant leur résidence habituelle (au sens du décret) sur le territoire de la  commune,  dans  un  logement ou  une  communauté,  les  personnes détenues dans les établissements pénitentiaires de la commune, les personnes sans-abri recensées sur le territoire de la commune et les personnes résidant habituellement dans une habitation mobile recensée sur le territoire de la commune.
Actualité : La population au 1er janvier de l’année « n » correspond à la population légale millésimée de l’année « n-3 ». Elles ont été calculées conformément aux concepts définis dans le décret n° 2003-485 signé le 5 juin 2003. Leur date de référence statistique est le 1er janvier de l’année « n-3 ». Pour les communes ayant changé de statut (fusion, scission, ...) depuis le 1er janvier, la population de la commune correspond aux informations portées à la connaissance de l’IGN par les différents décrets et arrêtés publiés au Journal Officiel.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.insee_arr IS ''Numéro INSEE de l’arrondissement contenant la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.nom_dept IS ''Nom INSEE du département auquel appartient la commune (en majuscules non accentuées).'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.insee_dept IS ''Numéro INSEE du département auquel appartient la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.nom_region IS ''Nom INSEE de la région à laquelle appartient la commune (en majuscules non accentuées).'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.insee_reg IS ''Numéro INSEE de la région contenant la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_commune_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.6 n_communication_restreinte_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_communication_restreinte_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_communication_restreinte_bdc_')) = 'n_communication_restreinte_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || ' IS ''Communication restreintede la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || ' .
Exprime la relation « Deux tronçons de routes communiquent via un nœud routier sous restriction de... ». 
Cette table permet d’exprimer le fait que la communication entre un tronçon routier dit initial et un tronçon routier dit final soit impossible ou soumise à certaines restrictions de poids et/ou de hauteur.
Chaque objet de la classe est localisé sur le nœud routier concerné par cette relation.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la communication restreinte.
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
		COMMENT ON COLUMN ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || '.id_noeud IS ''Identifiant du nœud routier concerné par la relation de communication restreinte.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || '.id_tro_ini IS ''Identifiant du tronçon routier initial concerné par la relation de communication restreinte.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || '.id_tro_fin IS ''Identifiant du tronçon routier final concerné par la relation de communication restreinte.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || '.interdit IS ''Type de restriction.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || '.rest_poids IS ''Poids maximum autorisé en tonne.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || '.rest_haut IS ''Hauteur maximale autorisée en mètre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_communication_restreinte_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;


---- B.6.7 n_construction_elevee_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_construction_elevee_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_construction_elevee_bdc_')) = 'n_construction_elevee_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_construction_elevee_bdc_' || emprise || '_' || millesime || ' IS ''Construction remarquable par sa hauteur de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || ' .
Sont retenues les constructions permanentes à but industriel ou technique d’une hauteur remarquable.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_construction_elevee_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la construction élevée.
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
		COMMENT ON COLUMN ' || nom_schema || '.n_construction_elevee_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de la construction élevée.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_construction_elevee_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_construction_elevee_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.8 n_debut_section_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_debut_section_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_debut_section_bdc_')) = 'n_debut_section_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_debut_section_bdc_' || emprise || '_' || millesime || ' IS ''Début de section de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Une section est un ensemble continu de tronçons de route classée ayant même numéro et même gestionnaire.
L’objet DEBUT_SECTION est localisé sur le premier tronçon de route de chaque section. Le champ SENS donne le sens de parcours de la section par rapport au sens des arcs qui composent l’objet DEBUT_SECTION.
Enfin le champ ID_SEC_SUI donne l’identifiant BD CARTO® du début de section suivant : ceci permet de retrouver l’ordre des sections d’une même route.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_debut_section_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du début de section.
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
		COMMENT ON COLUMN ' || nom_schema || '.n_debut_section_bdc_' || emprise || '_' || millesime || '.gestion IS ''Département ou autre société gestionnaire de la route.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_debut_section_bdc_' || emprise || '_' || millesime || '.sens IS ''Sens de parcours de la section.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_debut_section_bdc_' || emprise || '_' || millesime || '.id_troncon IS ''Identifiant du premier tronçon de la section.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_debut_section_bdc_' || emprise || '_' || millesime || '.id_sec_sui IS ''Identifiant du début de section suivant.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_debut_section_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_debut_section_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;


---- B.6.9 n_departement_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_departement_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_departement_bdc_')) = 'n_departement_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || ' IS ''Département au sens INSEE de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du département.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || '.nom_dept IS ''Nom INSEE du département (en majuscules non accentuées).'';
		COMMENT ON COLUMN ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || '.insee_dept IS ''Numéro INSEE du département.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || '.x_dept IS ''Abscisse d’un point à l’intérieur du département (en mètre, dans le système légal de référence correspondant.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || '.y_dept IS ''Ordonnée d’un point à l’intérieur du département (en mètre, dans le système légal de référence correspondant.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || '.insee_reg IS ''Numéro INSEE de la région contenant le département.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_departement_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.10 n_digue_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_digue_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_digue_bdc_')) = 'n_digue_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_digue_bdc_' || emprise || '_' || millesime || ' IS ''Digue de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
 Cette classe regroupe :
• les digues de barrages d’une longueur supérieure à 200 m ;
• les autres digues d’une longueur supérieure à 500 m.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_digue_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la digue.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
  		COMMENT ON COLUMN ' || nom_schema || '.n_digue_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de la digue.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_digue_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_digue_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.11 n_enceinte_militaire_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_enceinte_militaire_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_enceinte_militaire_bdc_')) = 'n_enceinte_militaire_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_enceinte_militaire_bdc_' || emprise || '_' || millesime || ' IS ''Terrains militaires, champs de tirs et forts de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
 Sont retenus :
• tous les forts et citadelles, démilitarisés ou non ;
• les terrains militaires non entièrement clôturés dans lesquels s’effectuent des exercices ou des manœuvres. Les terrains entièrement clôturés et ceux d’importance régimentaire seulement ne sont pas retenus ;
• les champs de tirs utilisés de façon épisodique et qui restent accessibles en dehors des périodes d’utilisation.
Modélisation : Pour les champs de tirs, la limite retenue dans la BD CARTO® est celle de la zone dangereuse réglementée.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_enceinte_militaire_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de l’enceinte militaire.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_enceinte_militaire_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de l’enceinte militaire.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_enceinte_militaire_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à l’enceinte militaire.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_enceinte_militaire_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_enceinte_militaire_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.12 n_equipement_routier_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_equipement_routier_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_equipement_routier_bdc_')) = 'n_equipement_routier_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_equipement_routier_bdc_' || emprise || '_' || millesime || ' IS ''Equipement routier de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
 Les équipements routiers retenus sont :
• toutes les gares de péage ;
• les aires de repos et de service quand elles se trouvent sur le réseau de type autoroutier ;
• les tunnels routiers de longueur inférieure à 200m s’ils ne correspondent pas à une intersection avec d’autres tronçons des réseaux routiers et ferrés (sinon ce sont des franchissements). Les tunnelsroutiers d’une longueur supérieure à 200m sont représentés  sous forme d’un tronçon de route portant la valeur souterrain pour l’attribut position'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_equipement_routier_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de l’équipement routier.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_equipement_routier_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de l’équipement routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_equipement_routier_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à l’équipement routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_equipement_routier_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_equipement_routier_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.13 n_etablissement_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_etablissement_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_etablissement_bdc_')) = 'n_etablissement_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_etablissement_bdc_' || emprise || '_' || millesime || ' IS ''Etablissement public ou administratif de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Ces établissements sont des bâtiments ou ensembles de bâtiments ayant pour fonction l’équipement technique, administratif, éducatif et sanitaire du territoire.

Dans le cas particulier des franchissements internes au réseau routier, il peut y avoir communication entre les tronçons, mais elle ne se fait pas au niveau du point représentant le franchissement. Elle se fait par l’intermédiaire de bretelles (échangeur).

Dans le cas où un tronçon de route ou de voie ferrée croise un tronçon hydrographique, et que l’un des tronçons est en souterrain (valeur « Souterrain » de l’attribut POS_SOL), on ne peut pas considérer qu’il y a une intersection ; par conséquent, ces tronçons  ne  participent  jamais à un franchissement.

D’autre part, dans la quasi-totalité des cas,les cours d’eau passent au-dessous des routes et des voies ferrées, sans que soit rattachée une information particulière au point de franchissement.

Sont finalement retenus dans la BD CARTO® tous  les  franchissements entre tronçons de route, de voie ferrée ou hydrographique, hormis dans les trois cas suivants : 
• le tronçon hydrographique est au-dessous (cas général) ;
• le tronçon de route est un chemin ou un sentier (valeur « Chemin  d’exploitation » ou « Sentier » de l’attribut ETAT) et le franchissement se fait à gué ;
• le franchissement se fait par un tunnel de moins de 200 mètres de long ; il s’agit alors d’un équipement routier.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_etablissement_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de l’établissement.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_etablissement_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de l’établissement.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_etablissement_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à l’établissement.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_etablissement_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_etablissement_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.14 n_franchissement_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_franchissement_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_franchissement_bdc_')) = 'n_franchissement_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || ' IS ''Franchissement de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Lieu où plusieurs tronçons des réseaux routier, ferré ou hydrographique s’intersectent, sans qu’il n’y ait communication entre ces tronçons.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du franchissement.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé au franchissement.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || '.cote IS ''Altitude en mètre du point haut du franchissement.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || '.type_tron IS ''Type du tronçon passant par le franchissement et décrit par les champs suivants.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || '.id_troncon IS ''Identifiant du tronçon passant par le franchissement et décrit par les champs suivants.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || '.mode IS ''Mode de franchissement. Renseigne sur la nature de l’ouvrage d’art réalisant le franchissement physique pour le tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || '.niveau IS ''Niveau d’empilement du tronçon dans le franchissement.
 Par convention, 0 est le niveau le plus bas et n+1 le niveau immédiatement supérieur à n.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_franchissement_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.15 n_itineraire_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_itineraire_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_itineraire_bdc_')) = 'n_itineraire_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_itineraire_bdc_' || emprise || '_' || millesime || ' IS ''Itinéraire routier de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Un itinéraire routier est un ensemble de parcours continu empruntant des tronçons de route, chemin ou sentier et identifié par un toponyme et/ou un numéro (par exemple pour les routes européennes).

Les itinéraires retenus sont :
• les routes européennes ;
• les parcours routiers portant un nom ainsi que les voies antiques.
Ils ne sont retenus que si leur longueur est supérieure à 20 kilomètres.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_itineraire_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de l’itineraire.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_itineraire_bdc_' || emprise || '_' || millesime || '.numero IS ''Numéro de l’itinéraire routier. Ce champ peut être vide.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_itineraire_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de l’itinéraire routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_itineraire_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à l’itinéraire.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_itineraire_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_itineraire_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.16 n_ligne_electrique_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_ligne_electrique_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_ligne_electrique_bdc_')) = 'n_ligne_electrique_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_ligne_electrique_bdc_' || emprise || '_' || millesime || ' IS ''Ligne électriques de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Partie ou totalité d’une ligne de transport d’énergie électrique, homogène quant au voltage et au type de tracé.
Sont retenus :
• tous les tronçons aériens ;
• les tronçons sous-marins ou souterrains, si leur tracé est communiqué par RTE.

Aucune ligne des réseaux de distribution et de production n’est gérée dans la BD CARTO®.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_ligne_electrique_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la ligne electrique.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_ligne_electrique_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de la ligne electrique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_ligne_electrique_bdc_' || emprise || '_' || millesime || '.tension IS ''Tension de contruction de la ligne electrique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_ligne_electrique_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_ligne_electrique_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.17 n_limite_administrative_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_limite_administrative_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_limite_administrative_bdc_')) = 'n_limite_administrative_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_limite_administrative_bdc_' || emprise || '_' || millesime || ' IS ''Limite administrative de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Portion continue de contour de commune :  Toutes les limites administratives sont retenues.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_limite_administrative_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la limite administrative.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_limite_administrative_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de la limite administrative.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_limite_administrative_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_limite_administrative_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.18 n_massif_boise_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_massif_boise_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_massif_boise_bdc_')) = 'n_massif_boise_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_massif_boise_bdc_' || emprise || '_' || millesime || ' IS ''Toponymes des massifs boisés de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Point repérant un massif boisé.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_massif_boise_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du massif boisé.
Cet identifiant est unique. Il est stable d’une édition à l’autre''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_massif_boise_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé au massif boisé.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_massif_boise_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_massif_boise_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.19 n_noeud_ferre_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_noeud_ferre_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_noeud_ferre_bdc_')) = 'n_noeud_ferre_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_noeud_ferre_bdc_' || emprise || '_' || millesime || ' IS ''Nœud ferré de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Un nœud ferré correspond à un embranchement, à un équipement (gare, etc.) ou à un changement de valeur d’attribut sur un tronçon de voie ferrée.
C’est une extrémité d’un tronçon de voie ferrée.

En plus de la sélection déduite de la sélection des tronçons de voie ferrée, sont retenus :
• les gares SNCF ouvertes aux voyageurs et au fret ;
• les gares SNCF de fret seul ;
• les gares SNCF et points d’arrêt SNCF ouverts aux voyageurs seulement.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_ferre_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du nœud ferré.
Cet identifiant est unique. Il est stable d’une édition à l’autre'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_ferre_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature du nœud ferré.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_ferre_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé au nœud ferré.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_ferre_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_noeud_ferre_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.20 n_noeud_routier_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_noeud_routier_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_noeud_routier_bdc_')) = 'n_noeud_routier_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || ' IS ''Nœud routiers et carefours complexes de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Un nœud routier est une extrémité de tronçon de route. Il traduit donc une modification des conditions de circulation, une intersection, un obstacle ou un changement de valeur d’attribut.
Les carrefours complexes auxquels peuvent appartenir les tronçons routiers sont les échangeurs, les diffuseurs, les carrefours aménagés, les ronds-points, etc.

Il n’y a pas à proprement parler de sélection des nœuds routiers : elle est déduite de celle des tronçons de route et des liaisons maritimes ou de bacs.
Les carrefours aménagés d’une extension supérieure à 100 mètres et les ronds-points d’un diamètre supérieur à 50 mètres sont des nœuds avec une nature spécifique ; si leur extension est inférieure, ils sont considérés comme des carrefours simples.
D’autre part, si leur  extension est supérieure à 100 mètres, ils sont également détaillés en plusieurs carrefours simples au même titre que les échangeurs (ils ont alors 2 descriptions : une généralisée et une détaillée).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du nœud routier.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature du nœud routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuel du nœud routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || '.cote IS '' Altitude en mètre du nœud routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || '.num_carref IS ''Numéro du carrefour complexe auquel peut appartenir le nœud routier. 
Cette  numérotation  concerne  uniquement  les  échangeurs  sur  autoroute,  voies  express 
aux  normes,  et  certaines  routes  nationales  qui  garantissent  la  continuité  des  liaisons 
vertes importantes, plusieurs carrefours complexes peuvent porter le même numéro.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || '.nat_carref IS '' Nature du carrefour complexe auquel peut appartenir le nœud routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || '.top_carref IS '' Toponyme éventuel du carrefour complexe auquel peut appartenir le nœud routier.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_noeud_routier_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.21 n_piste_aerodrome_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_piste_aerodrome_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_piste_aerodrome_bdc_')) = 'n_piste_aerodrome_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_piste_aerodrome_bdc_' || emprise || '_' || millesime || ' IS ''Axes des pistes d’aérodrome de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
 Les pistes principales des aérodromes d’une longueur supérieure ou égale à 1000 mètres et construites en dur sont retenues. '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_piste_aerodrome_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la piste d’aérodrome.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_piste_aerodrome_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_piste_aerodrome_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.22 n_point_remarquable_relief_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_point_remarquable_relief_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_point_remarquable_relief_bdc_')) = 'n_point_remarquable_relief_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || ' IS ''Toponymes des points remarquables du relief de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Elément caractéristique en termes de relief (cap, col, etc.).'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du point remarquable.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature du point remarquable.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || '.cote IS ''Altitude en mètre du point remarquable.
9999 = Cote non renseignée.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuel au point remarquable.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.23 n_ponctuel_hydrographique_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_ponctuel_hydrographique_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_ponctuel_hydrographique_bdc_')) = 'n_ponctuel_hydrographique_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_ponctuel_hydrographique_bdc_' || emprise || '_' || millesime || ' IS ''Nœud hydrographique et point d’eau isolé de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Cette classe regroupe les nœuds hydrographiques et les points d’eau isolés. Un nœud hydrographique correspond à une modification de l’écoulement de l’eau. C’est une extrémité d’un tronçon hydrographique. 
Un  point  d’eau  isolé  correspond  à  un  point  d’eau  non  susceptible  d’être  relié, pour la BD CARTO®, au réseau hydrographique.

Les points d’eau isolés sont : 
•  les réservoirs et châteaux d’eau ; 
•  les stations de pompage et de traitement des eaux. 
 
Les nœuds hydrographiques sont : 
•  les confluences, diffluences, sources, embouchures et pertes de cours d’eau; 
•  tous les barrages de retenue ; 
•  les barrages au fil de l’eau ; 
•  les écluses (pour le passage ou le radoub) ; 
•  les sources et les cascades d’intérêt touristique.''; 
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_ponctuel_hydrographique_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du ponctuel hydrographique.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_ponctuel_hydrographique_bdc_' || emprise || '_' || millesime || '.type IS ''Type de ponctuel hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature du ponctuel hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || '.cote IS ''Altitude en mètre du ponctuel hydrographique(en mètres).
9999 = Cote non renseignée.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuel au ponctuel hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_ponctuel_hydrographique_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_point_remarquable_relief_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;
---- B.6.24 n_region_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_region_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_region_bdc_')) = 'n_region_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_region_bdc_' || emprise || '_' || millesime || ' IS ''Région au sens INSEE de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.''; 
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_region_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la région.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_region_bdc_' || emprise || '_' || millesime || '.nom_region IS ''Nom INSEE de la région (en majuscules non accentuées).'';
		COMMENT ON COLUMN ' || nom_schema || '.n_region_bdc_' || emprise || '_' || millesime || '.insee_reg IS ''Numéro INSEE de la région.
NR : Non renseigné. Le numéro INSEE n’est pas connu (COM).'';
		COMMENT ON COLUMN ' || nom_schema || '.n_region_bdc_' || emprise || '_' || millesime || '.x_region IS ''Abscisse d’un point à l’intérieur de la région (en mètre, dans le système légal de référence correspondant.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_region_bdc_' || emprise || '_' || millesime || '.y_region IS ''Ordonnée d’un point à l’intérieur de la région (en mètre, dans le système légal de référence correspondant.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_region_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_region_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.25 n_surface_hydrographique_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_surface_hydrographique_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_surface_hydrographique_bdc_')) = 'n_surface_hydrographique_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_surface_hydrographique_bdc_' || emprise || '_' || millesime || ' IS ''Surface repérant et décrivant une zone couverte d’eau de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Ces zones sont saisies si elles couvrent une superficie supérieure à 25 hectares.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_surface_hydrographique_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la surface hydrographique.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_surface_hydrographique_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de la surface hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_surface_hydrographique_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à la surface hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_surface_hydrographique_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_surface_hydrographique_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.26 n_transport_cable_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_transport_cable_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_transport_cable_bdc_')) = 'n_transport_cable_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_transport_cable_bdc_' || emprise || '_' || millesime || ' IS '' Transport  par  câble de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Equipements de sport d’hiver (hormis les  funiculaires) destinés au transport des skieurs, équipements de loisirs d’été en montagne, câbles transporteurs à usage privé ou industriel.
 Sont retenus : 
• tous les téléphériques et télécabines ; 
• les télésièges, téléskis et autres câbles transporteurs d’une longueur supérieure ou égale à 1000m.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_transport_cable_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du transport par câble.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_transport_cable_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature du transport par câble.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_transport_cable_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé au transport par câble.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_transport_cable_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_transport_cable_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.27 n_troncon_hydrographique_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_troncon_hydrographique_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_troncon_hydrographique_bdc_')) = 'n_troncon_hydrographique_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || ' IS ''Tronçon hydrographique et cours d’eau de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Portion connexe de rivière, de ruisseau ou de canal, homogène pour les attributs qu’elle porte et les relations la mettant en jeu. 
Un tronçon correspond à l’axe du lit du cours d’eau. 
Les cours d’eau, auxquels peuvent appartenir les tronçons hydrographiques, sont des portions connexes du réseau hydrographique liées à un toponyme, possédant une source ou origine et un confluent ou embouchure. 

 Les tronçons retenus sont situés sur le territoire national : 
• tous les axes principaux, y compris dans la zone d’estran et dans les zones de marais et les « culs-de-sac », quelle que soit leur longueur (au  minimum  20  mètres). L’exhaustivité est assurée pour les culs de sac d’une longueur supérieure à un kilomètre ou appartenant à un cours d’eau d’une longueur supérieure à un kilomètre. 
• outre l’axe principal, les axes des bras secondaires ou qui délimitent une île d’une superficie supérieure à 10 hectares quand un cours d’eau se subdivise en plusieurs. 
 
La continuité du réseau est assurée lors de la traversée de plans d’eau, de zones de marais ou de drainage, d’agglomérations. 
 
Modélisation :  Plusieurs  cours  d’eau  peuvent  passer  par  le  même  tronçon  hydrographique. 
Dans ce cas, la géométrie du tronçon est dupliquée, et chaque objet porte les mêmes valeurs d’attribut, sauf pour le champ donnant le toponyme du cours d’eau.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon hydrographique.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.etat IS ''État du tronçon hydrographique. '';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.largeur IS ''Largeur du tronçon hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature du tronçon hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.navigable IS ''Navigabilité du tronçon hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.pos_sol IS ''Position du tronçon hydrographique par rapport au sol.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé au tronçon hydrographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.sens IS ''Sens d’écoulement des eaux le long du tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.classe IS ''Hiérarchie décroissante entre les cours d’eau.
Cette hiérarchie est basée sur les cours d’eau BD Carthage®. On entend par « embouchure logique » une interruption du réseau formé par les cours d’eau naturels : mer, puits, etc. '';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_troncon_hydrographique_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

----- n_troncon_route_bdc_
---- B.6.28 n_troncon_route_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_troncon_route_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_troncon_route_bdc_')) = 'n_troncon_route_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || ' IS ''Portion connexe de route, de chemin, de piste cyclable ou de sentier, homogène pour les relations la mettant en jeu, et pour les attributs qu’elle porte de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Les tronçons retenus sont : 
•  les tronçons d’autoroute et leurs bretelles d’accès ; 
•  les  tronçons de voie express quand la longueur totale est supérieure à 5 kms et leurs bretelles d’accès ; 
•  les tronçons de routes classées : nationales et départementales ; 
•  les autres tronçons de routes appartenant au réseau vert. 
Auxquels sont ajoutés : 
• En zone agglomérée ou dans les zones d’activité (ports, aérodromes, zones industrielles, marchés d’intérêt national ou régional, camps militaires, etc.), les autres tronçons de rues ou routes régulièrement entretenues qui : 
	o participent à la traversée ou au contournement d’une agglomération, 
	o permettent l’accès à une voie de contournement, une autoroute ou une voie express, 
	o constituent une desserte principale d’une zone administrative, industrielle ou commerciale, d’une gare, d’un port, d’un aéroport, d’un lieu d’intérêt touristique, d’un lotissement important ou d’un quartier important vis-à-vis de l’agglomération où il est situé ; 
• En dehors des zones agglomérées : 
	o les  tronçons  de  voies  carrossables  régulièrement  ou  irrégulièrement  entretenus,  à l’exception : 
		  des culs-de-sac de moins de 1000m de long. Ce seuil est abaissé à 200m lorsque le tronçon en cul-de-sac mène à un bâtiment ou un équipement, et à 500m lorsque le tronçon en cul-de-sac mène au littoral, 
		  des  tronçons  non  classés  qui  dédoublent  le  réseau  principal  sur  une  longueur inférieure à 500m sans desservir un bâtiment ou un équipement, 
		  des bretelles d’accès aux aires de repos et aires de service, 
		  des chemins de halage sans connexion avec le reste du réseau ;   
	o les tronçons de chemins ou sentiers :
		  qui mènent à un bâtiment ou un équipement, quand il n’existe pas d’accès par une route revêtue ou non revêtue (dans ce cas, seul l’accès principal est saisi, si sa longueur est supérieure à 200 mètres), 
		  qui suivent le tracé d’une voie antique (dont les critères de sélection sont donnés dans la description de l’objet complexe « itinéraire routier »), 
		  qui  permettent d’atteindre un sommet important ou constituent l’axe principal de liaison entre deux vallées de montagne ; 
	o les chemins et sentiers de montagne balisés menant à des lacs d’altitude ; 
	o les chemins et sentiers côtiers balisés d’une longueur supérieure à 1000m ; 
	o les chemins d’exploitation situés à l’intérieur des forêts lorsqu’ils sont dans le prolongement des routes retenues et qui se raccrochent à l’autre extrémité au réseau existant, ou lorsqu’ils forment des alignements de plus de 3000m ; 
	o les  pistes cyclables d’une longueur supérieure à 1000m ne doublant pas le réseau routier. 
 
Modélisation : À l’axe et au sol. Les tronçons de route en construction ne sont pas localisés précisément.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon de route.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.vocation IS '' Vocation de la liaison. 
Ce champ matérialise une hiérarchisation du réseau routier basée, non pas sur un critère administratif, mais sur l’importance des tronçons de route pour le trafic routier.
Ainsi les 4 valeurs « Type  autoroutier », « Liaison  principale », « Liaison  régionale » et « Liaison locale » permettent un maillage de plus en plus dense du territoire.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.nb_chausse IS ''Nombre de chaussées du tronçon. 
Pour les voies à chaussées séparées, si elles sont contiguës, la BD CARTO® contient un tronçon à deux chaussées ; si elles sont éloignées de plus de 100m sur au moins 1000m de long, la BD CARTO® contient deux tronçons à une chaussée.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre total de voies du tronçon de route.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.etat IS ''Etat physique du tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.acces IS ''Accès au tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.pos_sol IS ''Position du tronçon par rapport au sol.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.res_vert IS ''Appartenance du tronçon au réseau vert. 
 Il s’agit du réseau vert de transit, le réseau vert de rabattement n’est pas géré.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.sens IS ''Sens de circulation sur le tronçon. 
Le sens de circulation est géré de façon obligatoire sur les tronçons composant les voies à chaussées séparées éloignées (valeur Sens unique ou Sens inverse) et sur les tronçons constituant un échangeur détaillé ; dans les autres cas, le sens est géré si l’information est connue.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.nb_voies_m IS ''Nombre de voies de la chaussée montante. 
Ne concerne que les tronçons à deux chaussées. La chaussée montante est celle où la circulation s’effectue dans le sens des arcs composant le tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.nb_voies_d IS ''Nombre de voies de la chaussée descendante. 
Ne concerne que les tronçons à deux chaussées. La chaussée descendante est celle où la circulation s’effectue dans le sens inverse des arcs composant le tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé au tronçon de route.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.usage IS ''Utilisation du tronçon de route. 
Ce champ permet de distinguer les tronçons en fonction de leur utilisation potentielle pour la description de la logique de communication et/ou d’une représentation cartographique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.date IS ''Date prévue de mise en service du tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.num_route IS ''Numéro de la route contenant le tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.class_adm IS ''Classement administratif de la route contenant le tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.gest_route IS ''Département ou autre gestionnaire de la route contenant le tronçon.''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_troncon_route_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.29 n_troncon_voie_ferree_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_troncon_voie_ferree_bdc_')) = 'n_troncon_voie_ferree_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || ' IS ''Tronçon de voie ferrée et ligne de chemin de fer de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Un tronçon de voie ferrée est une portion connexe de voie ferrée, homogène pour les attributs qu’elle porte.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant du tronçon de voie ferrée.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature du tronçon de voie ferrée.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.energie IS ''Energie de propulsion.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.nb_voies IS ''Nombre de voies principales du tronçon.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.largeur IS ''Largeur du tronçon de voie ferrée.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.pos_sol IS ''Position du tronçon de voie ferrée par rapport au sol.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.classement IS ''Classement du tronçon de voie ferrée.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé au tronçon de voie ferrée.
Seuls les noms des ponts, viaducs ou tunnels sont portés par les tronçons.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.touristiq IS ''Eventuel caractère touristique de la ligne de chemin de fer à laquelle ce tronçon de voie ferrée peut appartenir.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.topo_ligne IS ''Eventuel toponyme de la ligne de chemin de fer à laquelle le tronçon de voie ferrée peut appartenir.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_troncon_voie_ferree_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.30 n_zone_activite_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_zone_activite_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_zone_activite_bdc_')) = 'n_zone_activite_bdc_'
	
	THEN
	req :='
			COMMENT ON TABLE ' || nom_schema || '.n_zone_activite_bdc_' || emprise || '_' || millesime || ' IS ''Toponymes des points représentant une zone d’activité. de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sont retenues les zones bâties ou aménagées, à usage d’activités  industrielles, commerciales, de stockage ou de transports (zones  industrielles,  raffineries,  centrales électriques, centres commerciaux, marchés  d’intérêt national (MIN) ou  régional (MIR), parcs d’expositions, entrepôts, ports, mines à ciel ouvert, etc.), d’une surface supérieure ou égale à 25 hectares.
 
Modélisation : Une zone d’activité est représentée par un sommet géométrique situé à l’intérieur de la zone.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_activite_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant la zone d’activité.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_activite_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à la zone d’activité.
Seuls les noms des ponts, viaducs ou tunnels sont portés par les tronçons.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_activite_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_zone_activite_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.31 n_zone_habitat_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_zone_habitat_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_zone_habitat_bdc_')) = 'n_zone_habitat_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_zone_habitat_bdc_' || emprise || '_' || millesime || ' IS ''Toponymes des points représentant une zone d’habitat. de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Sont retenus : 
• tous les groupes d’habitations couvrant une superficie supérieure ou égale à 8 hectares ; 
• les chefs-lieux de commune (zone d’habitat où se situe la mairie) ; 
• les anciens chefs-lieux de commune ; 
• la plupart des lieux-dits habités de 2 feux et plus, selon la densité de la zone ; 
• les autres lieux-dits habités situés soit aux carrefours accessibles par le réseau classé départemental ou national, soit à l’extrémité des culs-de-sac du réseau routier carrossable de longueur supérieure ou égale à 1000 mètres. 
 
Modélisation : Une zone d’habitat est représentée par un sommet géométrique situé en son centre géographique. Les zones d’habitat couvrant plus de 8 hectares apparaissent également comme objet de la classe ZONE_OCCUPATION_SOL de NATURE = Bâti.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_habitat_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant la zone d’habitat.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_habitat_bdc_' || emprise || '_' || millesime || '.importance IS ''Importance de la zone d’habitat.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_habitat_bdc_' || emprise || '_' || millesime || '.insee IS ''Numéro INSEE de la commune dont la zone d’habitat est chef-lieu.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_habitat_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à la zone d’habitat.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_habitat_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_zone_habitat_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.32 n_zone_hydrographique_texture_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_zone_hydrographique_texture_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_zone_hydrographique_texture_bdc_')) = 'n_zone_hydrographique_texture_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_zone_hydrographique_texture_bdc_' || emprise || '_' || millesime || ' IS ''Zone plate au drainage de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Zone plate au drainage complexe dans laquelle circule un ensemble de portions de cours d’eau formant un entrelacs de bras d’égale importance. 

Ces zones sont saisies si elles couvrent une superficie supérieure à 25 hectares.
Les  tronçons  hydrographiques  situés  dans  les  zones  d’hydrographie  de  texture  sont  présents dans la mesure où ils répondent aux critères de sélection définis pour cette classe d’objet.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_hydrographique_texture_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant la zone d’hydrographie de texture.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_habitat_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à la zone d’hydrographie de texture.''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_hydrographique_texture_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_zone_hydrographique_texture_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.33 n_zone_occupation_sol_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_zone_occupation_sol_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_zone_occupation_sol_bdc_')) = 'n_zone_occupation_sol_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_zone_occupation_sol_bdc_' || emprise || '_' || millesime || ' IS ''Zones d’occupation du sol de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Le territoire est partitionné en zones connexes et de nature homogène. 
Chaque zone est donc localisée et possède une nature. 
Tout point du territoire a été interprété lors de la saisie, et appartient à une zone et une seule. 
L’occupation du sol est saisie jusqu’à la laisse des plus basses eaux. Au-delà de cette laisse, et jusqu’à la limite du territoire BD CARTO®, on trouve la mer.

Surfaces minimales de sélection d’une zone selon la nature : 
 
La superficie minimale des zones d’occupation du sol est fixée à : 
•  8 ha pour les zones « Bâti », « Forêt » et « Glacier, névé » ; 
•  4 ha pour la zone « Eau libre » ; 
•  25 ha pour les autres zones. 
 
Cas particuliers : 
• Les îles sont saisies dès qu’elles atteignent une surface de 1 ha à la pleine mer. 
Pour les îles dont la superficie est comprise entre 1 ha et 25 ha, les seuils de saisie, pour toutes les zones, descendent à 1 ha. 
• En zone d’estran et en limite de laisse lorsque la zone d’estran n’existe pas, le seuil de saisie des zones « Sable … », « Rocher … » et « Mangrove … » descend à 4 ha. Les zones doivent avoir alors une largeur minimale de 50 mètres. 
 
Remarque : 
Les  objets  volumineux  (surface  importante)  sont  découpés  selon  une  grille  correspondant  au tableau d’assemblage des cartes au 1 : 50 000.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_occupation_sol_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant la zone  d’occupation du sol.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_occupation_sol_bdc_' || emprise || '_' || millesime || '.nature IS ''Nature de la zone d’occupation du sol.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_occupation_sol_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_zone_occupation_sol_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.34 n_zone_reglementee_touristique_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_zone_reglementee_touristique_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_zone_reglementee_touristique_bdc_')) = 'n_zone_reglementee_touristique_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_zone_reglementee_touristique_bdc_' || emprise || '_' || millesime || ' IS '' Toponyme des zones réglementées par l’administration et d’intérêt touristique de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
 Sont retenus : 
•  les parcs naturels marins et les parcs nationaux avec leurs zones périphériques ; 
•  les parcs naturels régionaux ; 
•  les réserves naturelles accessibles au public. Dans certaines de ces réserves, le public ne peut pas pénétrer mais l’observation peut se faire de l’extérieur ; c’est le cas le plus courant pour les îles. Une réserve naturelle es  un espace soumis à des restrictions et à une législation particulière afin de protéger un milieu naturel fragile ou menacé ; 
•  les réserves nationales de chasse ; 
•  les forêts domaniales selon la liste page suivante. 
 
Modélisation : Plusieurs zones réglementées peuvent se superposer.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_reglementee_touristique_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la zone réglementée par l’administration et d’intérêt touristique.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_reglementee_touristique_bdc_' || emprise || '_' || millesime || '.nature IS ''nature de la zone d’intérêt touristique.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_reglementee_touristique_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à la zone réglementée.''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_zone_reglementee_touristique_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_zone_reglementee_touristique_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

---- B.6.35 n_liaison_maritime_bdc_
SELECT tablename FROM pg_tables WHERE schemaname = nom_schema AND tablename = 'n_liaison_maritime_bdc_' || emprise || '_' || millesime INTO veriftable;
	IF LEFT(veriftable,length ('n_zone_reglementee_touristique_bdc_')) = 'n_liaison_maritime_bdc_'
	
	THEN
	req :='
		COMMENT ON TABLE ' || nom_schema || '.n_liaison_maritime_bdc_' || emprise || '_' || millesime || ' IS '' Liaison maritime ou ligne de bac reliant deux embarcadères de la BDCARTO® v3.2 pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
 Les liaisons maritimes et bacs retenus sont : 
•  tous les bacs et liaisons  maritimes reliant deux embarcadères situés sur le territoire de la BD CARTO® et ouverts au public, à l’exception des bacs fluviaux réservés aux piétons ; 
•  toutes  les  liaisons  maritimes  régulières  effectuant  le  transport  des  passagers  et  des véhicules entre un embarcadère situé sur le territoire de la BD CARTO® et un embarcadère situé hors du territoire BD CARTO®. 
 
 
Modélisation :  Les  liaisons  maritimes  et  bacs  ne  sont  pas  localisés  précisément,  seules  les extrémités (nœud routier de type autre que « embarcadère liaison maritime situé hors du territoire BD CARTO® »)  sont  localisées  avec  la  précision  nominale  de  la  BD  CARTO®
.  Les  liaisons maritimes permettent : 
•  d’indiquer les liaisons entre embarcadères ; 
•  d’avoir une représentation cartographique de ces liaisons ; 
•  d’assurer  la  continuité  du  réseau  routier  dans  certains  cas  (pour  la  valeur  "piétons  et automobiles" de l’attribut vocation de la liaison). '';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	req :='
		COMMENT ON COLUMN ' || nom_schema || '.n_liaison_maritime_bdc_' || emprise || '_' || millesime || '.id IS ''Identifiant de la liaison maritime ou ligne de bac reliant deux embarcadères.
Cet identifiant est unique. Il est stable d’une édition à l’autre.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_liaison_maritime_bdc_' || emprise || '_' || millesime || '.ouverture IS ''Période d’ouverture de la liaison.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_liaison_maritime_bdc_' || emprise || '_' || millesime || '.ouverture IS ''Vocation de la liaison.'';
		COMMENT ON COLUMN ' || nom_schema || '.n_liaison_maritime_bdc_' || emprise || '_' || millesime || '.toponyme IS ''Toponyme éventuellement associé à la liaison.''; 
		COMMENT ON COLUMN ' || nom_schema || '.n_liaison_maritime_bdc_' || emprise || '_' || millesime || '.geom IS ''Champs géométrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
	
	ELSE
	req :='La table ' || nom_schema || '.n_liaison_maritime_bdc_' || emprise || '_' || millesime || ' n’est pas présente';
	RAISE NOTICE '%', req;

	END IF;

END; 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
				   
COMMENT ON FUNCTION w_adl_delegue.set_adm_bdcarto(character varying, character varying, character varying) IS '[ADMIN - BDCARTO] - Administration d''un millesime de la BDCARTO une fois son import réalisé et les couches mises à la COVADIS

Taches réalisées :
- Renomage des tables
- Suppression des colonnes gid
- Ajout d''une clé primaire sur le champs [id]
- Ajout des contraintes
- Commentaires des tables
- Commentaires des colonnes
- Index Géométriques & attributaire

Tables concernées :
- acces_equipement
- aerodrome
- arrondissement
- cimetiere
- commune
- communication_restreinte
- construction_elevee
- debut_section
- departement
- digue	postgres
- enceinte_militaire
- equipement_routier
- etablissement
- franchissement
- itineraire
- liaison_maritime
- ligne_electrique
- limite_administrative
- massif_boise
- liaison_maritime

amélioration à faire :
---- B.4 Ajout des index attributaires

dernière MAJ : 10/09/2018';
