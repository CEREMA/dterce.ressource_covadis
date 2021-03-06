-- FUNCTION: w_adl_delegue.set_partition_detach_metropole_et_regions(character varying, character varying, boolean)

-- DROP FUNCTION w_adl_delegue.set_partition_detach_metropole_et_regions(character varying, character varying, boolean);

CREATE OR REPLACE FUNCTION w_adl_delegue.set_partition_detach_metropole_et_regions(
	racine_table character varying,
	millesime character varying DEFAULT NULL::character varying,
	partition_sans_millesime boolean DEFAULT false)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
/*
[ADMIN] - Detache les 95 départements d'un sous-partitionnement existant du type France Métropolitaine (000)
plus sous-partitionnement Régions (rrr) sans supprimer le partitionnement France / Régions.

Obligatoire : Patitionnement existant COVADIS : _000_ / _rrr_ / _ddd_

Option :
- racine_table = 'nomduschema.nomdelatable'
- millesime = '_aaaa'
- partition_sans_millesime = fasle ou true
si true : les tables régionales et la table nationale n'ont pas le millésime dans le nom de fichier
	emprise : ddd pour département, rrr pour région, 000 pour métropole, fra pour France entière,
	millesime : aaaa pour l'année du millesime

Taches réalisées :
---- A. Détachement des 95 tables départementales de 2019

Tables concernées :
- paramètre en entrée

amélioration à faire :
- option détacher les régions et/ou tout spprimer
- faire une boucle 'rrr' , ['ddd',...,'ddd']

dernière MAJ : 24/07/2019
*/

declare
req 						text;					-- Texte de la requete à faire passer
region 						character(03);			-- Région
tb_tout_dpt					character varying[];	-- Toutes les tables
nb_tout_dpt		 			integer;
departement					character(03);

BEGIN

