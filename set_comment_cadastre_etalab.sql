CREATE OR REPLACE FUNCTION w_adl_delegue.set_comment_cadastre_etalab(nom_schema character varying,
																	 emprise character DEFAULT '000'::bpchar,
																	 millesime character DEFAULT NULL::bpchar,
																	 covadis boolean DEFAULT true)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
/*
[ADMIN - CADASTRE ETALAB] - Mise en place des commentaires

Option :
- nom du schéma où se trouvent les tables
- emprise sur 3 caractères selon la COVADIS ddd : 
	- 'fra' : France Entière
	- '000' : France Métropolitaine
	- 'rrr' : Numéro INSEE de la Région : 'r84' pour Avergne-Rhône-Alpes
	- 'ddd' : Numéro INSEE du département : '038' pour l'Isère
				non pris en compte si COVADIS = false
- millesime selon COVADIS : aaaa pour l'année du millesime ou null si pas de millesime
				non pris en compte si COVADIS = false
- COVADIS : nommage des tble selon la COVADIS : oui : true / non false

Tables concernées :
- bati
- commune
- feuille
- lieu_dit
- parcelle
- prefixe_section
- section
- subdivision_fiscale

amélioration à faire :

dernière MAJ : 04/04/2020
*/
declare
nom_table 					character varying;		-- nom de la table en text
champs						character varying;		-- nom de la table en text;
commentaires 				character varying;		-- nom de la table en text
req 						text;
veriftable 					character varying;
liste_valeur				character varying[][4];	-- Toutes les tables
attribut 					character varying; 		-- Liste des attributs de la table
nomgeometrie 				character varying; 		-- nom de l'attribut qui contient la géométrie

begin

IF covadis is true
	THEN nomgeometrie := 'geom';
	ELSE nomgeometrie := 'wkb_geometry';
END IF;

