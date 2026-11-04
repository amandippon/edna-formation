-- Test de l'atelier : renvoie une ligne par problème trouvé (0 ligne = test vert)
with expected as (
    select season, count(*) as games
    from {{ ref('fct_regular_season_games') }}
    where has_box_score
    group by season
)
select e.season, e.games as attendu, r.games as obtenu, r.fga3_share, r.fg3_pct
from expected e
left join {{ ref('rpt_three_point_trend') }} r on e.season = r.season
where r.season is null
   or r.games <> e.games
   or r.fgm3 > r.fga3
   or r.fga3_share not between 0 and 1
   or r.fg3_pct not between 0 and 1
