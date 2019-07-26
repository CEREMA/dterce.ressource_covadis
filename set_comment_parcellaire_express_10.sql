-- FUNCTION: w_adl_delegue.set_comment_parcellaire_express_10(boolean, character varying, character varying)

-- DROP FUNCTION w_adl_delegue.set_comment_parcellaire_express_10(boolean, character varying, character varying);

CREATE OR REPLACE FUNCTION w_adl_delegue.set_comment_parcellaire_express_10(
	covadis boolean DEFAULT false,
	emprise character varying DEFAULT NULL::character varying,
	millesime character varying DEFAULT EXTRACT(YEAR FROM current_date)::character(4))
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
/*
[ADMIN - PARCELLAIRE EXPRESS V1] - Mise en place des commentaires

Option :
- nommage COVADIS  par défault non
- si oui :
	emprise : ddd pour département, rrr pour région, 000 pour métropole, fra pour France entière,
	millesime : aaaa pour l'année du millesime

Tables concernées :
	batiment
	borne_limite_propriete
	borne_parcelle
	commune
	feuille
	localisant
	parcelle
	subdivision_fiscale

amélioration à faire :

dernière MAJ : 26/07/2019
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
		nom_schema := 'r_parcellaire_express_' || millesime;
	ELSE
		nom_schema := 'public';
END IF;

---- D. Mise en place des commentaires
---- D.0 arrondissement
IF covadis is true
	then
		nom_table := 'n_arrondissement_pepci_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'arrondissement';
		nomgeometrie := 'geom';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Table permettant de faire le lien entre les classes BORNE_LIMITE_PROPRIETE et PARCELLE.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee IS ''Numéro INSEE de la commune obtenu par concaténation du numéro de département et du numéro de commune.
Une commune nouvelle résultant d’un regroupement de communes préexistantes se voit attribuer le code INSEE de l’ancienne commune désignée comme chef-lieu par l’arrêté préfectoral qui l’institue.
En conséquence une commune change de code INSEE si un arrêté préfectoral modifie son chef-lieu.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_arr IS ''Nom de l’arrondissement municipal.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_arr IS ''Code de l’arrondissement municipal.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

---- D.1 batiment
IF covadis is true
	then
		nom_table := 'n_batiment_pepci_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'batiment';
		nomgeometrie := 'geom';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Type de bâtiment selon la distinction faite par le service du Cadastre en fonction
de la normalisation du PCI Vecteur.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type IS ''Type de bâtiment selon la distinction faite par le service du Cadastre en
fonction de la normalisation du PCI Vecteur :
- Bâtiment en dur : Construction attachée au sol par des fondations et fermée sur
les 4 côtés, ou bâtiment industriel.
- Construction légère : Structure légère non attachée au sol par l’intermédiaire de
fondations, ou bâtiment quelconque ouvert sur au moins un
côté.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
		';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

---- D.2 borne_limite_propriete
IF covadis is true
	then
		nom_table := 'n_borne_limite_propriete_pepci_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'borne_limite_propriete';
		nomgeometrie := 'geom';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Toutes les bornes de limite de propriété présentes dans le PCI Vecteur.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id IS ''Identifiant de la borne de limite de propriété.
Il s’agit de la concaténation d’attributs des classes FEUILLE, LOCALISANT et PARCELLE et du numéro du fichier de la DGFiP (précédé d’un underscore).
Cet identifiant n’est pas stable dans le temps, c’est-à-dire qu’il n’est pas le même d’une édition à l’autre.
Référence de la feuille obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune
absorbée [3 car], section cadastrale [2 car], numéro de feuille [2 car] et numéro de l’objet DGFiP [14 car. max], soit : ID = CODE_DEP + CODE_COM + COM_ABS + SECTION + FEUILLE + NUMERO OBJET.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT.'';
		';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

---- D.3 commune
IF covadis is true
	then
		nom_table := 'n_commune_pepci_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'commune';
		nomgeometrie := 'geom';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Plus petite subdivision du territoire, administrée par un maire, des adjoints et un conseil municipal.
Les objets surfaciques « Commune » forment une partition du territoire national à l’exception de certains lacs, étangs côtiers, et des eaux territoriales.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_com IS ''Nom officiel de la commune.'';	
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_dep IS ''Code INSEE du département.
	Pour les départements et collectivités d’outre-mer, seuls les deux premiers chiffres du numéro départemental sont pris en compte.
(voir Valeurs de l’attribut).'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_insee IS ''Numéro INSEE de la commune obtenu par concaténation du numéro de département et du numéro de commune.
Une commune nouvelle résultant d’un regroupement de communes préexistantes se voit attribuer le code INSEE de l’ancienne commune désignée comme chef-lieu par l’arrêté préfectoral qui l’institue.
En conséquence une commune change de code INSEE si un arrêté préfectoral modifie son chef-lieu.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
		';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;
	
	---- D.4 feuille
IF covadis is true
	then
		nom_table := 'n_feuille_pepci_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'feuille';
		nomgeometrie := 'geom';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Feuille cadastrale.
Partie du plan cadastral correspondant à une section ou à une subdivision de section (voir paragraphe 6. GLOSSAIRE).
Dans la plupart des cas, une feuille correspond à la partie du plan contenue dans une section, mais certaines feuilles peuvent contenir plusieurs sections.
Sur un territoire donné (commune ou arrondissement municipal), les objets surfaciques FEUILLE forment une partition de ce territoire.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.feuille IS ''Numéro de la feuille cadastrale.
Il permet d’identifier les subdivisions de section dans le cas des feuilles issues du cadastre napoléonien ou pour celles des départements du Bas-Rhin (67), du Haut-Rhin (68) et de Moselle (57).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.section IS ''Numéro de la section cadastrale.
Extrait du nom du fichier image produit par la DGFiP si les données cadastrales proviennent du PCI Image ou de l’identifiant de l’objet si elles proviennent du PCI
Lorsque le numéro de section ne comporte qu’un caractère, la valeur sera alors préfixée d’un « 0 ».'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_dep IS ''Code INSEE du département.
Pour les départements et collectivités d’outre-mer, seuls les deux premiers chiffres du numéro départemental sont pris en compte.'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_com IS ''Nom officiel de la commune.
Code officiel géographique de l’INSEE (COG).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_com IS ''Code INSEE de la commune.
Codification utilisée par la DGFiP sur les plans cadastraux à la date où ils ont été fournis à l’IGN pour constituer le produit Parcellaire Express (PCI).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.com_abs IS ''Ancien code INSEE de la commune en cas de fusion de communes.
Cet attribut sert à distinguer les feuilles cadastrales dans le cas des communes fusionnées.
Extrait du nom du fichier image produit par la DGFiP si les données cadastrales proviennent du PCI Image, ou de l’identifiant de l’objet si elles proviennent du PCI Vecteur.
Dans les cas particuliers des communes de Marseille (13055) et Toulouse (31555), il s’agit du code de quartier utilisé par la DGFiP.
Dans tous les autres cas, la valeur est « 000 ».'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.echelle IS ''Dénominateur de l’échelle principale du plan cadastral contenu sur la planche minute de conservation scannée par la DGFiP.'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.edition IS ''Numéro d’édition de la feuille dans le produit Parcellaire Express (PCI).
La feuille cadastrale est l’unité élémentaire de production et de mise à jour.'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_arr IS ''Code INSEE de l’arrondissement municipal.
Code officiel géographique de l’INSEE (COG).'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
		';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

---- D.5 localisant
IF covadis is true
	then
		nom_table := 'n_localisant_pepci_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'localisant';
		nomgeometrie := 'geom';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Localisant de parcelle cadastrale, situé dans l’emprise d’une parcelle du plan cadastral.
Pour les communes non couvertes par le PCI vecteur, il est issu des fichiers des localisants parcellaires produits par la DGFiP.
Pour les communes couvertes par le PCI vecteur, il est calculé de manière à être situé à l’intérieur de l’objet parcelle.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.idu IS ''Identifiant unique de la parcelle cadastrale.
Référence de la parcelle obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_COM + COM_ABS + SECTION + NUMERO
Cas particuliers des communes avec arrondissements municipaux (Paris, Lyon, Marseille) :
Code du département [2 car], code de l’arrondissement [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_ARR + COM_ABS + SECTION + NUMERO
Le code de la commune absorbée (COM_ABS) est égal à 000 lorsque la commune n’a pas fait l’objet de fusion avec une autre commune.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero IS '' Numéro de la parcelle cadastrale.
Fichiers des localisants parcellaires pour les communes issues du PCI Image, ou fichier PCI Vecteur de la DGFiP.
Valeurs composées de caractères numériques uniquement.
Lorsque le numéro de section comporte moins de 4 caractères, la valeur sera alors préfixée d’un ou plusieurs 0.'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.feuille IS ''Numéro de la feuille cadastrale.
Il permet d’identifier les subdivisions de section dans le cas des feuilles issues du cadastre napoléonien ou pour celles des départements du Bas-Rhin (67), du Haut-Rhin (68) et de Moselle (57).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.section IS ''Numéro de la section cadastrale.
Extrait du nom du fichier image produit par la DGFiP si les données cadastrales proviennent du PCI Image ou de l’identifiant de l’objet si elles proviennent du PCI
Lorsque le numéro de section ne comporte qu’un caractère, la valeur sera alors préfixée d’un « 0 ».'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_dep IS ''Code INSEE du département.
Pour les départements et collectivités d’outre-mer, seuls les deux premiers chiffres du numéro départemental sont pris en compte.'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_com IS ''Nom officiel de la commune.
Code officiel géographique de l’INSEE (COG).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_com IS ''Code INSEE de la commune.
Codification utilisée par la DGFiP sur les plans cadastraux à la date où ils ont été fournis à l’IGN pour constituer le produit Parcellaire Express (PCI).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.com_abs IS ''Ancien code INSEE de la commune en cas de fusion de communes.
Cet attribut sert à distinguer les feuilles cadastrales dans le cas des communes fusionnées.
Extrait du nom du fichier image produit par la DGFiP si les données cadastrales proviennent du PCI Image, ou de l’identifiant de l’objet si elles proviennent du PCI Vecteur.
Dans les cas particuliers des communes de Marseille (13055) et Toulouse (31555), il s’agit du code de quartier utilisé par la DGFiP.
Dans tous les autres cas, la valeur est « 000 ».'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_arr IS ''Code INSEE de l’arrondissement municipal.
Code officiel géographique de l’INSEE (COG).'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en POINT.'';
		';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

---- D.6 parcelle
IF covadis is true
	then
		nom_table := 'n_parcelle_pepci_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'parcelle';
		nomgeometrie := 'geom';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Parcelle : Portion du territoire communal d’un seul tenant située dans une même section, appartenant à un même propriétaire et formant un tout dont l’indépendance est évidente en regard de l’agencement de la propriété.
(Nomenclature d’échange du CNIG, indice EDIGÉO Z13-150).'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.idu IS ''Identifiant unique de la parcelle cadastrale.
Référence de la parcelle obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_COM + COM_ABS + SECTION + NUMERO
Cas particuliers des communes avec arrondissements municipaux (Paris, Lyon, Marseille) :
Code du département [2 car], code de l’arrondissement [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_ARR + COM_ABS + SECTION + NUMERO
Le code de la commune absorbée (COM_ABS) est égal à 000 lorsque la commune n’a pas fait l’objet de fusion avec une autre commune.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero IS '' Numéro de la parcelle cadastrale.
Fichiers des localisants parcellaires pour les communes issues du PCI Image, ou fichier PCI Vecteur de la DGFiP.
Valeurs composées de caractères numériques uniquement.
Lorsque le numéro de section comporte moins de 4 caractères, la valeur sera alors préfixée d’un ou plusieurs 0.'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.feuille IS ''Numéro de la feuille cadastrale.
Il permet d’identifier les subdivisions de section dans le cas des feuilles issues du cadastre napoléonien ou pour celles des départements du Bas-Rhin (67), du Haut-Rhin (68) et de Moselle (57).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.section IS ''Numéro de la section cadastrale.
Extrait du nom du fichier image produit par la DGFiP si les données cadastrales proviennent du PCI Image ou de l’identifiant de l’objet si elles proviennent du PCI
Lorsque le numéro de section ne comporte qu’un caractère, la valeur sera alors préfixée d’un « 0 ».'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_dep IS ''Code INSEE du département.
Pour les départements et collectivités d’outre-mer, seuls les deux premiers chiffres du numéro départemental sont pris en compte.'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom_com IS ''Nom officiel de la commune.
Code officiel géographique de l’INSEE (COG).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_com IS ''Code INSEE de la commune.
Codification utilisée par la DGFiP sur les plans cadastraux à la date où ils ont été fournis à l’IGN pour constituer le produit Parcellaire Express (PCI).'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.com_abs IS ''Ancien code INSEE de la commune en cas de fusion de communes.
Cet attribut sert à distinguer les feuilles cadastrales dans le cas des communes fusionnées.
Extrait du nom du fichier image produit par la DGFiP si les données cadastrales proviennent du PCI Image, ou de l’identifiant de l’objet si elles proviennent du PCI Vecteur.
Dans les cas particuliers des communes de Marseille (13055) et Toulouse (31555), il s’agit du code de quartier utilisé par la DGFiP.
Dans tous les autres cas, la valeur est « 000 ».'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code_arr IS ''Code INSEE de l’arrondissement municipal.
Code officiel géographique de l’INSEE (COG).'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
		';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

---- D.7 subdivision_fiscale
IF covadis is true
	then
		nom_table := 'n_subdivision_fiscale_pepci_' || emprise || '_' || millesime;
		nomgeometrie := 'geom';
	else
		nom_table := 'subdivision_fiscale';
		nomgeometrie := 'geom';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Subdivision fiscale d’une parcelle.
Toutes les subdivisions fiscales présentes dans le PCI Vecteur.
Limite de la subdivision. En principe, cette limite définit un contour simple, éventuellement troué.
Exceptionnellement, si les fichiers PCI Vecteur la décrivent ainsi, la subdivision pourra être constituée de plusieurs contours disjoints.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.idu IS ''Identifiant unique de la parcelle cadastrale.
Référence de la parcelle obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_COM + COM_ABS + SECTION + NUMERO
Cas particuliers des communes avec arrondissements municipaux (Paris, Lyon, Marseille) :
Code du département [2 car], code de l’arrondissement [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_ARR + COM_ABS + SECTION + NUMERO
Le code de la commune absorbée (COM_ABS) est égal à 000 lorsque la commune n’a pas fait l’objet de fusion avec une autre commune.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.lettre IS ''Lettre indicative de subdivision fiscale.'';
	COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géométrique en MULTIPOLYGON.'';
		';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

---- D.7 borne_parcelle
IF covadis is true
	then
		nom_table := 'n_borne_parcelle_pepci_' || emprise || '_' || millesime;
		nomgeometrie := '';
	else
		nom_table := 'borne_parcelle';
		nomgeometrie := '';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''IGN PARCELLAIRE EXPRESS® - Edition ' || millesime || ' - Table permettant de faire le lien entre les classes BORNE_LIMITE_PROPRIETE et PARCELLE.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='
			COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id_borne IS ''Identifiant de la borne de limite de propriété.
Il s’agit de la concaténation d’attributs des classes FEUILLE, LOCALISANT et PARCELLE et du numéro du fichier de la DGFiP (précédé d’un underscore).
Cet identifiant n’est pas stable dans le temps, c’est-à-dire qu’il n’est pas le même d’une édition à l’autre.
Référence de la feuille obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune
absorbée [3 car], section cadastrale [2 car], numéro de feuille [2 car] et numéro de l’objet DGFiP [14 car. max], soit : ID = CODE_DEP + CODE_COM + COM_ABS + SECTION + FEUILLE + NUMERO OBJET.'';
    COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.idu_parcel IS ''Identifiant unique de la parcelle cadastrale.
Référence de la parcelle obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_COM + COM_ABS + SECTION + NUMERO
Cas particuliers des communes avec arrondissements municipaux (Paris, Lyon, Marseille) :
Code du département [2 car], code de l’arrondissement [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_ARR + COM_ABS + SECTION + NUMERO
Le code de la commune absorbée (COM_ABS) est égal à 000 lorsque la commune n’a pas fait l’objet de fusion avec une autre commune.'';
		';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

RETURN current_time;
END; 
$BODY$;

ALTER FUNCTION w_adl_delegue.set_comment_parcellaire_express_10(boolean, character varying, character varying)
    OWNER TO postgres;

COMMENT ON FUNCTION w_adl_delegue.set_comment_parcellaire_express_10(boolean, character varying, character varying)
    IS '[ADMIN - PARCELLAIRE EXPRESS V1] - Mise en place des commentaires

Option :
- nommage COVADIS  par défault non
- si oui :
	emprise : ddd pour département, rrr pour région, 000 pour métropole, fra pour France entière,
	millesime : aaaa pour l''année du millesime

Tables concernées :
	batiment
	borne_limite_propriete
	borne_parcelle
	commune
	feuille
	localisant
	parcelle
	subdivision_fiscale

amélioration à faire :

dernière MAJ : 26/07/2019';
