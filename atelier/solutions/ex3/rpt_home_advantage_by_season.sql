-- Avantage du terrain par saison (saison régulière, matchs non neutres)
with games as (
    select season, w_loc, score_margin
    from {{ ref('fct_regular_season_games') }}
    where w_loc in ('H', 'A')          -- on écarte les matchs sur terrain neutre
),
by_season as (
    select
        season,
        count(*)                                                   as games,
        sum(case when w_loc = 'H' then 1 else 0 end)::bigint       as home_wins,
        avg(case when w_loc = 'H' then score_margin
                 else -score_margin end)                           as avg_home_margin
    from games
    group by season
),
final as (
    select
        s.season,
        s.season_label,
        b.games,
        b.home_wins,
        round(b.home_wins::double / b.games, 3)   as home_win_pct,
        round(b.avg_home_margin, 1)               as avg_home_margin
    from by_season b
    left join {{ ref('dim_seasons') }} s on b.season = s.season
)
select * from final
