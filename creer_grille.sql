CREATE OR REPLACE FUNCTION w_fonctions.creer_grille(nom_schema TEXT, nom_table TEXT, pas_metre integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$

/*
[ADMIN] - Crée une grille qui contient l'ensemble de la couche en paramètre, selon un pas en paramètre aussi.

Paramètres : 
- nom_schema = 'nomduschema' pour le schéma d'origine de la table et d'arrivée de la grille
- nom_table = 'nomdelatable' pour la table d'origine, la grille d'arrivée s'appelle grille_nomdelatable
- pas_metre = 10 pour le pas de la grille qui en en metre car par defaut Lambert93

Taches réalisées :
- Recherche des coordonnées de la BoudingBox. Celles-ci sont arrondies à un mulptiple du pas
- Création de digonale de la grille
- Création de la grille
- Ajout de l'identifiant qui correspond au x_min concatène y_min

Tables concernées :
- paramètre en entrée

amélioration à faire :
- passer la projection en paramètre : par defaut à 2154. 

dernière MAJ : 21/02/2020
*/

DECLARE
    req text;
BEGIN
req = '
DROP TABLE IF EXISTS ' || nom_schema || '.grille_' || nom_table || ';
CREATE TABLE ' || nom_schema || '.grille_' || nom_table || ' AS 
WITH coordonnees AS (
	WITH diagonale_simple AS (
		WITH box_arrondi AS ( -- Requête de récupération des coordonnées englobantes et arrondies de l´objet

				SELECT		
					--ST_Xmin(Box2D(ST_Collect(geom))) AS Xmin,  -- a utiliser sans arrondi
					(((CAST(ST_Xmin(Box2D(ST_Collect(geom)))AS INTEGER)/' || pas_metre || ')-0)*' || pas_metre || ') AS xmin_arrondi,
					--ST_Xmax(Box2D(ST_Collect(geom))) AS Xmax, -- a utiliser sans arrondi
					(((CAST(ST_Xmax(Box2D(ST_Collect(geom)))AS INTEGER)/' || pas_metre || ')+1)*' || pas_metre || ') AS xmax_arrondi,
					--ST_Ymin(Box2D(ST_Collect(geom))) AS Ymin, -- a utiliser sans arrondi
					(((CAST(ST_Ymin(Box2D(ST_Collect(geom)))AS INTEGER)/' || pas_metre || ')-0)*' || pas_metre || ') AS ymin_arrondi,
					--ST_Ymax(Box2D(ST_Collect(geom))) AS Ymax, -- a utiliser sans arrondi
					(((CAST(ST_Ymax(Box2D(ST_Collect(geom)))AS INTEGER)/' || pas_metre || ')+1)*' || pas_metre || ') AS ymax_arrondi

				FROM ' || nom_schema || '.' || nom_table || '

				) -- fin box_arrondi

			SELECT		-- Génération des coordonnées de la grille
				generate_series (xmin_arrondi,xmax_arrondi-1,' || pas_metre || ') AS xmin_box,

				-- generate_series (t1.xmin_arrondi,t1.xmax_arrondi,' || pas_metre || ')+' || pas_metre || ' AS xmax_box,
				-- pour mémoire car inutile passage de xmin à xmax se retrouver très facilement

				generate_series (Ymin_arrondi,Ymax_arrondi-1,' || pas_metre || ') AS ymin_box

				-- generate_series (t2.ymin_arrondi,t2.ymax_arrondi,' || pas_metre || ')+' || pas_metre || ' AS ymax_box
				-- pour mémoire car inutile passage de ymin à ymax se retrouver très facilement

			FROM box_arrondi -- Fin de la grille

			) -- fin de la diagonale

	SELECT DISTINCT t1.xmin_box, t2.ymin_box -- supprime les carrés en doublons

	FROM diagonale_simple t1 CROSS JOIN diagonale_simple t2

	) -- fin de coordonnées

 SELECT -- pas ici le SELECT DISTINCT
	xmin_box||''_''||ymin_box::character varying(80) AS id, -- id correspond au x_min concatène y_min
	ST_SetSRID(ST_MakeBox2D(ST_Point(xmin_box,ymin_box),ST_Point(xmin_box + ' || pas_metre || ',ymin_box + ' || pas_metre || ')),2154)::geometry(Polygon,2154) AS geom
FROM coordonnees
WHERE xmin_box IS NOT NULL AND ymin_box IS NOT NULL;';
RAISE NOTICE '%', req;
EXECUTE(req);


req := '
DROP INDEX IF EXISTS ' || nom_schema || '.grille_' || nom_table || '_id_idx;
CREATE INDEX grille_' || nom_table || '_id_idx ON ' || nom_schema || '.grille_' || nom_table || ' USING brin (id) TABLESPACE index;
';
RAISE NOTICE '%', req;
EXECUTE(req);

req := '
DROP INDEX IF EXISTS grille_' || nom_schema || '.grille_' || nom_table || '_geom_gist;
CREATE INDEX grille_' || nom_table || '_geom_gist ON ' || nom_schema || '.grille_' || nom_table || ' USING gist (geom) TABLESPACE index;
ALTER TABLE IF EXISTS ' || nom_schema || '.grille_' || nom_table || ' CLUSTER ON grille_' || nom_table || '_geom_gist;
';
RAISE NOTICE '%', req;
EXECUTE(req);

RETURN 'Fait avec succes !';

END ;
$function$
;

COMMENT ON FUNCTION w_fonctions.creer_grille("text","text","int4") IS '[ADMIN] - Crée une grille qui contient l''ensemble de la couche en paramètre, selon un pas en paramètre aussi.

Paramètres : 
- nom_schema = ''nomduschema'' pour le schéma d''origine de la table et d''arrivée de la grille
- nom_table = ''nomdelatable'' pour la table d''origine, la grille d''arrivée s''appelle grille_nomdelatable
- pas_metre = 10 pour le pas de la grille qui en en metre car par defaut Lambert93

Taches réalisées :
- Recherche des coordonnées de la BoudingBox. Celles-ci sont arrondies à un mulptiple du pas
- Création de digonale de la grille
- Création de la grille
- Ajout de l''identifiant qui correspond au x_min concatène y_min

Tables concernées :
- paramètre en entrée

amélioration à faire :
- passer la projection en paramètre : par defaut à 2154.

dernière MAJ : 21/02/2020';
