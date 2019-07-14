CREATE OR REPLACE FUNCTION partitionner_metropole(
	racine_table character varying)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$

declare
req 		text;					-- Texte de la requete à faire passer
region 		character varying;		-- Région

BEGIN

---- A. Mise en place des Régions
---- Création des Régions elles-mêmes partitionnables :
req := '
	---- AUVERGNE-RHONE-ALPES    84 : Ain (01) / Allier (03) / Ardèche (07) / Cantal (15) / Drôme (26) / Isère (3 / Loire (42) / Haute-Loire (43) / Puy-de-Dôme (63) / Rhône (69D) / Métropole de Lyon (69M) / Savoie (73) / Haute-Savoie (74)
	CREATE TABLE ' || racine_table || '_r84 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''001'',''003'',''007'',''015'',''026'',''038'',''042'',''043'',''063'',''069'',''073'',''074'') PARTITION BY LIST (code_dep);
	---- BOURGOGNE-FRANCHE-COMTE    27 : Côte-d Or (21) / Doubs (25) / Jura (39) / Nièvre (5 / Haute-Saône (70) / Saône-et-Loire (71) / Yonne (89) / Territoire de Belfort (90)
	CREATE TABLE ' || racine_table || '_r27 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''021'',''025'',''039'',''058'',''070'',''071'',''089'',''090'') PARTITION BY LIST (code_dep);
	---- OCCITANIE    76 : Ariège (09) / Aude (11) / Aveyron (12) / Gard (30) / Haute-Garonne (31) / Gers (32) / Hérault (34) / Lot (46) / Lozère (4 / Hautes-Pyrénées (65) / Pyrénées-Orientales (66) / Tarn (81) / Tarn-et-Garonne (82)
	CREATE TABLE ' || racine_table || '_r76 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''009'',''011'',''012'',''030'',''031'',''032'',''034'',''046'',''048'',''065'',''066'',''081'',''082'') PARTITION BY LIST (code_dep);
	---- CENTRE-VAL DE LOIRE    24 : Cher (1 / Eure-et-Loir (2 / Indre (36) / Indre-et-Loire (37) / Loir-et-Cher (41) / Loiret (45)
	CREATE TABLE ' || racine_table || '_r24 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''018'',''028'',''036'',''037'',''041'',''045'') PARTITION BY LIST (code_dep);
	---- NORMANDIE    28 : Calvados (14) / Eure (27) / Manche (50) / Orne (61) / Seine-Maritime (76)
	CREATE TABLE ' || racine_table || '_r28 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''014'',''027'',''050'',''061'',''076'') PARTITION BY LIST (code_dep);
	---- NOUVELLE-AQUITAINE    75 / Charente (16) : Charente-Maritime (17) / Corrèze (19) / Creuse (23) / Dordogne (24) / Gironde (33) / Landes (40) / Lot-et-Garonne (47) / Pyrénées-Atlantiques (64) / Deux-Sèvres (79) / Vienne (86) / Haute-Vienne (87)
	CREATE TABLE ' || racine_table || '_r75 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''016'',''017'',''019'',''023'',''024'',''033'',''040'',''047'',''064'',''079'',''086'',''087'') PARTITION BY LIST (code_dep);
	--- GRAND EST    44 : Ardennes (0 / Aube (10) / Marne (51) / Haute-Marne (52) / Meurthe-et-Moselle (54) / Meuse (55) / Moselle (57) / Bas-Rhin (67) / Haut-Rhin (6 / Vosges (8
	CREATE TABLE ' || racine_table || '_r44 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''008'',''010'',''051'',''052'',''054'',''055'',''057'',''067'',''068'',''088'') PARTITION BY LIST (code_dep);
	---- PROVENCE-ALPES-COTE D AZUR    93 : Alpes-de-Haute-Provence (04) / Hautes-Alpes (05) / Alpes-Maritimes (06) / Bouches-du-Rhône (13) / Var (83) / Vaucluse (84)
	CREATE TABLE ' || racine_table || '_r93 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''004'',''005'',''006'',''013'',''083'',''084'') PARTITION BY LIST (code_dep);
	---- PAYS DE LA LOIRE    52 : Loire-Atlantique (44) / Maine-et-Loire (49) / Mayenne (53) / Sarthe (72) / Vendée (85)
	CREATE TABLE ' || racine_table || '_r52 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''044'',''049'',''053'',''072'',''085'') PARTITION BY LIST (code_dep);
	---- HAUTS-DE-FRANCE    32 : Aisne (02) / Nord (59) / Oise (60) / Pas-de-Calais (62) / Somme (80)
	CREATE TABLE ' || racine_table || '_r32 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''002'',''059'',''060'',''062'',''080'') PARTITION BY LIST (code_dep);
	---- BRETAGNE    53 : Côtes-d´Armor (22) / Finistère (29) / Ille-et-Vilaine (35) / Morbihan (56)
	CREATE TABLE ' || racine_table || '_r53 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''022'',''029'',''035'',''056'') PARTITION BY LIST (code_dep);
	---- CORSE    94 : Haute-Corse (2B) / Corse-du-Sud (2A)
	CREATE TABLE ' || racine_table || '_r94 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''02A'',''02B'') PARTITION BY LIST (code_dep);
	---- ILE-DE-FRANCE    11 : Paris (75) / Seine-et-Marne (77) / Yvelines (7 / Essonne (91) / Hauts-de-Seine (92) / Seine-Saint-Denis (93) / Val-de-Marne (94) / Val-d´Oise (95)
	CREATE TABLE ' || racine_table || '_r11 PARTITION OF ' || racine_table || '_000 FOR VALUES IN (''075'',''077'',''078'',''091'',''092'',''093'',''094'',''095'') PARTITION BY LIST (code_dep);
';
RAISE NOTICE '%', req;
EXECUTE(req);

---- B. Mise en place des Départements par Région :
req := '
	---- AUVERGNE-RHONE-ALPES    84 : Ain (01) / Allier (03) / Ardèche (07) / Cantal (15) / Drôme (26) / Isère (3 / Loire (42) / Haute-Loire (43) / Puy-de-Dôme (63) / Rhône (69D) / Métropole de Lyon (69M) / Savoie (73) / Haute-Savoie (74)
	CREATE TABLE ' || racine_table || '_001 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''001'');
	CREATE TABLE ' || racine_table || '_003 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''003'');
	CREATE TABLE ' || racine_table || '_007 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''007'');
	CREATE TABLE ' || racine_table || '_015 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''015'');
	CREATE TABLE ' || racine_table || '_026 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''026'');
	CREATE TABLE ' || racine_table || '_038 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''038'');
	CREATE TABLE ' || racine_table || '_042 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''042'');
	CREATE TABLE ' || racine_table || '_043 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''043'');
	CREATE TABLE ' || racine_table || '_063 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''063'');
	CREATE TABLE ' || racine_table || '_069 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''069'');
	CREATE TABLE ' || racine_table || '_073 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''073'');
	CREATE TABLE ' || racine_table || '_074 PARTITION OF ' || racine_table || '_r84 FOR VALUES IN (''074'');
	---- BOURGOGNE-FRANCHE-COMTE    27 : Côte-d Or (21) / Doubs (25) / Jura (39) / Nièvre (5 / Haute-Saône (70) / Saône-et-Loire (71) / Yonne (89) / Territoire de Belfort (90)
	CREATE TABLE ' || racine_table || '_021 PARTITION OF ' || racine_table || '_r27 FOR VALUES IN (''021'');
	CREATE TABLE ' || racine_table || '_025 PARTITION OF ' || racine_table || '_r27 FOR VALUES IN (''025'');
	CREATE TABLE ' || racine_table || '_039 PARTITION OF ' || racine_table || '_r27 FOR VALUES IN (''039'');
	CREATE TABLE ' || racine_table || '_058 PARTITION OF ' || racine_table || '_r27 FOR VALUES IN (''058'');
	CREATE TABLE ' || racine_table || '_070 PARTITION OF ' || racine_table || '_r27 FOR VALUES IN (''070'');
	CREATE TABLE ' || racine_table || '_071 PARTITION OF ' || racine_table || '_r27 FOR VALUES IN (''071'');
	CREATE TABLE ' || racine_table || '_089 PARTITION OF ' || racine_table || '_r27 FOR VALUES IN (''089'');
	CREATE TABLE ' || racine_table || '_090 PARTITION OF ' || racine_table || '_r27 FOR VALUES IN (''090'');
	---- OCCITANIE    76 : Ariège (09) / Aude (11) / Aveyron (12) / Gard (30) / Haute-Garonne (31) / Gers (32) / Hérault (34) / Lot (46) / Lozère (4 / Hautes-Pyrénées (65) / Pyrénées-Orientales (66) / Tarn (81) / Tarn-et-Garonne (82)
	CREATE TABLE ' || racine_table || '_009 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''009'');
	CREATE TABLE ' || racine_table || '_011 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''011'');
	CREATE TABLE ' || racine_table || '_012 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''012'');
	CREATE TABLE ' || racine_table || '_030 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''030'');
	CREATE TABLE ' || racine_table || '_031 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''031'');
	CREATE TABLE ' || racine_table || '_032 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''032'');
	CREATE TABLE ' || racine_table || '_034 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''034'');
	CREATE TABLE ' || racine_table || '_046 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''046'');
	CREATE TABLE ' || racine_table || '_048 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''048'');
	CREATE TABLE ' || racine_table || '_065 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''065'');
	CREATE TABLE ' || racine_table || '_066 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''066'');
	CREATE TABLE ' || racine_table || '_081 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''081'');
	CREATE TABLE ' || racine_table || '_082 PARTITION OF ' || racine_table || '_r76 FOR VALUES IN (''082'');
	---- CENTRE-VAL DE LOIRE    24 : Cher (1 / Eure-et-Loir (2 / Indre (36) / Indre-et-Loire (37) / Loir-et-Cher (41) / Loiret (45)
	CREATE TABLE ' || racine_table || '_018 PARTITION OF ' || racine_table || '_r24 FOR VALUES IN (''018'');
	CREATE TABLE ' || racine_table || '_028 PARTITION OF ' || racine_table || '_r24 FOR VALUES IN (''028'');
	CREATE TABLE ' || racine_table || '_036 PARTITION OF ' || racine_table || '_r24 FOR VALUES IN (''036'');
	CREATE TABLE ' || racine_table || '_037 PARTITION OF ' || racine_table || '_r24 FOR VALUES IN (''037'');
	CREATE TABLE ' || racine_table || '_041 PARTITION OF ' || racine_table || '_r24 FOR VALUES IN (''041'');
	CREATE TABLE ' || racine_table || '_045 PARTITION OF ' || racine_table || '_r24 FOR VALUES IN (''045'');
	---- NORMANDIE    28 : Calvados (14) / Eure (27) / Manche (50) / Orne (61) / Seine-Maritime (76)
	CREATE TABLE ' || racine_table || '_014 PARTITION OF ' || racine_table || '_r28 FOR VALUES IN (''014'');
	CREATE TABLE ' || racine_table || '_027 PARTITION OF ' || racine_table || '_r28 FOR VALUES IN (''027'');
	CREATE TABLE ' || racine_table || '_050 PARTITION OF ' || racine_table || '_r28 FOR VALUES IN (''050'');
	CREATE TABLE ' || racine_table || '_061 PARTITION OF ' || racine_table || '_r28 FOR VALUES IN (''061'');
	CREATE TABLE ' || racine_table || '_076 PARTITION OF ' || racine_table || '_r28 FOR VALUES IN (''076'');
	---- NOUVELLE-AQUITAINE    75 / Charente (16) : Charente-Maritime (17) / Corrèze (19) / Creuse (23) / Dordogne (24) / Gironde (33) / Landes (40) / Lot-et-Garonne (47) / Pyrénées-Atlantiques (64) / Deux-Sèvres (79) / Vienne (86) / Haute-Vienne (87)
	CREATE TABLE ' || racine_table || '_016 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''016'');
	CREATE TABLE ' || racine_table || '_017 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''017'');
	CREATE TABLE ' || racine_table || '_019 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''019'');
	CREATE TABLE ' || racine_table || '_023 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''023'');
	CREATE TABLE ' || racine_table || '_024 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''024'');
	CREATE TABLE ' || racine_table || '_033 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''033'');
	CREATE TABLE ' || racine_table || '_040 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''040'');
	CREATE TABLE ' || racine_table || '_047 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''047'');
	CREATE TABLE ' || racine_table || '_064 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''064'');
	CREATE TABLE ' || racine_table || '_079 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''079'');
	CREATE TABLE ' || racine_table || '_086 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''086'');
	CREATE TABLE ' || racine_table || '_087 PARTITION OF ' || racine_table || '_r75 FOR VALUES IN (''087'');
	---- GRAND EST    44 : Ardennes (0 / Aube (10) / Marne (51) / Haute-Marne (52) / Meurthe-et-Moselle (54) / Meuse (55) / Moselle (57) / Bas-Rhin (67) / Haut-Rhin (6 / Vosges (8
	CREATE TABLE ' || racine_table || '_008 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''008'');
	CREATE TABLE ' || racine_table || '_010 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''010'');
	CREATE TABLE ' || racine_table || '_051 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''051'');
	CREATE TABLE ' || racine_table || '_052 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''052'');
	CREATE TABLE ' || racine_table || '_054 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''054'');
	CREATE TABLE ' || racine_table || '_055 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''055'');
	CREATE TABLE ' || racine_table || '_057 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''057'');
	CREATE TABLE ' || racine_table || '_067 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''067'');
	CREATE TABLE ' || racine_table || '_068 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''068'');
	CREATE TABLE ' || racine_table || '_088 PARTITION OF ' || racine_table || '_r44 FOR VALUES IN (''088'');
	---- PROVENCE-ALPES-COTE D AZUR    93 : Alpes-de-Haute-Provence (04) / Hautes-Alpes (05) / Alpes-Maritimes (06) / Bouches-du-Rhône (13) / Var (83) / Vaucluse (84)
	CREATE TABLE ' || racine_table || '_004 PARTITION OF ' || racine_table || '_r93 FOR VALUES IN (''004'');
	CREATE TABLE ' || racine_table || '_005 PARTITION OF ' || racine_table || '_r93 FOR VALUES IN (''005'');
	CREATE TABLE ' || racine_table || '_006 PARTITION OF ' || racine_table || '_r93 FOR VALUES IN (''006'');
	CREATE TABLE ' || racine_table || '_013 PARTITION OF ' || racine_table || '_r93 FOR VALUES IN (''013'');
	CREATE TABLE ' || racine_table || '_083 PARTITION OF ' || racine_table || '_r93 FOR VALUES IN (''083'');
	CREATE TABLE ' || racine_table || '_084 PARTITION OF ' || racine_table || '_r93 FOR VALUES IN (''084'');
	---- PAYS DE LA LOIRE    52 : Loire-Atlantique (44) / Maine-et-Loire (49) / Mayenne (53) / Sarthe (72) / Vendée (85)
	CREATE TABLE ' || racine_table || '_044 PARTITION OF ' || racine_table || '_r52 FOR VALUES IN (''044'');
	CREATE TABLE ' || racine_table || '_049 PARTITION OF ' || racine_table || '_r52 FOR VALUES IN (''049'');
	CREATE TABLE ' || racine_table || '_053 PARTITION OF ' || racine_table || '_r52 FOR VALUES IN (''053'');
	CREATE TABLE ' || racine_table || '_072 PARTITION OF ' || racine_table || '_r52 FOR VALUES IN (''072'');
	CREATE TABLE ' || racine_table || '_085 PARTITION OF ' || racine_table || '_r52 FOR VALUES IN (''085'');
	---- HAUTS-DE-FRANCE    32 : Aisne (02) / Nord (59) / Oise (60) / Pas-de-Calais (62) / Somme (80)
	CREATE TABLE ' || racine_table || '_002 PARTITION OF ' || racine_table || '_r32 FOR VALUES IN (''002'');
	CREATE TABLE ' || racine_table || '_059 PARTITION OF ' || racine_table || '_r32 FOR VALUES IN (''059'');
	CREATE TABLE ' || racine_table || '_060 PARTITION OF ' || racine_table || '_r32 FOR VALUES IN (''060'');
	CREATE TABLE ' || racine_table || '_062 PARTITION OF ' || racine_table || '_r32 FOR VALUES IN (''062'');
	CREATE TABLE ' || racine_table || '_080 PARTITION OF ' || racine_table || '_r32 FOR VALUES IN (''080'');
	---- BRETAGNE    53 : Côtes-d´Armor (22) / Finistère (29) / Ille-et-Vilaine (35) / Morbihan (56)
	CREATE TABLE ' || racine_table || '_022 PARTITION OF ' || racine_table || '_r53 FOR VALUES IN (''022'');
	CREATE TABLE ' || racine_table || '_029 PARTITION OF ' || racine_table || '_r53 FOR VALUES IN (''029'');
	CREATE TABLE ' || racine_table || '_035 PARTITION OF ' || racine_table || '_r53 FOR VALUES IN (''035'');
	CREATE TABLE ' || racine_table || '_056 PARTITION OF ' || racine_table || '_r53 FOR VALUES IN (''056'');
	---- CORSE    94 : Haute-Corse (2B) / Corse-du-Sud (2A)
	CREATE TABLE ' || racine_table || '_02a PARTITION OF ' || racine_table || '_r94 FOR VALUES IN (''02A'');
	CREATE TABLE ' || racine_table || '_02b PARTITION OF ' || racine_table || '_r94 FOR VALUES IN (''02B'');
	---- ILE-DE-FRANCE    11 : Paris (75) / Seine-et-Marne (77) / Yvelines (7 / Essonne (91) / Hauts-de-Seine (92) / Seine-Saint-Denis (93) / Val-de-Marne (94) / Val-d´Oise (95)
	CREATE TABLE ' || racine_table || '_075 PARTITION OF ' || racine_table || '_r11 FOR VALUES IN (''075'');
	CREATE TABLE ' || racine_table || '_077 PARTITION OF ' || racine_table || '_r11 FOR VALUES IN (''077'');
	CREATE TABLE ' || racine_table || '_078 PARTITION OF ' || racine_table || '_r11 FOR VALUES IN (''078'');
	CREATE TABLE ' || racine_table || '_091 PARTITION OF ' || racine_table || '_r11 FOR VALUES IN (''091'');
	CREATE TABLE ' || racine_table || '_092 PARTITION OF ' || racine_table || '_r11 FOR VALUES IN (''092'');
	CREATE TABLE ' || racine_table || '_093 PARTITION OF ' || racine_table || '_r11 FOR VALUES IN (''093'');
	CREATE TABLE ' || racine_table || '_094 PARTITION OF ' || racine_table || '_r11 FOR VALUES IN (''094'');
	CREATE TABLE ' || racine_table || '_095 PARTITION OF ' || racine_table || '_r11 FOR VALUES IN (''095'');
';
RAISE NOTICE '%', req;
EXECUTE(req);
	
RETURN current_time;
END; 
$BODY$;
