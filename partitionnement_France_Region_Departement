---- Créer la partition nationale avec comme clé de partitionnement le numéro de département
DROP TABLE IF EXISTS r_bdparcellaire.n_commune_bdp_000_2014;
CREATE TABLE r_bdparcellaire.n_commune_bdp_000_2014
(
    gid integer NOT NULL,
    nom_com character varying(45),
    code_dep character varying(2),
    code_insee character varying(5),
    geom geometry(MultiPolygon,2154)
)
PARTITION BY LIST (code_dep)
TABLESPACE data;

---- Création des Régions elles-mêmes partitionnables :
---- AUVERGNE-RHONE-ALPES    84 : Ain (01) / Allier (03) / Ardèche (07) / Cantal (15) / Drôme (26) / Isère (38) / Loire (42) / Haute-Loire (43) / Puy-de-Dôme (63) / Rhône (69D) / Métropole de Lyon (69M) / Savoie (73) / Haute-Savoie (74)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r84_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('01','03','07','15','26','38','42','43','63','69','73','74') PARTITION BY LIST (code_dep);
---- BOURGOGNE-FRANCHE-COMTE    27 : Côte-d'Or (21) / Doubs (25) / Jura (39) / Nièvre (58) / Haute-Saône (70) / Saône-et-Loire (71) / Yonne (89) / Territoire de Belfort (90)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r27_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('21','25','39','58','70','71','89','90') PARTITION BY LIST (code_dep);
---- OCCITANIE    76 : Ariège (09) / Aude (11) / Aveyron (12) / Gard (30) / Haute-Garonne (31) / Gers (32) / Hérault (34) / Lot (46) / Lozère (48) / Hautes-Pyrénées (65) / Pyrénées-Orientales (66) / Tarn (81) / Tarn-et-Garonne (82)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r76_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('09','11','12','30','31','32','34','46','48','65','66','81','82') PARTITION BY LIST (code_dep);
---- CENTRE-VAL DE LOIRE    24 : Cher (18) / Eure-et-Loir (28) / Indre (36) / Indre-et-Loire (37) / Loir-et-Cher (41) / Loiret (45)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r24_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('18','28','36','37','41','45') PARTITION BY LIST (code_dep);
---- NORMANDIE    28 : Calvados (14) / Eure (27) / Manche (50) / Orne (61) / Seine-Maritime (76)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r28_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('14','27','50','61','76') PARTITION BY LIST (code_dep);
---- NOUVELLE-AQUITAINE    75 / Charente (16) : Charente-Maritime (17) / Corrèze (19) / Creuse (23) / Dordogne (24) / Gironde (33) / Landes (40) / Lot-et-Garonne (47) / Pyrénées-Atlantiques (64) / Deux-Sèvres (79) / Vienne (86) / Haute-Vienne (87)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r75_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('16','17','19','23','24','33','40','47','64','79','86','87') PARTITION BY LIST (code_dep);
--- GRAND EST    44 : Ardennes (08) / Aube (10) / Marne (51) / Haute-Marne (52) / Meurthe-et-Moselle (54) / Meuse (55) / Moselle (57) / Bas-Rhin (67) / Haut-Rhin (68) / Vosges (88)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r44_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('08','10','51','52','54','55','57','67','68','88') PARTITION BY LIST (code_dep);
---- PROVENCE-ALPES-COTE D'AZUR    93 : Alpes-de-Haute-Provence (04) / Hautes-Alpes (05) / Alpes-Maritimes (06) / Bouches-du-Rhône (13) / Var (83) / Vaucluse (84)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r93_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('04','05','06','13','83','84') PARTITION BY LIST (code_dep);
---- PAYS DE LA LOIRE    52 : Loire-Atlantique (44) / Maine-et-Loire (49) / Mayenne (53) / Sarthe (72) / Vendée (85)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r52_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('44','49','53','72','85') PARTITION BY LIST (code_dep);
---- HAUTS-DE-FRANCE    32 : Aisne (02) / Nord (59) / Oise (60) / Pas-de-Calais (62) / Somme (80)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r32_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('02','59','60','62','80') PARTITION BY LIST (code_dep);
---- BRETAGNE    53 : Côtes-d´Armor (22) / Finistère (29) / Ille-et-Vilaine (35) / Morbihan (56)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r53_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('22','29','35','56') PARTITION BY LIST (code_dep);
---- CORSE    94 : Haute-Corse (2B) / Corse-du-Sud (2A)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r94_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('02a','02b') PARTITION BY LIST (code_dep);
---- ILE-DE-FRANCE    11 : Paris (75) / Seine-et-Marne (77) / Yvelines (78) / Essonne (91) / Hauts-de-Seine (92) / Seine-Saint-Denis (93) / Val-de-Marne (94) / Val-d´Oise (95)
CREATE TABLE r_bdparcellaire.n_commune_bdp_r11_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_000_2014 FOR VALUES IN ('75','77','78','91','92','93','94','95') PARTITION BY LIST (code_dep);

