-- Exercice bonus : le tir à 3 points prend-il le pouvoir ?
-- Objectif : une ligne par saison avec les tirs à 3 points tentés et réussis,
-- leur part dans tous les tirs tentés et l'adresse à 3 points.
-- Source : marts.fct_regular_season_games (une ligne par match)
--   colonnes utiles : has_box_score, w_fga3 / l_fga3 (3 pts tentés), w_fgm3 / l_fgm3 (3 pts réussis),
--   w_fga / l_fga (tous les tirs tentés). Préfixe w_ = gagnant, l_ = perdant.
-- Vérifier : task build   (tous les tests doivent passer au vert)

with games as (
    select *
    from {{ ref('fct_regular_season_games') }}
    -- TODO 1 : ne garder que les matchs qui ont un box score (2010 et après)
),
by_season as (
    select
        season,
        count(*)                as games,
        null::bigint            as fga3,    -- TODO 2 : somme des 3 pts tentés des deux équipes (w_fga3 + l_fga3),
                                            --   convertie avec ::bigint : sum() renvoie sinon un HUGEINT, mal géré par Superset
        null::bigint            as fgm3,    -- TODO 3 : somme des 3 pts réussis des deux équipes
        null::bigint            as fga      -- TODO 4 : somme de tous les tirs tentés des deux équipes
    from games
    group by season
),
final as (
    select
        season,
        games,
        fga3,
        fgm3,
        null::double            as fga3_share,          -- TODO 5 : fga3 / fga, arrondi à 3 décimales
        null::double            as fg3_pct,             -- TODO 6 : fgm3 / fga3, arrondi à 3 décimales
        null::double            as fga3_per_team_game   -- TODO 7 : fga3 / (2 * games), arrondi à 1 décimale
    from by_season
)
select * from final
