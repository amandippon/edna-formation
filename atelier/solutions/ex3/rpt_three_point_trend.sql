-- Évolution du tir à 3 points par saison (matchs avec box score, 2010+)
with games as (
    select *
    from {{ ref('fct_regular_season_games') }}
    where has_box_score
),
by_season as (
    select
        season,
        count(*)                              as games,
        sum(w_fga3 + l_fga3)::bigint          as fga3,
        sum(w_fgm3 + l_fgm3)::bigint          as fgm3,
        sum(w_fga + l_fga)::bigint            as fga
    from games
    group by season
),
final as (
    select
        season,
        games,
        fga3,
        fgm3,
        round(fga3::double / fga, 3)          as fga3_share,
        round(fgm3::double / fga3, 3)         as fg3_pct,
        round(fga3::double / (2 * games), 1)  as fga3_per_team_game
    from by_season
)
select * from final