---- Il y a alors 2 options :
---- 1. Créer la sous-partition Ardéchoise de la partition Auvergne-Rhône-Alpes
---- CREATE TABLE r_bdparcellaire.n_commune_bdp_d07_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('07');
---- 1. On a ainsi une organisation vide dans laquelle on peut inserer des données nationales, régionales ou départementales
---- qui se répartiront dans les couches départementales selon la clé définie

---- AUVERGNE-RHONE-ALPES    84 : Ain (01) / Allier (03) / Ardèche (07) / Cantal (15) / Drôme (26) / Isère (38) / Loire (42) / Haute-Loire (43) / Puy-de-Dôme (63) / Rhône (69D) / Métropole de Lyon (69M) / Savoie (73) / Haute-Savoie (74)
CREATE TABLE r_bdparcellaire.n_commune_bdp_001_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('001');
CREATE TABLE r_bdparcellaire.n_commune_bdp_003_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('003');
CREATE TABLE r_bdparcellaire.n_commune_bdp_007_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('007');
CREATE TABLE r_bdparcellaire.n_commune_bdp_015_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('015');
CREATE TABLE r_bdparcellaire.n_commune_bdp_026_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('026');
CREATE TABLE r_bdparcellaire.n_commune_bdp_038_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('038');
CREATE TABLE r_bdparcellaire.n_commune_bdp_042_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('042');
CREATE TABLE r_bdparcellaire.n_commune_bdp_043_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('043');
CREATE TABLE r_bdparcellaire.n_commune_bdp_063_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('063');
CREATE TABLE r_bdparcellaire.n_commune_bdp_069_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('069');
CREATE TABLE r_bdparcellaire.n_commune_bdp_073_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('073');
CREATE TABLE r_bdparcellaire.n_commune_bdp_074_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('074');
---- BOURGOGNE-FRANCHE-COMTE    27 : Côte-d'Or (21) / Doubs (25) / Jura (39) / Nièvre (58) / Haute-Saône (70) / Saône-et-Loire (71) / Yonne (89) / Territoire de Belfort (90)
CREATE TABLE r_bdparcellaire.n_commune_bdp_021_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('021');
CREATE TABLE r_bdparcellaire.n_commune_bdp_025_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('025');
CREATE TABLE r_bdparcellaire.n_commune_bdp_039_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('039');
CREATE TABLE r_bdparcellaire.n_commune_bdp_058_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('058');
CREATE TABLE r_bdparcellaire.n_commune_bdp_070_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('070');
CREATE TABLE r_bdparcellaire.n_commune_bdp_071_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('071');
CREATE TABLE r_bdparcellaire.n_commune_bdp_089_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('089');
CREATE TABLE r_bdparcellaire.n_commune_bdp_090_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('090');
---- OCCITANIE    76 : Ariège (09) / Aude (11) / Aveyron (12) / Gard (30) / Haute-Garonne (31) / Gers (32) / Hérault (34) / Lot (46) / Lozère (48) / Hautes-Pyrénées (65) / Pyrénées-Orientales (66) / Tarn (81) / Tarn-et-Garonne (82)
CREATE TABLE r_bdparcellaire.n_commune_bdp_009_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('009');
CREATE TABLE r_bdparcellaire.n_commune_bdp_011_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('011');
CREATE TABLE r_bdparcellaire.n_commune_bdp_012_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('012');
CREATE TABLE r_bdparcellaire.n_commune_bdp_030_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('030');
CREATE TABLE r_bdparcellaire.n_commune_bdp_031_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('031');
CREATE TABLE r_bdparcellaire.n_commune_bdp_032_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('032');
CREATE TABLE r_bdparcellaire.n_commune_bdp_034_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('034');
CREATE TABLE r_bdparcellaire.n_commune_bdp_046_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('046');
CREATE TABLE r_bdparcellaire.n_commune_bdp_048_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('048');
CREATE TABLE r_bdparcellaire.n_commune_bdp_065_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('065');
CREATE TABLE r_bdparcellaire.n_commune_bdp_066_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('066');
CREATE TABLE r_bdparcellaire.n_commune_bdp_081_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('081');
CREATE TABLE r_bdparcellaire.n_commune_bdp_082_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('082');
---- CENTRE-VAL DE LOIRE    24 : Cher (18) / Eure-et-Loir (28) / Indre (36) / Indre-et-Loire (37) / Loir-et-Cher (41) / Loiret (45)
CREATE TABLE r_bdparcellaire.n_commune_bdp_018_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('018');
CREATE TABLE r_bdparcellaire.n_commune_bdp_028_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('028');
CREATE TABLE r_bdparcellaire.n_commune_bdp_036_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('036');
CREATE TABLE r_bdparcellaire.n_commune_bdp_037_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('037');
CREATE TABLE r_bdparcellaire.n_commune_bdp_041_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('041');
CREATE TABLE r_bdparcellaire.n_commune_bdp_045_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('045');
---- NORMANDIE    28 : Calvados (14) / Eure (27) / Manche (50) / Orne (61) / Seine-Maritime (76)
CREATE TABLE r_bdparcellaire.n_commune_bdp_014_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('014');
CREATE TABLE r_bdparcellaire.n_commune_bdp_027_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('027');
CREATE TABLE r_bdparcellaire.n_commune_bdp_050_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('050');
CREATE TABLE r_bdparcellaire.n_commune_bdp_061_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('061');
CREATE TABLE r_bdparcellaire.n_commune_bdp_076_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('076');
---- NOUVELLE-AQUITAINE    75 / Charente (16) : Charente-Maritime (17) / Corrèze (19) / Creuse (23) / Dordogne (24) / Gironde (33) / Landes (40) / Lot-et-Garonne (47) / Pyrénées-Atlantiques (64) / Deux-Sèvres (79) / Vienne (86) / Haute-Vienne (87)
CREATE TABLE r_bdparcellaire.n_commune_bdp_016_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('016');
CREATE TABLE r_bdparcellaire.n_commune_bdp_017_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('017');
CREATE TABLE r_bdparcellaire.n_commune_bdp_019_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('019');
CREATE TABLE r_bdparcellaire.n_commune_bdp_023_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('023');
CREATE TABLE r_bdparcellaire.n_commune_bdp_024_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('024');
CREATE TABLE r_bdparcellaire.n_commune_bdp_033_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('033');
CREATE TABLE r_bdparcellaire.n_commune_bdp_040_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('040');
CREATE TABLE r_bdparcellaire.n_commune_bdp_047_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('047');
CREATE TABLE r_bdparcellaire.n_commune_bdp_064_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('064');
CREATE TABLE r_bdparcellaire.n_commune_bdp_079_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('079');
CREATE TABLE r_bdparcellaire.n_commune_bdp_086_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('086');
CREATE TABLE r_bdparcellaire.n_commune_bdp_087_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('087');
---- GRAND EST    44 : Ardennes (08) / Aube (10) / Marne (51) / Haute-Marne (52) / Meurthe-et-Moselle (54) / Meuse (55) / Moselle (57) / Bas-Rhin (67) / Haut-Rhin (68) / Vosges (88)
CREATE TABLE r_bdparcellaire.n_commune_bdp_008_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('008');
CREATE TABLE r_bdparcellaire.n_commune_bdp_010_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('010');
CREATE TABLE r_bdparcellaire.n_commune_bdp_051_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('051');
CREATE TABLE r_bdparcellaire.n_commune_bdp_052_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('052');
CREATE TABLE r_bdparcellaire.n_commune_bdp_054_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('054');
CREATE TABLE r_bdparcellaire.n_commune_bdp_055_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('055');
CREATE TABLE r_bdparcellaire.n_commune_bdp_057_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('057');
CREATE TABLE r_bdparcellaire.n_commune_bdp_067_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('067');
CREATE TABLE r_bdparcellaire.n_commune_bdp_068_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('068');
CREATE TABLE r_bdparcellaire.n_commune_bdp_088_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('088');
---- PROVENCE-ALPES-COTE D'AZUR    93 : Alpes-de-Haute-Provence (04) / Hautes-Alpes (05) / Alpes-Maritimes (06) / Bouches-du-Rhône (13) / Var (83) / Vaucluse (84)
CREATE TABLE r_bdparcellaire.n_commune_bdp_004_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('004');
CREATE TABLE r_bdparcellaire.n_commune_bdp_005_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('005');
CREATE TABLE r_bdparcellaire.n_commune_bdp_006_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('006');
CREATE TABLE r_bdparcellaire.n_commune_bdp_013_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('013');
CREATE TABLE r_bdparcellaire.n_commune_bdp_083_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('083');
CREATE TABLE r_bdparcellaire.n_commune_bdp_084_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('084');
---- PAYS DE LA LOIRE    52 : Loire-Atlantique (44) / Maine-et-Loire (49) / Mayenne (53) / Sarthe (72) / Vendée (85)
CREATE TABLE r_bdparcellaire.n_commune_bdp_044_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('044');
CREATE TABLE r_bdparcellaire.n_commune_bdp_049_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('049');
CREATE TABLE r_bdparcellaire.n_commune_bdp_053_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('053');
CREATE TABLE r_bdparcellaire.n_commune_bdp_072_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('072');
CREATE TABLE r_bdparcellaire.n_commune_bdp_085_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('085');
---- HAUTS-DE-FRANCE    32 : Aisne (02) / Nord (59) / Oise (60) / Pas-de-Calais (62) / Somme (80)
CREATE TABLE r_bdparcellaire.n_commune_bdp_002_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('002');
CREATE TABLE r_bdparcellaire.n_commune_bdp_059_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('059');
CREATE TABLE r_bdparcellaire.n_commune_bdp_060_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('060');
CREATE TABLE r_bdparcellaire.n_commune_bdp_062_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('062');
CREATE TABLE r_bdparcellaire.n_commune_bdp_080_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('082');
---- BRETAGNE    53 : Côtes-d´Armor (22) / Finistère (29) / Ille-et-Vilaine (35) / Morbihan (56)
CREATE TABLE r_bdparcellaire.n_commune_bdp_022_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r53_2014 FOR VALUES IN ('022');
CREATE TABLE r_bdparcellaire.n_commune_bdp_029_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r53_2014 FOR VALUES IN ('029');
CREATE TABLE r_bdparcellaire.n_commune_bdp_035_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r53_2014 FOR VALUES IN ('035');
CREATE TABLE r_bdparcellaire.n_commune_bdp_056_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r53_2014 FOR VALUES IN ('056');
---- CORSE    94 : Haute-Corse (2B) / Corse-du-Sud (2A)
CREATE TABLE r_bdparcellaire.n_commune_bdp_02a_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r94_2014 FOR VALUES IN ('02a');
CREATE TABLE r_bdparcellaire.n_commune_bdp_02b_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r94_2014 FOR VALUES IN ('02b');
---- ILE-DE-FRANCE    11 : Paris (75) / Seine-et-Marne (77) / Yvelines (78) / Essonne (91) / Hauts-de-Seine (92) / Seine-Saint-Denis (93) / Val-de-Marne (94) / Val-d´Oise (95)
CREATE TABLE r_bdparcellaire.n_commune_bdp_075_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('075');
CREATE TABLE r_bdparcellaire.n_commune_bdp_077_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('077');
CREATE TABLE r_bdparcellaire.n_commune_bdp_078_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('078');
CREATE TABLE r_bdparcellaire.n_commune_bdp_091_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('091');
CREATE TABLE r_bdparcellaire.n_commune_bdp_092_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('092');
CREATE TABLE r_bdparcellaire.n_commune_bdp_093_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('093');
CREATE TABLE r_bdparcellaire.n_commune_bdp_094_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('094');
CREATE TABLE r_bdparcellaire.n_commune_bdp_095_2014 PARTITION OF r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('095');

