CREATE OR REPLACE FUNCTION w_fonctions.synthese_geometrie_schema(IN nom_schema text)
  RETURNS TABLE(nom_table text, champs_geometrie text, type_geometrie text, code_epsg integer, dim_geometrie integer, nb_entitees integer, nb_erreur_geom integer, longeur_tot_m integer, surface_tot_m2 text, surface_moy_m2 text, surface_maxi_m2 text, surface_mini_m2 text, nb_monogeometrie integer, nb_points integer) AS
$BODY$
BEGIN
FOR nom_table, champs_geometrie, type_geometrie, code_epsg, dim_geometrie IN SELECT f_table_name, f_geometry_column, type, srid, coord_dimension from geometry_columns WHERE f_table_schema = nom_schema ORDER BY f_table_name,f_geometry_column
    LOOP
    EXECUTE 'SELECT COUNT(*) FROM '||nom_schema||'."'||nom_table||'"' INTO nb_entitees ;
    EXECUTE 'SELECT COUNT(*) FROM "'||nom_schema||'"."'||nom_table||'" WHERE ST_isvalid('||champs_geometrie||') IS false' INTO nb_erreur_geom;
    EXECUTE 'SELECT sum(ST_Length('||champs_geometrie||'))::integer FROM "'||nom_schema||'"."'||nom_table||'"' INTO longeur_tot_m;
    EXECUTE 'SELECT sum(ST_AREA('||champs_geometrie||'))::numeric(20,2) FROM "'||nom_schema||'"."'||nom_table||'"' INTO surface_tot_m2;
    EXECUTE 'SELECT avg(ST_AREA('||champs_geometrie||'))::numeric(20,2) FROM "'||nom_schema||'"."'||nom_table||'"' INTO surface_moy_m2;
    EXECUTE 'SELECT max(ST_AREA('||champs_geometrie||'))::numeric(20,2) FROM "'||nom_schema||'"."'||nom_table||'"' INTO surface_maxi_m2;   
    EXECUTE 'SELECT min(ST_AREA('||champs_geometrie||'))::numeric(20,2) FROM "'||nom_schema||'"."'||nom_table||'"' INTO surface_mini_m2;
    EXECUTE 'SELECT sum(ST_NumGeometries('||champs_geometrie||'))::integer FROM "'||nom_schema||'"."'||nom_table||'"' INTO nb_monogeometrie;
        EXECUTE 'SELECT sum(ST_npoints('||champs_geometrie||'))::integer FROM "'||nom_schema||'"."'||nom_table||'"' INTO nb_points;

    RETURN NEXT ;
    END LOOP ;
END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
ALTER FUNCTION w_fonctions.synthese_geometrie_schema(text)
  OWNER TO postgres;
COMMENT ON FUNCTION w_fonctions.synthese_geometrie_schema(text) IS '22/06/2018 : synthèse des informations géométriques de tous les champs géométriques présents dans un schéma passé en paramètre

- paramètre 1 : nom du schéma';
