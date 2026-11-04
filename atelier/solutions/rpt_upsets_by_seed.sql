-- Upsets du tournoi NCAA selon l'affiche (seed du favori contre seed de l'outsider)
with games as (
    select *
    from {{ ref('fct_tourney_games') }}
    where w_seed_number <> l_seed_number      -- même seed : pas de favori
),
matchups as (
    select
        least(w_seed_number, l_seed_number)        as favorite_seed,
        greatest(w_seed_number, l_seed_number)     as underdog_seed,
        is_upset
    from games
),
final as (
    select
        favorite_seed || ' vs ' || underdog_seed   as matchup,
        favorite_seed,
        underdog_seed,
        underdog_seed - favorite_seed              as seed_gap,
        count(*)                                   as games,
        sum(case when is_upset then 1 else 0 end)::bigint as upsets,
        round(avg(case when is_upset then 1.0 else 0.0 end), 3) as upset_pct
    from matchups
    group by favorite_seed, underdog_seed
)
select * from final