---- 2. Attacher la table Ardéchoise existante à la partition partition Auvergne-Rhône-Alpes
---- AUVERGNE-RHONE-ALPES    84 : Ain (01) / Allier (03) / Ardèche (07) / Cantal (15) / Drôme (26) / Isère (38) / Loire (42) / Haute-Loire (43) / Puy-de-Dôme (63) / Rhône (69D) / Métropole de Lyon (69M) / Savoie (73) / Haute-Savoie (74)
ALTER TABLE r_bdparcellaire.n_commune_bdp_001_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('001');
ALTER TABLE r_bdparcellaire.n_commune_bdp_003_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('003');
ALTER TABLE r_bdparcellaire.n_commune_bdp_007_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('007');
ALTER TABLE r_bdparcellaire.n_commune_bdp_015_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('015');
ALTER TABLE r_bdparcellaire.n_commune_bdp_026_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('026');
ALTER TABLE r_bdparcellaire.n_commune_bdp_038_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('038');
ALTER TABLE r_bdparcellaire.n_commune_bdp_042_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('042');
ALTER TABLE r_bdparcellaire.n_commune_bdp_043_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('043');
ALTER TABLE r_bdparcellaire.n_commune_bdp_063_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('063');
ALTER TABLE r_bdparcellaire.n_commune_bdp_069_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('069');
ALTER TABLE r_bdparcellaire.n_commune_bdp_073_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('073');
ALTER TABLE r_bdparcellaire.n_commune_bdp_074_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r84_2014 FOR VALUES IN ('074');
---- BOURGOGNE-FRANCHE-COMTE    27 : Côte-d'Or (21) / Doubs (25) / Jura (39) / Nièvre (58) / Haute-Saône (70) / Saône-et-Loire (71) / Yonne (89) / Territoire de Belfort (90)
ALTER TABLE r_bdparcellaire.n_commune_bdp_021_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('021');
ALTER TABLE r_bdparcellaire.n_commune_bdp_025_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('025');
ALTER TABLE r_bdparcellaire.n_commune_bdp_039_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('039');
ALTER TABLE r_bdparcellaire.n_commune_bdp_058_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('058');
ALTER TABLE r_bdparcellaire.n_commune_bdp_070_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('070');
ALTER TABLE r_bdparcellaire.n_commune_bdp_071_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('071');
ALTER TABLE r_bdparcellaire.n_commune_bdp_089_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('089');
ALTER TABLE r_bdparcellaire.n_commune_bdp_090_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r27_2014 FOR VALUES IN ('090');
---- OCCITANIE    76 : Ariège (09) / Aude (11) / Aveyron (12) / Gard (30) / Haute-Garonne (31) / Gers (32) / Hérault (34) / Lot (46) / Lozère (48) / Hautes-Pyrénées (65) / Pyrénées-Orientales (66) / Tarn (81) / Tarn-et-Garonne (82)
ALTER TABLE r_bdparcellaire.n_commune_bdp_009_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('009');
ALTER TABLE r_bdparcellaire.n_commune_bdp_011_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('011');
ALTER TABLE r_bdparcellaire.n_commune_bdp_012_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('012');
ALTER TABLE r_bdparcellaire.n_commune_bdp_030_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('030');
ALTER TABLE r_bdparcellaire.n_commune_bdp_031_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('031');
ALTER TABLE r_bdparcellaire.n_commune_bdp_032_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('032');
ALTER TABLE r_bdparcellaire.n_commune_bdp_034_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('034');
ALTER TABLE r_bdparcellaire.n_commune_bdp_046_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('046');
ALTER TABLE r_bdparcellaire.n_commune_bdp_048_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('048');
ALTER TABLE r_bdparcellaire.n_commune_bdp_065_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('065');
ALTER TABLE r_bdparcellaire.n_commune_bdp_066_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('066');
ALTER TABLE r_bdparcellaire.n_commune_bdp_081_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('081');
ALTER TABLE r_bdparcellaire.n_commune_bdp_082_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r76_2014 FOR VALUES IN ('082');
---- CENTRE-VAL DE LOIRE    24 : Cher (18) / Eure-et-Loir (28) / Indre (36) / Indre-et-Loire (37) / Loir-et-Cher (41) / Loiret (45)
ALTER TABLE r_bdparcellaire.n_commune_bdp_018_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('018');
ALTER TABLE r_bdparcellaire.n_commune_bdp_028_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('028');
ALTER TABLE r_bdparcellaire.n_commune_bdp_036_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('036');
ALTER TABLE r_bdparcellaire.n_commune_bdp_037_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('037');
ALTER TABLE r_bdparcellaire.n_commune_bdp_041_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('041');
ALTER TABLE r_bdparcellaire.n_commune_bdp_045_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r24_2014 FOR VALUES IN ('045');
---- NORMANDIE    28 : Calvados (14) / Eure (27) / Manche (50) / Orne (61) / Seine-Maritime (76)
ALTER TABLE r_bdparcellaire.n_commune_bdp_014_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('014');
ALTER TABLE r_bdparcellaire.n_commune_bdp_027_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('027');
ALTER TABLE r_bdparcellaire.n_commune_bdp_050_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('050');
ALTER TABLE r_bdparcellaire.n_commune_bdp_061_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('061');
ALTER TABLE r_bdparcellaire.n_commune_bdp_076_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r28_2014 FOR VALUES IN ('076');
---- NOUVELLE-AQUITAINE    75 / Charente (16) : Charente-Maritime (17) / Corrèze (19) / Creuse (23) / Dordogne (24) / Gironde (33) / Landes (40) / Lot-et-Garonne (47) / Pyrénées-Atlantiques (64) / Deux-Sèvres (79) / Vienne (86) / Haute-Vienne (87)
ALTER TABLE r_bdparcellaire.n_commune_bdp_016_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('016');
ALTER TABLE r_bdparcellaire.n_commune_bdp_017_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('017');
ALTER TABLE r_bdparcellaire.n_commune_bdp_019_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('019');
ALTER TABLE r_bdparcellaire.n_commune_bdp_023_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('023');
ALTER TABLE r_bdparcellaire.n_commune_bdp_024_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('024');
ALTER TABLE r_bdparcellaire.n_commune_bdp_033_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('033');
ALTER TABLE r_bdparcellaire.n_commune_bdp_040_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('040');
ALTER TABLE r_bdparcellaire.n_commune_bdp_047_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('047');
ALTER TABLE r_bdparcellaire.n_commune_bdp_064_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('064');
ALTER TABLE r_bdparcellaire.n_commune_bdp_079_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('079');
ALTER TABLE r_bdparcellaire.n_commune_bdp_086_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('086');
ALTER TABLE r_bdparcellaire.n_commune_bdp_087_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r75_2014 FOR VALUES IN ('087');
---- GRAND EST    44 : Ardennes (08) / Aube (10) / Marne (51) / Haute-Marne (52) / Meurthe-et-Moselle (54) / Meuse (55) / Moselle (57) / Bas-Rhin (67) / Haut-Rhin (68) / Vosges (88)
ALTER TABLE r_bdparcellaire.n_commune_bdp_008_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('008');
ALTER TABLE r_bdparcellaire.n_commune_bdp_010_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('010');
ALTER TABLE r_bdparcellaire.n_commune_bdp_051_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('051');
ALTER TABLE r_bdparcellaire.n_commune_bdp_052_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('052');
ALTER TABLE r_bdparcellaire.n_commune_bdp_054_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('054');
ALTER TABLE r_bdparcellaire.n_commune_bdp_055_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('055');
ALTER TABLE r_bdparcellaire.n_commune_bdp_057_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('057');
ALTER TABLE r_bdparcellaire.n_commune_bdp_067_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('067');
ALTER TABLE r_bdparcellaire.n_commune_bdp_068_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('068');
ALTER TABLE r_bdparcellaire.n_commune_bdp_088_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r44_2014 FOR VALUES IN ('088');
---- PROVENCE-ALPES-COTE D'AZUR    93 : Alpes-de-Haute-Provence (04) / Hautes-Alpes (05) / Alpes-Maritimes (06) / Bouches-du-Rhône (13) / Var (83) / Vaucluse (84)
ALTER TABLE r_bdparcellaire.n_commune_bdp_004_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('004');
ALTER TABLE r_bdparcellaire.n_commune_bdp_005_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('005');
ALTER TABLE r_bdparcellaire.n_commune_bdp_006_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('006');
ALTER TABLE r_bdparcellaire.n_commune_bdp_013_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('013');
ALTER TABLE r_bdparcellaire.n_commune_bdp_083_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('083');
ALTER TABLE r_bdparcellaire.n_commune_bdp_084_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r93_2014 FOR VALUES IN ('084');
---- PAYS DE LA LOIRE    52 : Loire-Atlantique (44) / Maine-et-Loire (49) / Mayenne (53) / Sarthe (72) / Vendée (85)
ALTER TABLE r_bdparcellaire.n_commune_bdp_044_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('044');
ALTER TABLE r_bdparcellaire.n_commune_bdp_049_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('049');
ALTER TABLE r_bdparcellaire.n_commune_bdp_053_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('053');
ALTER TABLE r_bdparcellaire.n_commune_bdp_072_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('072');
ALTER TABLE r_bdparcellaire.n_commune_bdp_085_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r52_2014 FOR VALUES IN ('085');
---- HAUTS-DE-FRANCE    32 : Aisne (02) / Nord (59) / Oise (60) / Pas-de-Calais (62) / Somme (80)
ALTER TABLE r_bdparcellaire.n_commune_bdp_002_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('002');
ALTER TABLE r_bdparcellaire.n_commune_bdp_059_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('059');
ALTER TABLE r_bdparcellaire.n_commune_bdp_060_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('060');
ALTER TABLE r_bdparcellaire.n_commune_bdp_062_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('062');
ALTER TABLE r_bdparcellaire.n_commune_bdp_080_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r32_2014 FOR VALUES IN ('082');
---- BRETAGNE    53 : Côtes-d´Armor (22) / Finistère (29) / Ille-et-Vilaine (35) / Morbihan (56)
ALTER TABLE r_bdparcellaire.n_commune_bdp_022_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r53_2014 FOR VALUES IN ('022');
ALTER TABLE r_bdparcellaire.n_commune_bdp_029_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r53_2014 FOR VALUES IN ('029');
ALTER TABLE r_bdparcellaire.n_commune_bdp_035_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r53_2014 FOR VALUES IN ('035');
ALTER TABLE r_bdparcellaire.n_commune_bdp_056_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r53_2014 FOR VALUES IN ('056');
---- CORSE    94 : Haute-Corse (2B) / Corse-du-Sud (2A)
ALTER TABLE r_bdparcellaire.n_commune_bdp_02a_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r94_2014 FOR VALUES IN ('02a');
ALTER TABLE r_bdparcellaire.n_commune_bdp_02b_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r94_2014 FOR VALUES IN ('02b');
---- ILE-DE-FRANCE    11 : Paris (75) / Seine-et-Marne (77) / Yvelines (78) / Essonne (91) / Hauts-de-Seine (92) / Seine-Saint-Denis (93) / Val-de-Marne (94) / Val-d´Oise (95)
ALTER TABLE r_bdparcellaire.n_commune_bdp_075_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('075');
ALTER TABLE r_bdparcellaire.n_commune_bdp_077_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('077');
ALTER TABLE r_bdparcellaire.n_commune_bdp_078_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('078');
ALTER TABLE r_bdparcellaire.n_commune_bdp_091_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('091');
ALTER TABLE r_bdparcellaire.n_commune_bdp_092_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('092');
ALTER TABLE r_bdparcellaire.n_commune_bdp_093_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('093');
ALTER TABLE r_bdparcellaire.n_commune_bdp_094_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('094');
ALTER TABLE r_bdparcellaire.n_commune_bdp_095_2014 ATTACH PARTITION r_bdparcellaire.n_commune_bdp_r11_2014 FOR VALUES IN ('095');

---- Pour optimiser :
---- Contraintes & Index seulement sur toutes les partitions filles si PostgreSQL V10
---- Contraintes & Index sur la seule partition mère si PostgreSQL V11