---- A] Commentaires des tables
---- Liste des valeurs à passer :
liste_valeur := ARRAY[

ARRAY['bati','Bâtiment de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Définitions, Commentaires :
Construction assise sur une ou plusieurs parcelles cadastrales

Contraintes : 
* entre objets identiques :
un bâtiment peut être à cheval sur plusieurs parcelles. L’élément de bâtiment est la partie de construction supportée par une seule parcelle.
Les éléments d’un même bâtiment doivent être en cohérence géométrique entre eux.
* entre objets différents :
les limites d’un bâtiment peuvent être en partie confondues avec celles des parcelles.
Toute limite de subdivision de section ou de section quipasse à l’intérieur d’un bâtiment doit scinder cet objet en deux bâtiments distincts. 
Lorsque l’on réunit deux parcelles sur lesquelles sont implantés deux bâtiments contigus, les bâtiments ne sont pas réunis.'],

ARRAY['commune','Commune de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Définitions, Commentaires : 
Territoire contenant un nombre entier de subdivisions de section cadastrales.
Son emprise est constituée à partir de l’union des subdivisions de section qui la composent au moment de l’échange.
Le contour de l’objet «COMMUNE» est calculé automatiquement à partir des subdivisions de section reçues, même si l’objet «COMMUNE» a été transmis dans l’échange.'],

ARRAY['feuille','Feuille de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Le plan cadastral d´une commune est composé de feuilles parcellaires qui donnent la représentationgraphique du territoire communal dans tous les détails de son morcellement.
Il comporte le parcellaire,les bâtiments, l´ensemble des limites administratives, les voies de communication, l´hydrographie, la toponymie ainsi que diverses informations représentées par des signes conventionnels.'],

ARRAY['lieu_dit','Lieu-dit de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Ensemble de parcelles entières comportant une même dénomination géographique résultant de l’usage.'],
	
ARRAY['parcelle','Parcelle de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Portion de territoire communal d’un seul tenant située dans une subdivision de section et appartenant à un même propriétaire.
Certaines parcelles, incluses dans la voirie et en attente d’une régularisation juridique, ne figurent pas au plan.

Contraintes :
* entre objets identiques : cette cohérence n’existe qu’entre parcelles d’un même ensemble de parcelles contiguës appartenant à une même commune.
Elle est assurée en utilisant une polyligne unique (même appellation et mêmes coordonnées des points) pour représenter la limite commune à deux parcelles
(sauf en cas de discordances subsistantentre ces parcelles, notamment en limite de subdivision de section).
La position médiane des points p2 et p5 d’une part, p3 et p8 d’autre part, est retenue pour donner respectivement les points A2 et A5.
Si un objet «PARCELLE» n’est pas en cohérence topologique avec son environnement, il entraîne le classement des autres objets «PARCELLE» de l’échange dans la structure spaghetti.
La ou les subdivisions de section ainsi que la section ou les sections concernées ne subissent toutefois pas ce déclassement.

* entre objets différents : Une limite de parcelle peut être confondue avec une limite de lieu-dit, de subdivision de section, de section, de commune, de département ou d’État lorsque ces limites ont des tronçons communs.
Les limites parcellaires respectent le premier principe général présenté au paragraphe 7.2.'],
	
ARRAY['prefixe_section','Préfixe de Section de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Le préfixe de section cadastrale permet d’identifier de manière unique des parcelles qui provient de communes fusionnées ou absorbées et de mémoire, existe aussi sur les communes découpées en arrondissements.
Si la section appartient à la commune absorbante, il est alors indiqué "000".'],
	
ARRAY['section','Section de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Partie du plan cadastral correspondant à une portion du territoire communal et comportant, suivant le cas, une ou plusieurs subdivisions de section.
Cet objet est obligatoire dans tous les lots formant l’échange.'],
	
ARRAY['subdivision_fiscale','Subdivision Fiscale de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Portion de section cadastrale disposant de caractéristiques propres au regard notamment de :
- son échelle;
- sa qualité;
- son mode de confection.
Une section a au moins une subdivision de section. Cet objet correspond à la feuille cadastrale.']
];

---- Boucle pour tous les commentaires de table
FOR i_table IN 1..array_length(liste_valeur, 1) LOOP
---- Récupération des champs
---- Nom de la table
	select
		case
			when COVADIS is false then 
				lower(liste_valeur[i_table][1])
			else
				case
					when millesime is not null then
						'n_' || lower(liste_valeur[i_table][1]) || '_etalab_' || emprise || '_' || millesime
					else
						'n_' || lower(liste_valeur[i_table][1]) || '_etalab_' || emprise
				end
		end
		 into nom_table;
---- Nom du commentaire	
	SELECT liste_valeur[i_table][2] into commentaires;
---- Execution de la requete
	IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) then
		req := '
				COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''' || commentaires || ''';
				';
		RAISE NOTICE '%', req;
		EXECUTE(req);
	else
		req := '
				La table ' || nom_schema || '.' || nom_table || ' n´est pas présente.
				';
		RAISE NOTICE '%', req;
	END IF;
END LOOP;

---- B] Commentaires des attributs
---- Liste des valeurs à passer :
liste_valeur := ARRAY[
---- bati
ARRAY['bati','type',
'Type de bâtiment selon la distinction faite par le service du Cadastre en
fonction de la normalisation du PCI Vecteur :
- 01 : Bâtiment en dur : Construction attachée au sol par des fondations et fermée sur
les 4 côtés, ou bâtiment industriel.
- 02 : Construction légère : Structure légère non attachée au sol par l’intermédiaire de
fondations, ou bâtiment quelconque ouvert sur au moins un
côté.'],
ARRAY['bati','nom','Texte du bâtiment issu de la DGFiP.'],
ARRAY['bati','commune','Code INSEE de la commune de laquelle le bâtiment fait partie.'],
ARRAY['bati','created','Date de création de l’objet par la DGFiP.'],
ARRAY['bati','updated','Date de dernière modification de l’objet par la DGFiP.'],
ARRAY['bati',nomgeometrie,'Champs géometrique en Lambert93.'],
---- commune
ARRAY['commune','id','Identifiant unique de l’objet : Code INSEE de la commune.'],
ARRAY['commune','nom','Nom officiel DGFiP de la commune.'],
ARRAY['commune','created','Date de création de l’objet par la DGFiP.'],
ARRAY['commune','updated','Date de dernière modification de l’objet par la DGFiP.'],
ARRAY['commune',nomgeometrie,'Champs géometrique en Lambert93.'],
---- feuille
ARRAY['feuille','id','Identifiant unique de l’objet.'],
ARRAY['feuille','commune','Nom DGFiP de la commune : Code INSEE de la commune.'],
ARRAY['feuille','prefixe',
'Le préfixe de section cadastrale permet d’identifier de manière unique des parcelles qui provient de communes fusionnées ou absorbées et de mémoire, existe aussi sur les communes découpées en arrondissements.
Si la section appartient à la commune absorbante, il est alors indiqué "000".'],
ARRAY['feuille','section',
'Numéro de la section cadastrale.
Extrait du nom du fichier image produit par la DGFiP si les données cadastrales proviennent du PCI Image ou de l’identifiant de l’objet si elles proviennent du PCI.
Lorsque le numéro de section ne comporte qu’un caractère, la valeur sera alors préfixée d’un « 0 ».'],
ARRAY['feuille','numero',
'Numéro de la feuille cadastrale.
Il permet d’identifier les subdivisions de section dans le cas des feuilles issues du cadastre napoléonien ou pour celles des départements du Bas-Rhin (67), du Haut-Rhin (68) et de Moselle (57).'],	  
ARRAY['feuille','qualite','En attente de métadonnées sur cadastre.data.gouv.fr.'],
ARRAY['feuille','modeconfection','En attente de métadonnées sur cadastre.data.gouv.fr.'],
ARRAY['feuille','echelle','Dénominateur de l’échelle principale du plan cadastral contenu sur la planche minute de conservation scannée par la DGFiP.'],	
ARRAY['feuille','created','Date de création de l’objet par la DGFiP.'],
ARRAY['feuille','updated','Date de dernière modification de l’objet par la DGFiP.'],
ARRAY['feuille',nomgeometrie,'Champs géometrique en Lambert93.'],
---- Lieu-dit
ARRAY['lieu_dit','nom','Nom DGFiP du lieu-dit.'],
ARRAY['lieu_dit','commune','Code INSEE de la commune.'],
ARRAY['lieu_dit','created','Date de création de l’objet par la DGFiP.'],
ARRAY['lieu_dit','updated','Date de dernière modification de l’objet par la DGFiP.'],
ARRAY['lieu_dit',nomgeometrie,'Champs géometrique en Lambert93.'],
---- parcelle
ARRAY['parcelle','id',
'Identifiant unique de la parcelle cadastrale.
Référence de la parcelle obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_COM + COM_ABS + SECTION + NUMERO
Cas particuliers des communes avec arrondissements municipaux (Paris, Lyon, Marseille) :
Code du département [2 car], code de l’arrondissement [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_ARR + COM_ABS + SECTION + NUMERO
Le code de la commune absorbée (COM_ABS) est égal à 000 lorsque la commune n’a pas fait l’objet de fusion avec une autre commune..'],
ARRAY['parcelle','commune','Code INSEE de la commune.'],
ARRAY['parcelle','prefixe','En attente de métadonnées sur cadastre.data.gouv.fr.'],
ARRAY['parcelle','section',
'Numéro de la section cadastrale.
Extrait du nom du fichier image produit par la DGFiP si les données cadastrales proviennent du PCI Image ou de l’identifiant de l’objet si elles proviennent du PCI.
Lorsque le numéro de section ne comporte qu’un caractère, la valeur sera alors préfixée d’un « 0 ».'],
ARRAY['parcelle','numero',
'Numéro de la parcelle cadastrale.
Fichiers des localisants parcellaires pour les communes issues du PCI Image, ou fichier PCI Vecteur de la DGFiP.
Valeurs composées de caractères numériques uniquement.'],
ARRAY['parcelle','contenance',
'Il s’agit de la surface cadastrale d’un bien immobilier (appartement, maison, terrain, etc) et la surface inscrite sur les documents cadastraux.
	 Cette surface permet de calculer l’impôt foncier.
	 Elle prend en compte l’intégralité de la surface au sol.
	 Le cadastre contient les relevés topographiques des propriétés de communes.'],
ARRAY['parcelle','arpente','True : La parcelle a fait l’objet d’un arpentage : sa contenance s’en trouve alors "fiabilisée" (elle correspond à la réalité terrain).'],	
ARRAY['parcelle','created','Date de création de l’objet par la DGFiP.'],
ARRAY['parcelle','updated','Date de dernière modification de l’objet par la DGFiP.'],
ARRAY['parcelle',nomgeometrie,'Champs géometrique en Lambert93.'],
---- préfixe de section
ARRAY['prefixe_section','id','Identifiant unique de l’objet : Code INSEE de la parcelle + Code de la section actuelle.'],
ARRAY['prefixe_section','commune','Code INSEE de la commune.'],
ARRAY['prefixe_section','prefixe',
'Le préfixe de section cadastrale permet d’identifier de manière unique des parcelles qui provient de communes fusionnées ou absorbées et de mémoire, existe aussi sur les communes découpées en arrondissements.
Si la section appartient à la commune absorbante, il est alors indiqué "000".'],
ARRAY['prefixe_section','ancienne',
'Ancien code INSEE de la commune fusionnée ou absorbée.
Dans le cas d’une absorption, la commune absorbante conserve ses identifiants parcellaires en l’état, ce champs est NULL.'],
ARRAY['prefixe_section','nom',
'Ancien nom de la commune fusionnée ou absorbée.
Dans le cas d’une absorption, la commune absorbante conserve ses identifiants parcellaires en l’état, ce champs est NULL.'],
ARRAY['prefixe_section',nomgeometrie,'Champs géometrique en Lambert93.'],	
---- section
ARRAY['section','id',
'Identifiant unique de la section cadastrale.
Référence de la section obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune absorbée [3 car], section cadastrale [2 car], soit : IDU = CODE_DEP + CODE_COM + COM_ABS + SECTION
Cas particuliers des communes avec arrondissements municipaux (Paris, Lyon, Marseille) :
Code du département [2 car], code de l’arrondissement [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_ARR + COM_ABS + SECTION'],
ARRAY['section','commune','Code INSEE de la commune.'],
ARRAY['section','prefixe',
'Le préfixe de section cadastrale permet d’identifier de manière unique des parcelles qui provient de communes fusionnées ou absorbées et de mémoire, existe aussi sur les communes découpées en arrondissements.
Si la section appartient à la commune absorbante, il est alors indiqué "000".'],
ARRAY['section','code','Code unique de la section cadastrale sur deux caractères.'],
ARRAY['section','created','Date de création de l’objet par la DGFiP.'],
ARRAY['section','updated','Date de dernière modification de l’objet par la DGFiP.'],
ARRAY['section',nomgeometrie,'Champs géometrique en Lambert93.'],	
---- subdivision fiscale
ARRAY['subdivision_fiscale','parcelle',
'Identifiant unique de la subdivision fiscale.
Référence de la subdivision obtenue par concaténation d’attributs : Code du département [2 car], code de la commune [3 car], code de la commune absorbée [3 car], section cadastrale [2 car], soit : IDU = CODE_DEP + CODE_COM + COM_ABS + SECTION
Cas particuliers des communes avec arrondissements municipaux (Paris, Lyon, Marseille) :
Code du département [2 car], code de l’arrondissement [3 car], code de la commune absorbée [3 car], section cadastrale [2 car] et numéro de parcelle [4 car], soit : IDU = CODE_DEP + CODE_ARR + COM_ABS + SECTION
Le code de la commune absorbée (COM_ABS) est égal à 000 lorsque la commune n’a pas fait l’objet de fusion avec une autre commune.'],	
ARRAY['subdivision_fiscale','lettre','Lettre indicative de subdivision fiscale.'],		
ARRAY['subdivision_fiscale','created','Date de création de l’objet par la DGFiP.'],
ARRAY['subdivision_fiscale','updated','Date de dernière modification de l’objet par la DGFiP.'],
ARRAY['subdivision_fiscale',nomgeometrie,'Champs géometrique en Lambert93.']	
];	
---- Boucle pour tous les commentaires de champs
FOR i_table IN 1..array_length(liste_valeur, 1) LOOP
---- Récupération des champs
---- Nom de la table
	select
		case
			when COVADIS is false then 
				lower(liste_valeur[i_table][1])
			else
				case
					when millesime is not null then
						'n_' || lower(liste_valeur[i_table][1]) || '_etalab_' || emprise || '_' || millesime
					else
						'n_' || lower(liste_valeur[i_table][1]) || '_etalab_' || emprise
				end
		end
		 into nom_table;
---- Nom du champs à commenter		
	SELECT lower(liste_valeur[i_table][2]) into champs;
---- Nom du commentaire	
	SELECT liste_valeur[i_table][3] into commentaires;
---- Execution de la requete
	IF EXISTS (SELECT relname FROM pg_class where relname='' || nom_table ) then
		req := '
				COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || champs || ' IS ''' || commentaires || ''';
				';
		RAISE NOTICE '%', req;
		EXECUTE(req);
	else
		req := '
				La table ' || nom_schema || '.' || nom_table || ' n´est pas présente pour le champs ' || champs || '.
				';
		RAISE NOTICE '%', req;
	END IF;
END LOOP; 
RETURN current_time;
END; 
$function$
;

COMMENT ON FUNCTION w_adl_delegue.set_comment_cadastre_etalab("varchar","bpchar","bpchar","bool") IS '[ADMIN - CADASTRE ETALAB] - Mise en place des commentaires

Option :
- nom du schéma où se trouvent les tables
- emprise sur 3 caractères selon la COVADIS ddd : 
	- ''fra'' : France Entière
	- ''000'' : France Métropolitaine
	- ''rrr'' : Numéro INSEE de la Région : ''r84'' pour Avergne-Rhône-Alpes
	- ''ddd'' : Numéro INSEE du département : ''038'' pour l''Isère
				non pris en compte si COVADIS = false
- millesime selon COVADIS : aaaa pour l''année du millesime ou null si pas de millesime
				non pris en compte si COVADIS = false
- COVADIS : nommage des tble selon la COVADIS : oui : true / non false

Tables concernées :
- bati
- commune
- feuille
- lieu_dit
- parcelle
- prefixe_section
- section
- subdivision_fiscale

amélioration à faire :

dernière MAJ : 04/04/2020';
