-- FUNCTION: r_cadastre_etalab_2018.set_comment_cadastre_etalab(boolean, boolean, character varying, character varying)

-- DROP FUNCTION r_cadastre_etalab_2018.set_comment_cadastre_etalab(boolean, boolean, character varying, character varying);

CREATE OR REPLACE FUNCTION r_cadastre_etalab_2018.set_comment_cadastre_etalab(
	covadis boolean DEFAULT false,
	millesimee boolean DEFAULT false,
	emprise character varying DEFAULT NULL::character varying,
	millesime character varying DEFAULT (
	date_part(
	'year'::text,
	CURRENT_DATE))::character(
	4))
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
/*
[ADMIN - CADASTRE ETALAB] - Administration d'un millesime du Cadastre Etalab une fois son import réalisé et les couches mises à la COVADIS

Mise en place des commentaires

Option :
- nommage COVADIS - par défault non
- couche millésimée - _aaaa - selon la COVADIS - par défault non
- si oui :
	emprise : ddd pour département, rrr pour région, 000 pour métropole, fra pour France entière,
	millesime : aaaa pour l’année du millesime

Tables concernées :
n_bati_etalab_ddd_aaaa
n_commune_etalab_ddd_aaaa
n_feuille_etalab_ddd_aaaa
n_lieu-dit_etalab_ddd_aaaa
n_parcelle_etalab_ddd_aaaa
n_section_etalab_ddd_aaaa

amélioration à faire :

dernière MAJ : 09/08/2019
*/
declare

object text;
r record;
req text;
veriftable character varying;
tb_table character varying[]; 			-- Liste des tables à traiter
nb_table integer; 						-- Nombre de tables
nom_table character varying; 			-- nom de la table en texte
nom_schema character varying; 			-- nom du schema de travail en texte
nomgeometrie character varying; 		-- nom de l'attribut qui contient la géométrie
i_table int2; 							-- Nombre de table dans la boucle Tables
tb_index character varying[]; 			-- Index à créer
nb_index integer; 						-- Nombre d'index à créér
nom_index character varying; 			-- nom du champs à indexer en texte
i_index int2;							-- Nombre d'index dans la boucle des index

begin

IF covadis is true
	THEN nom_schema := 'r_cadastre_etalab_' || millesime;
	ELSE nom_schema := 'public';
END IF;

IF covadis is true
	THEN nomgeometrie := 'geom';
	ELSE nomgeometrie := 'wkb_geometry';
END IF;

---- D. Mise en place des commentaires
---- D.1 n_bati_etalab_ddd_aaaa
IF covadis is true
	then
		IF millesimee is false
			THEN
				nom_table := 'n_bati_etalab_' || emprise;
			ELSE
				nom_table := 'n_bati_etalab_' || emprise || '_' || millesime;
		END IF;
	ELSE
		nom_table := 'bati_etalab';
END IF;

IF EXISTS (SELECT relname FROM pg_class where relname=nom_table) THEN
---- Commentaire Table ’
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Bâtiment de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Définitions, Commentaires :
Construction assise sur une ou plusieurs parcelles cadastrales

Contraintes : 
* entre objets identiques :
un bâtiment peut être à cheval sur plusieurs parcelles. L’élément de bâtiment est la partie de construction supportée par une seule parcelle.
Les éléments d’un même bâtiment doivent être en cohérence géométrique entre eux.
* entre objets différents :
les limites d’un bâtiment peuvent être en partie confondues avec celles des parcelles.
Toute limite de subdivision de section ou de section quipasse à l’intérieur d’un bâtiment doit scinder cet objet en deux bâtiments distincts. 
Lorsque l’on réunit deux parcelles sur lesquelles sont implantés deux bâtiments contigus, les bâtiments ne sont pas réunis.'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
---- Commentaires colonnes ’
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.type IS ''Type de bâtiment : 01 : bâti dur / 02 : bâti léger.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom IS ''Texte du bâtiment.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commune IS ''Commune du bâtiment.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.created IS ''Date de création de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.updated IS ''Date de dernière modification de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géometrique en Lambert93'';
	';
	RAISE NOTICE '%', req;
	EXECUTE(req);
ELSE
	RAISE NOTICE 'La table n’est pas présente : %', nom_table;
END IF;

---- D.2 n_commune_etalab_ddd_aaaa
IF covadis is true
	then
		IF millesimee is false
			THEN
				nom_table := 'n_commune_etalab_' || emprise;
			ELSE
				nom_table := 'n_commune_etalab_' || emprise || '_' || millesime;
		END IF;
	ELSE
		nom_table := 'commune_etalab';
END IF;

---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Commune de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Définitions, Commentaires : 
Territoire contenant un nombre entier de subdivisions de section cadastrales.
Son emprise est constituée à partir de l’union des subdivisions de section qui la composent au moment de l’échange.
Le contour de l’objet «COMMUNE» est calculé automatiquement à partir des subdivisions de section reçues, même si l’objet «COMMUNE» a été transmis dans l’échange.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id IS ''Identifiant unique de l’objet : Code INSEE de la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom IS ''Nom DGFiP de la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.created IS ''Date de création de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.updated IS ''Date de dernière modification de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géometrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

