-- Mission 3, sujet libre : avantage du terrain par saison
-- Objectif : une ligne par saison avec le nombre de matchs joués chez une équipe,
-- le nombre gagnés par l'équipe qui reçoit, et l'écart de score moyen pour elle.
-- Source : marts.fct_regular_season_games (une ligne par match, format gagnant / perdant)
--   w_loc = 'H' : le gagnant jouait à domicile ; 'A' : il jouait à l'extérieur ; 'N' : terrain neutre
-- Vérifier : task build   (tous les tests doivent passer au vert)

with games as (
    select season, w_loc, score_margin
    from {{ ref('fct_regular_season_games') }}
    -- TODO 1 : ne garder que les matchs à domicile ou à l'extérieur (exclure 'N')
),
by_season as (
    select
        season,
        count(*)                as games,
        null::bigint            as home_wins,        -- TODO 2 : compter les matchs où w_loc = 'H'
        null::double            as avg_home_margin   -- TODO 3 : moyenne de score_margin si l'équipe qui reçoit gagne,
                                                     --          de -score_margin si elle perd
    from games
    group by season
),
final as (
    select
        b.season,
        null::varchar           as season_label,     -- TODO 4 : récupérer season_label depuis dim_seasons (jointure)
        b.games,
        b.home_wins,
        null::double            as home_win_pct,     -- TODO 5 : home_wins / games, arrondi à 3 décimales
        round(b.avg_home_margin, 1) as avg_home_margin
    from by_season b
)
select * from final