---- A. Détachement des 95 tables départementales
---- AUVERGNE-RHONE-ALPES r84 : Ain (01) / Allier (03) / Ardèche (07) / Cantal (15) / Drôme (26) / Isère (3 / Loire (42) / Haute-Loire (43) / Puy-de-Dôme (63) / Rhône (69D) / Métropole de Lyon (69M) / Savoie (73) / Haute-Savoie (74)
region := 'r84';
tb_tout_dpt := array['001','003','007','015','026','038','042','043','063','069','073','074'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- BOURGOGNE-FRANCHE-COMTE r27 : Côte-d Or (21) / Doubs (25) / Jura (39) / Nièvre (5 / Haute-Saône (70) / Saône-et-Loire (71) / Yonne (89) / Territoire de Belfort (90)
region := 'r27';
tb_tout_dpt := array['021','025','039','058','070','071','089','090'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- OCCITANIE r76 : Ariège (09) / Aude (11) / Aveyron (12) / Gard (30) / Haute-Garonne (31) / Gers (32) / Hérault (34) / Lot (46) / Lozère (48) / Hautes-Pyrénées (65) / Pyrénées-Orientales (66) / Tarn (81) / Tarn-et-Garonne (82)
region := 'r76';
tb_tout_dpt := array['009','011','012','030','031','032','034','046','048','065','066','081','082'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- CENTRE-VAL DE LOIRE r24 : Cher (18) / Eure-et-Loir (28) / Indre (36) / Indre-et-Loire (37) / Loir-et-Cher (41) / Loiret (45)
region := 'r24';
tb_tout_dpt := array['018','028','036','037','041','045'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- NORMANDIE r28 : Calvados (14) / Eure (27) / Manche (50) / Orne (61) / Seine-Maritime (76)
region := 'r28';
tb_tout_dpt := array['014','027','050','061','076'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- NOUVELLE-AQUITAINE r75 : Charente (16) : Charente-Maritime (17) / Corrèze (19) / Creuse (23) / Dordogne (24) / Gironde (33) / Landes (40) / Lot-et-Garonne (47) / Pyrénées-Atlantiques (64) / Deux-Sèvres (79) / Vienne (86) / Haute-Vienne (87)
region := 'r75';
tb_tout_dpt := array['016','017','019','023','024','033','040','047','064','079','086','087'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
--- GRAND EST r44 : Ardennes (08) / Aube (10) / Marne (51) / Haute-Marne (52) / Meurthe-et-Moselle (54) / Meuse (55) / Moselle (57) / Bas-Rhin (67) / Haut-Rhin (68) / Vosges (88)
region := 'r44';
tb_tout_dpt := array['008','010','051','052','054','055','057','067','068','088'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- PROVENCE-ALPES-COTE D AZUR r93 : Alpes-de-Haute-Provence (04) / Hautes-Alpes (05) / Alpes-Maritimes (06) / Bouches-du-Rhône (13) / Var (83) / Vaucluse (84)
region := 'r93';
tb_tout_dpt := array['004','005','006','013','083','084'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- PAYS DE LA LOIRE r52 : Loire-Atlantique (44) / Maine-et-Loire (49) / Mayenne (53) / Sarthe (72) / Vendée (85)
region := 'r52';
tb_tout_dpt := array['044','049','053','072','085'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- HAUTS-DE-FRANCE r32 : Aisne (02) / Nord (59) / Oise (60) / Pas-de-Calais (62) / Somme (80)
region := 'r32';
tb_tout_dpt := array['002','059','060','062','080'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- BRETAGNE r53 : Côtes-d´Armor (22) / Finistère (29) / Ille-et-Vilaine (35) / Morbihan (56)
region := 'r53';
tb_tout_dpt := array['022','029','035','056'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- CORSE r94 : Haute-Corse (2B) / Corse-du-Sud (2A)
region := 'r94';
tb_tout_dpt := array['02A','02B'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;
---- ILE-DE-FRANCE r11 : Paris (75) / Seine-et-Marne (77) / Yvelines (78) / Essonne (91) / Hauts-de-Seine (92) / Seine-Saint-Denis (93) / Val-de-Marne (94) / Val-d´Oise (95)
region := 'r11';
tb_tout_dpt := array['075','077','078','091','092','093','094','095'];
nb_tout_dpt := array_length(tb_tout_dpt, 1);
FOR i_dpt IN 1..nb_tout_dpt LOOP
	departement := tb_tout_dpt[i_dpt];
	IF partition_sans_millesime is true
		THEN
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
		ELSE
			req := '
					ALTER TABLE IF EXISTS ' || racine_table || '_' || region || millesime || ' DETACH PARTITION ' || racine_table || '_' || departement || millesime || ';
			';
	END IF;
	RAISE NOTICE '%', req;
	EXECUTE(req);
END LOOP;

RETURN current_date || ' - Partition ' || racine_table || '_000 en place mais vidée ';
END; 
$BODY$;

ALTER FUNCTION w_adl_delegue.set_partition_detach_metropole_et_regions(character varying, character varying, boolean)
    OWNER TO postgres;

COMMENT ON FUNCTION w_adl_delegue.set_partition_detach_metropole_et_regions(character varying, character varying, boolean)
    IS '[ADMIN] - Detache les 95 départements d''un sous-partitionnement existant du type France Métropolitaine (000)
plus sous-partitionnement Régions (rrr) sans supprimer le partitionnement France / Régions

Obligatoire : Patitionnement existant COVADIS : _000_ / _rrr_ / _ddd_

Option :
- racine_table = ''nomduschema.nomdelatable''
- millesime = ''_aaaa''
- partition_sans_millesime = fasle ou true
si true : les tables régionales et la table nationale n''ont pas le millésime dans le nom de fichier
	emprise : ddd pour département, rrr pour région, 000 pour métropole, fra pour France entière,
	millesime : aaaa pour l''année du millesime

Taches réalisées :
---- A. Détachement des 95 tables départementales de 2019

Tables concernées :
- paramètre en entrée

amélioration à faire :
- option détacher les régions et/ou tout spprimer
- faire une boucle ''rrr'' , [''ddd'',...,''ddd'']

dernière MAJ : 24/07/2019';