---- D3 n_feuille_etalab_ddd_aaaa
IF covadis is true
	then
		IF millesimee is false
			THEN
				nom_table := 'n_feuille_etalab_' || emprise;
			ELSE
				nom_table := 'n_feuille_etalab_' || emprise || '_' || millesime;
		END IF;
	ELSE
		nom_table := 'feuille_etalab';
END IF;

---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Feuille de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
En attente de métadonnées sur cadastre.data.gouv.fr.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id IS ''Identifiant unique de l’objet : Code INSEE de la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commune IS ''Nom DGFiP de la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.prefixe IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.section IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.qualite IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.modeconfection IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.created IS ''Date de création de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.updated IS ''Date de dernière modification de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs géometrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
		
---- D.4 n_lieu_dit_etalab_ddd_aaaa
IF covadis is true
	then
		IF millesimee is false
			THEN
				nom_table := 'n_lieu_dit_etalab_' || emprise;
			ELSE
				nom_table := 'n_lieu_dit_etalab_' || emprise || '_' || millesime;
		END IF;
	ELSE
		nom_table := 'lieu_dit_etalab';
END IF;

---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Lieu-dit de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Ensemble de parcelles entières comportant une même dénomination géographique résultant de l’usage.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='	
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.nom IS ''Nom DGFiP de la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commune IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.created IS ''Date de création de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.updated IS ''Date de dernière modification de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs geometrique en Lambert93'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

---- D.5 n_parcelle_etalab_ddd_aaaa
IF covadis is true
	then
		IF millesimee is false
			THEN
				nom_table := 'n_parcelle_etalab_' || emprise;
			ELSE
				nom_table := 'n_parcelle_etalab_' || emprise || '_' || millesime;
		END IF;
	ELSE
		nom_table := 'parcelle_etalab';
END IF;

---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Parcelle de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
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
Les limites parcellaires respectent le premier principe général présenté au paragraphe 7.2.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='			
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id IS ''Identifiant unique de l’objet : Code INSEE de la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commune IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.prefixe IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.section IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.numero IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.contenance IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.created IS ''Date de création de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.updated IS ''Date de dernière modification de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs geometrique en Lambert93'';		
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;		
	
---- D.6 n_section_etalab_ddd_aaaa
IF covadis is true
	then
		IF millesimee is false
			THEN
				nom_table := 'n_section_etalab_' || emprise;
			ELSE
				nom_table := 'n_section_etalab_' || emprise || '_' || millesime;
		END IF;
	ELSE
		nom_table := 'section_etalab';
END IF;

---- Commentaire Table
	req :='
		COMMENT ON TABLE ' || nom_schema || '.' || nom_table || ' IS ''Section de la DGFIP pour le millésime ' || millesime || ' et l’emprise ' || emprise || '.
Partie du plan cadastral correspondant à une portion du territoire communal et comportant, suivant le cas, une ou plusieurs subdivisions de section.
Cet objet est obligatoire dans tous les lots formant l’échange.'';
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;
---- Commentaire colonnes
	req :='			
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.id IS ''Identifiant unique de l’objet : Code INSEE de la commune.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.commune IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.prefixe IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.code IS ''En attente de métadonnées sur cadastre.data.gouv.fr.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.created IS ''Date de création de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.updated IS ''Date de dernière modification de l’objet par la DGFiP.'';
		COMMENT ON COLUMN ' || nom_schema || '.' || nom_table || '.' || nomgeometrie || ' IS ''Champs geometrique en Lambert93'';	
	';
	EXECUTE(req);
	RAISE NOTICE '%', req;

RETURN current_time;
END; 
$BODY$;

ALTER FUNCTION r_cadastre_etalab_2018.set_comment_cadastre_etalab(boolean, boolean, character varying, character varying)
    OWNER TO postgres;

COMMENT ON FUNCTION r_cadastre_etalab_2018.set_comment_cadastre_etalab(boolean, boolean, character varying, character varying)
    IS '[ADMIN - CADASTRE ETALAB] - Administration d''un millesime du Cadastre Etalab une fois son import réalisé et les couches mises à la COVADIS

Mise en place des commentaires

Option :
- nommage COVADIS - par défault non
- couche millésimée - _aaaa - selon la COVADIS - par défault non
- si oui :
	emprise : ddd pour département, rrr pour région, 000 pour métropole, fra pour France entière,
	millesime : aaaa pour l’année du millesime

Tables concernées :
n_bati_etalab_ddd_aaaa
n_commune_etalab_ddd_aaaa
n_feuille_etalab_ddd_aaaa
n_lieu-dit_etalab_ddd_aaaa
n_parcelle_etalab_ddd_aaaa
n_section_etalab_ddd_aaaa

amélioration à faire :

dernière MAJ : 09/08/2019';
