-- Test de l'atelier : renvoie une ligne par problème trouvé (0 ligne = test vert)
with expected as (
    select season, count(*) as games
    from {{ ref('fct_regular_season_games') }}
    where w_loc in ('H', 'A')
    group by season
)
select e.season, e.games as attendu, r.games as obtenu, r.home_win_pct
from expected e
left join {{ ref('rpt_home_advantage_by_season') }} r on e.season = r.season
where r.season is null                       -- saison manquante
   or r.games <> e.games                     -- mauvais nombre de matchs
   or r.home_wins > r.games
   or r.home_win_pct not between 0 and 1
