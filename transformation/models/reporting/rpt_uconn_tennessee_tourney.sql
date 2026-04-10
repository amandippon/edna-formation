with tourney as (
    select * from {{ ref('fct_tourney_games') }}
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
tourney_seeds as (
    select season, team_id, seed_number, seed_region
    from {{ ref('stg_tourney_seeds') }}
),
-- Connecticut = 3163, Tennessee = 3397
rival_ids as (
    select team_id from teams where team_name in ('Connecticut', 'Tennessee')
),
-- Unpivot tournament games: one row per team per game
team_tourney_games as (
    select
        g.season,
        g.w_team_id                            as team_id,
        1                                      as is_win,
        g.w_score                              as pts_scored,
        g.l_score                              as pts_allowed,
        g.score_margin,
        g.is_upset,
        g.seed_difference,
        g.has_box_score,
        g.w_fgm as fgm, g.w_fga as fga, g.w_fgm3 as fgm3, g.w_fga3 as fga3,
        g.w_ftm as ftm, g.w_fta as fta,
        g.w_reb as reb, g.w_or as off_reb, g.w_dr as def_reb,
        g.w_ast as ast, g.w_to as tov, g.w_stl as stl, g.w_blk as blk, g.w_pf as pf
    from tourney g
    where g.w_team_id in (select team_id from rival_ids)

    union all

    select
        g.season,
        g.l_team_id                            as team_id,
        0                                      as is_win,
        g.l_score                              as pts_scored,
        g.w_score                              as pts_allowed,
        -g.score_margin,
        g.is_upset,
        g.seed_difference,
        g.has_box_score,
        g.l_fgm, g.l_fga, g.l_fgm3, g.l_fga3,
        g.l_ftm, g.l_fta,
        g.l_reb, g.l_or, g.l_dr,
        g.l_ast, g.l_to, g.l_stl, g.l_blk, g.l_pf
    from tourney g
    where g.l_team_id in (select team_id from rival_ids)
),
aggregated as (
    select
        tg.season,
        tg.team_id,
        count(*)                                                    as tourney_games,
        sum(tg.is_win)                                              as tourney_wins,
        count(*) - sum(tg.is_win)                                   as tourney_losses,
        round(avg(tg.pts_scored), 1)                                as avg_pts_scored,
        round(avg(tg.pts_allowed), 1)                               as avg_pts_allowed,
        round(avg(tg.pts_scored - tg.pts_allowed), 1)               as avg_pt_diff,
        count(case when tg.is_upset then 1 end)                     as upsets_involved,
        -- box score (null before 2010)
        round(avg(tg.fgm), 1)                                      as avg_fgm,
        round(avg(tg.fga), 1)                                      as avg_fga,
        round(sum(tg.fgm)::double / nullif(sum(tg.fga), 0), 3)     as fg_pct,
        round(avg(tg.fgm3), 1)                                     as avg_fgm3,
        round(avg(tg.fga3), 1)                                     as avg_fga3,
        round(sum(tg.fgm3)::double / nullif(sum(tg.fga3), 0), 3)   as fg3_pct,
        round(avg(tg.ftm), 1)                                      as avg_ftm,
        round(avg(tg.fta), 1)                                      as avg_fta,
        round(sum(tg.ftm)::double / nullif(sum(tg.fta), 0), 3)     as ft_pct,
        round(avg(tg.reb), 1)                                      as avg_reb,
        round(avg(tg.off_reb), 1)                                   as avg_off_reb,
        round(avg(tg.def_reb), 1)                                   as avg_def_reb,
        round(avg(tg.ast), 1)                                      as avg_ast,
        round(avg(tg.tov), 1)                                      as avg_tov,
        round(avg(tg.stl), 1)                                      as avg_stl,
        round(avg(tg.blk), 1)                                      as avg_blk,
        round(avg(tg.pf), 1)                                       as avg_pf
    from team_tourney_games tg
    group by tg.season, tg.team_id
),
final as (
    select
        t.team_name,
        t.team_state,
        t.team_state_iso,
        s.season_label,
        a.season,
        ts.seed_number,
        ts.seed_region,
        a.tourney_games,
        a.tourney_wins,
        a.tourney_losses,
        case
            when a.tourney_wins = 6 then 'Champion'
            when a.tourney_wins = 5 then 'Runner-Up'
            when a.tourney_wins = 4 then 'Final Four'
            when a.tourney_wins = 3 then 'Elite Eight'
            when a.tourney_wins = 2 then 'Sweet Sixteen'
            when a.tourney_wins = 1 then 'Second Round'
            else 'First Round Exit'
        end                             as tournament_result,
        a.tourney_wins = 6              as is_champion,
        a.avg_pts_scored,
        a.avg_pts_allowed,
        a.avg_pt_diff,
        a.upsets_involved,
        a.avg_fgm,
        a.avg_fga,
        a.fg_pct,
        a.avg_fgm3,
        a.avg_fga3,
        a.fg3_pct,
        a.avg_ftm,
        a.avg_fta,
        a.ft_pct,
        a.avg_reb,
        a.avg_off_reb,
        a.avg_def_reb,
        a.avg_ast,
        a.avg_tov,
        a.avg_stl,
        a.avg_blk,
        a.avg_pf
    from aggregated a
    left join teams         t  on a.team_id = t.team_id
    left join seasons       s  on a.season  = s.season
    left join tourney_seeds ts on a.season  = ts.season and a.team_id = ts.team_id
)
select * from final
