with games as (
    select * from {{ ref('fct_regular_season_games') }}
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
team_games as (
    select season, w_team_id as team_id, 1 as is_win, w_score as pts_scored, l_score as pts_allowed
    from games

    union all

    select season, l_team_id as team_id, 0 as is_win, l_score as pts_scored, w_score as pts_allowed
    from games
),
aggregated as (
    select
        season,
        team_id,
        count(*)                                            as games_played,
        sum(is_win)                                         as wins,
        count(*) - sum(is_win)                              as losses,
        round(sum(is_win)::double / count(*), 3)            as win_pct,
        sum(pts_scored)                                     as total_pts_scored,
        sum(pts_allowed)                                    as total_pts_allowed,
        round(avg(pts_scored), 1)                           as avg_pts_scored,
        round(avg(pts_allowed), 1)                          as avg_pts_allowed,
        round(avg(pts_scored - pts_allowed), 1)             as avg_pt_diff
    from team_games
    group by season, team_id
),
ranked as (
    select
        *,
        rank() over (partition by season order by win_pct desc, avg_pt_diff desc) as season_rank
    from aggregated
),
final as (
    select
        t.team_name,
        t.team_state,
        t.team_state_iso,
        s.season_label,
        r.season,
        r.season_rank,
        r.games_played,
        r.wins,
        r.losses,
        r.win_pct,
        r.total_pts_scored,
        r.total_pts_allowed,
        r.avg_pts_scored,
        r.avg_pts_allowed,
        r.avg_pt_diff
    from ranked r
    left join teams   t on r.team_id = t.team_id
    left join seasons s on r.season  = s.season
)
select * from final
