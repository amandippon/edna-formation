with games as (
    select * from {{ ref('fct_regular_season_games') }}
),
all_team_games as (
    select season, w_team_id as team_id, w_score as pts_scored, l_score as pts_allowed, 1 as is_win
    from games

    union all

    select season, l_team_id as team_id, l_score as pts_scored, w_score as pts_allowed, 0 as is_win
    from games
),
team_stats as (
    select
        season,
        team_id,
        count(*)                                            as games_played,
        sum(is_win)                                         as wins,
        count(*) - sum(is_win)                              as losses,
        round(sum(is_win)::double / count(*), 3)            as win_pct,
        round(avg(pts_scored), 1)                           as avg_pts_scored,
        round(avg(pts_allowed), 1)                          as avg_pts_allowed,
        round(avg(pts_scored - pts_allowed), 1)             as avg_pt_diff
    from all_team_games
    group by season, team_id
),
tourney_seeds as (
    select
        season,
        team_id,
        seed_number as tourney_seed_number,
        true        as made_tourney
    from {{ ref('stg_tourney_seeds') }}
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
final as (
    select
        t.team_name,
        t.team_state,
        t.team_state_iso,
        ts.season,
        s.season_label,
        ts.games_played,
        ts.wins,
        ts.losses,
        ts.win_pct,
        ts.avg_pts_scored,
        ts.avg_pts_allowed,
        ts.avg_pt_diff,
        coalesce(seed.made_tourney, false)  as made_tourney,
        seed.tourney_seed_number
    from team_stats ts
    left join teams          t    on ts.team_id = t.team_id
    left join seasons        s    on ts.season  = s.season
    left join tourney_seeds  seed on ts.season  = seed.season and ts.team_id = seed.team_id
)
select * from final
