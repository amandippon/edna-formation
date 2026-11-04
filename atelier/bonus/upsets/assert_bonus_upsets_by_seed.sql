-- Test de l'exercice bonus : renvoie une ligne par problème trouvé (0 ligne = test vert)
with expected as (
    select count(*) as games, sum(case when is_upset then 1 else 0 end) as upsets
    from {{ ref('fct_tourney_games') }}
    where w_seed_number <> l_seed_number
),
actual as (
    select sum(games) as games, sum(upsets) as upsets, max(upset_pct) as max_pct, min(seed_gap) as min_gap
    from {{ ref('rpt_upsets_by_seed') }}
)
select e.games as matchs_attendus, a.games as matchs_obtenus, e.upsets as upsets_attendus, a.upsets as upsets_obtenus
from expected e cross join actual a
where a.games is distinct from e.games
   or a.upsets is distinct from e.upsets
   or a.max_pct > 1
   or a.min_gap < 1
