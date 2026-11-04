-- Mission 2 (marts) : dim_tourney_seeds
--
-- Un modèle dbt ne lit jamais une table par son nom : il passe par ref('<modèle>'), entre doubles
-- accolades, comme la CTE seeds ci-dessous. dbt remplace ref() par le nom complet de la table
-- et en déduit l'ordre de construction (le DAG).
--
-- ENTRÉES (trois modèles staging, exemple pour Connecticut en 2019)
--   stg_tourney_seeds : season | team_id | seed_raw | seed_region | seed_number
--                       2019   | 3163    | 'W02'    | 'W'         | 2
--   stg_teams         : team_id | team_name
--                       3163    | 'Connecticut'
--   stg_seasons       : season | region_w | region_x  | region_y     | region_z
--                       2019   | 'Albany' | 'Chicago' | 'Greensboro' | 'Portland'
--
-- SORTIE ATTENDUE : une ligne par équipe qualifiée et par saison (1 408 lignes)
--   season | team_id | team_name     | seed_raw | seed_region | seed_number | region_name
--   2019   | 3163    | 'Connecticut' | 'W02'    | 'W'         | 2           | 'Albany'
--   region_name = la colonne region_w, region_x, region_y ou region_z qui correspond à seed_region.
--
-- À FAIRE
--   TODO 1 : une CTE teams qui lit stg_teams avec ref (colonnes team_id et team_name).
--   TODO 2 : une CTE seasons qui lit stg_seasons avec ref (toutes les colonnes).
--   TODO 3 : joindre teams sur team_id, et prendre team_name.
--   TODO 4 : joindre seasons sur season, puis calculer region_name avec un case.
--
-- Aperçu du résultat : task show M=dim_tourney_seeds
-- Vérifier         : task build (au vert quand la mission est finie)
-- Détail d'un échec : task show M=mission_2_dim_tourney_seeds
-- SQL généré par dbt : target/compiled/transformation/models/marts/dim_tourney_seeds.sql

with seeds as (
    select * from {{ ref('stg_tourney_seeds') }}
),
-- TODO 1 : teams as ( select team_id, team_name from <ref vers stg_teams> ),
-- TODO 2 : seasons as ( select * from <ref vers stg_seasons> ),
final as (
    select
        s.season,
        s.team_id,
        null::varchar   as team_name,     -- TODO 3 : t.team_name, après la jointure sur teams
        s.seed_raw,
        s.seed_region,
        s.seed_number,
        null::varchar   as region_name    -- TODO 4 : selon s.seed_region, la bonne colonne de seasons :
                                          --   case s.seed_region
                                          --       when 'W' then se.region_w
                                          --       when 'X' then ...
                                          --   end
    from seeds s
    -- TODO 3 et 4 : les jointures, en left join pour garder toutes les lignes de seeds :
    --   left join teams   t  on ...
    --   left join seasons se on ...
)
select * from final
