# dterce.ressource_covadis

Ensemble de scripts SQL pour administrer les référentiels sous PostgreSQL/Postgis selon les règles de nommage prescrites par la COVADIS (http://www.geoinformations.developpement-durable.gouv.fr/covadis-r425.html)

D'une manière générale :
- set_admin_xxxxxxxxxx : administration du référentiel qui apparait dans le nom ainsi que sa version,
- set_comment_xxxxxxxxxx : mets les commentaires sur tables et les attributs de toutes les tables d'un référentiel IGN.

Les paramètres le plus souvent :
- nom du schéma où sont placées les tables,
- emprise selon les règles de la COVADIS : 000 pour France Métro / rrr pour les Régions, ddd pour les départements,
- millesime : AAAA

Pour avoir plus de détail sur les paramètres et les taches réalisées, tout est décrit dans la première partie du corps du code. Par exemple pour ADMIN EXPRESS® de l'IGN :

[ADMIN - ADMIN_EXPRESS] - Mise en place des taches d'administration pour un millesime d'ADMIN EXPRESS® de l'IGN selon le millesime et l'emprise :

Taches réalisées :
A - Re-nommage des tables
B. Optimisation de base sur l'ensemble des fichiers
B.1 Vérification du nom du champs géométrie
B.2 Suppression des champs inutiles
B.3 Correction des erreurs sur la géométrie
B.4 Contraintes géométriques de la table
B.5 Ajout des index spatiaux et cluster
B.6 Ajout des index attributaires non existants
B.7 clés primaires sur le champs id
C. Travail à la Table
C.1 n_adm_exp_arrondissement_dpt_ddd_aaaa
C.2 n_adm_exp_chef_lieu_ddd_aaaa
C.3 n_adm_exp_commune_ddd_aaaa
C.4 n_adm_exp_departement_ddd_aaaa
C.5 n_adm_exp_epci_ddd_aaaa
C.6 n_adm_exp_region_ddd_aaaa

Tables concernées :

amélioration à faire : option nommage COG en paramètre


