-- Mission 1 (staging) : stg_tourney_seeds
--
-- Un modèle dbt est un simple SELECT. dbt-duckdb l'exécute dans DuckDB et enregistre le
-- résultat dans la table staging.stg_tourney_seeds. Toutes les fonctions SQL de DuckDB sont
-- disponibles : https://duckdb.org/docs/current/sql/functions/text
--
-- ENTRÉE : le fichier Parquet WNCAATourneySeeds (une ligne par équipe qualifiée et par saison)
--   Season | TeamID | Seed
--   2019   | 3163   | 'W02'     <- Seed = lettre de la région (W, X, Y ou Z) + numéro sur 2 chiffres
--   2019   | 3346   | 'Z11'
--
-- SORTIE ATTENDUE : la même ligne, colonnes renommées, et le seed découpé en deux
--   season | team_id | seed_raw | seed_region | seed_number
--   2019   | 3163    | 'W02'    | 'W'         | 2            <- seed_number est un entier
--   2019   | 3346    | 'Z11'    | 'Z'         | 11
--
-- À FAIRE
--   TODO 1 et 2 (ce fichier) : remplacer les deux null::... par une expression calculée à partir
--                              de la colonne Seed. Garder les alias (as seed_region, as seed_number).
--   TODO 3 (models/staging/_staging_models.yml) : déclarer les tests de seed_region et seed_number.
--
-- Aperçu du résultat : task show M=stg_tourney_seeds
-- Vérifier         : task build (au vert quand la mission est finie)
-- Détail d'un échec : task show M=mission_1_stg_tourney_seeds
-- Modèle voisin pour s'inspirer : stg_teams.sql

with source as (
    select * from read_parquet('../processed-resources/WNCAATourneySeeds/*.parquet')
),
renamed as (
    select
        Season          as season,
        TeamID          as team_id,
        Seed            as seed_raw,
        null::varchar   as seed_region,   -- TODO 1 : premier caractère de Seed.
                                          --   left(texte, n) renvoie les n premiers caractères :
                                          --   left('W02', 1) = 'W'
        null::integer   as seed_number    -- TODO 2 : les chiffres de Seed, en entier.
                                          --   regexp_extract(texte, '[0-9]+') renvoie les chiffres, en texte :
                                          --   regexp_extract('W02', '[0-9]+') = '02'
                                          --   cast(texte as integer) convertit en entier :
                                          --   cast('02' as integer) = 2
                                          --   Les deux fonctions s'imbriquent : cast(regexp_extract(...) as integer)
    from source
)
select * from renamed
