with regular as (
    select * from {{ ref('fct_regular_season_games') }}
),
tourney as (
    select * from {{ ref('fct_tourney_games') }}
),
all_games as (
    select
        season, day_num, game_type,
        w_team_id, l_team_id,
        w_score, l_score,
        game_location,
        has_box_score,
        w_fgm, w_fga, w_fgm3, w_fga3, w_ftm, w_fta,
        w_reb, w_or, w_dr, w_ast, w_to, w_stl, w_blk, w_pf,
        l_fgm, l_fga, l_fgm3, l_fga3, l_ftm, l_fta,
        l_reb, l_or, l_dr, l_ast, l_to, l_stl, l_blk, l_pf
    from regular

    union all

    select
        season, day_num, game_type,
        w_team_id, l_team_id,
        w_score, l_score,
        game_location,
        has_box_score,
        w_fgm, w_fga, w_fgm3, w_fga3, w_ftm, w_fta,
        w_reb, w_or, w_dr, w_ast, w_to, w_stl, w_blk, w_pf,
        l_fgm, l_fga, l_fgm3, l_fga3, l_ftm, l_fta,
        l_reb, l_or, l_dr, l_ast, l_to, l_stl, l_blk, l_pf
    from tourney
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
tourney_seeds as (
    select season, team_id, seed_number as tourney_seed_number, true as made_tourney
    from {{ ref('stg_tourney_seeds') }}
),
-- Connecticut (3163) and Tennessee (3397)
rival_ids as (
    select team_id from teams where team_name in ('Connecticut', 'Tennessee')
),
-- Unpivot: one row per team per game (as winner or loser)
team_games as (
    select
        g.season,
        g.w_team_id                            as team_id,
        1                                      as is_win,
        g.w_score                              as pts_scored,
        g.l_score                              as pts_allowed,
        g.game_location,
        g.game_type,
        g.has_box_score,
        g.w_fgm                                as fgm,
        g.w_fga                                as fga,
        g.w_fgm3                               as fgm3,
        g.w_fga3                               as fga3,
        g.w_ftm                                as ftm,
        g.w_fta                                as fta,
        g.w_reb                                as reb,
        g.w_or                                 as off_reb,
        g.w_dr                                 as def_reb,
        g.w_ast                                as ast,
        g.w_to                                 as tov,
        g.w_stl                                as stl,
        g.w_blk                                as blk,
        g.w_pf                                 as pf
    from all_games g
    where g.w_team_id in (select team_id from rival_ids)

    union all

    select
        g.season,
        g.l_team_id                            as team_id,
        0                                      as is_win,
        g.l_score                              as pts_scored,
        g.w_score                              as pts_allowed,
        case g.game_location
            when 'Home' then 'Away'
            when 'Away' then 'Home'
            else 'Neutral'
        end                                    as game_location,
        g.game_type,
        g.has_box_score,
        g.l_fgm                                as fgm,
        g.l_fga                                as fga,
        g.l_fgm3                               as fgm3,
        g.l_fga3                               as fga3,
        g.l_ftm                                as ftm,
        g.l_fta                                as fta,
        g.l_reb                                as reb,
        g.l_or                                 as off_reb,
        g.l_dr                                 as def_reb,
        g.l_ast                                as ast,
        g.l_to                                 as tov,
        g.l_stl                                as stl,
        g.l_blk                                as blk,
        g.l_pf                                 as pf
    from all_games g
    where g.l_team_id in (select team_id from rival_ids)
),
aggregated as (
    select
        tg.season,
        tg.team_id,
        -- overall
        count(*)                                                            as games_played,
        sum(tg.is_win)                                                      as wins,
        count(*) - sum(tg.is_win)                                           as losses,
        round(sum(tg.is_win)::double / count(*), 3)                         as win_pct,
        sum(tg.pts_scored)                                                  as total_pts_scored,
        sum(tg.pts_allowed)                                                 as total_pts_allowed,
        round(avg(tg.pts_scored), 1)                                        as avg_pts_scored,
        round(avg(tg.pts_allowed), 1)                                       as avg_pts_allowed,
        round(avg(tg.pts_scored - tg.pts_allowed), 1)                       as avg_pt_diff,
        -- win rate by location
        count(case when tg.game_location = 'Home' then 1 end)              as home_games,
        sum(case when tg.game_location = 'Home' then tg.is_win else 0 end) as home_wins,
        round(
            sum(case when tg.game_location = 'Home' then tg.is_win else 0 end)::double
            / nullif(count(case when tg.game_location = 'Home' then 1 end), 0), 3
        )                                                                   as home_win_pct,
        count(case when tg.game_location = 'Away' then 1 end)              as away_games,
        sum(case when tg.game_location = 'Away' then tg.is_win else 0 end) as away_wins,
        round(
            sum(case when tg.game_location = 'Away' then tg.is_win else 0 end)::double
            / nullif(count(case when tg.game_location = 'Away' then 1 end), 0), 3
        )                                                                   as away_win_pct,
        count(case when tg.game_location = 'Neutral' then 1 end)              as neutral_games,
        sum(case when tg.game_location = 'Neutral' then tg.is_win else 0 end) as neutral_wins,
        round(
            sum(case when tg.game_location = 'Neutral' then tg.is_win else 0 end)::double
            / nullif(count(case when tg.game_location = 'Neutral' then 1 end), 0), 3
        )                                                                   as neutral_win_pct,
        -- box score averages (null before 2010)
        round(avg(tg.fgm), 1)                                              as avg_fgm,
        round(avg(tg.fga), 1)                                              as avg_fga,
        round(sum(tg.fgm)::double / nullif(sum(tg.fga), 0), 3)             as fg_pct,
        round(avg(tg.fgm3), 1)                                             as avg_fgm3,
        round(avg(tg.fga3), 1)                                             as avg_fga3,
        round(sum(tg.fgm3)::double / nullif(sum(tg.fga3), 0), 3)           as fg3_pct,
        round(avg(tg.fgm - tg.fgm3), 1)                                    as avg_fgm2,
        round(avg(tg.fga - tg.fga3), 1)                                    as avg_fga2,
        round(avg(tg.ftm), 1)                                              as avg_ftm,
        round(avg(tg.fta), 1)                                              as avg_fta,
        round(sum(tg.ftm)::double / nullif(sum(tg.fta), 0), 3)             as ft_pct,
        round(avg(tg.reb), 1)                                              as avg_reb,
        round(avg(tg.off_reb), 1)                                          as avg_off_reb,
        round(avg(tg.def_reb), 1)                                          as avg_def_reb,
        round(avg(tg.ast), 1)                                              as avg_ast,
        round(avg(tg.tov), 1)                                              as avg_tov,
        round(avg(tg.stl), 1)                                              as avg_stl,
        round(avg(tg.blk), 1)                                              as avg_blk,
        round(avg(tg.pf), 1)                                               as avg_pf,
        -- tournament
        count(case when tg.game_type = 'Tournament' then 1 end)            as tourney_games_played
    from team_games tg
    group by tg.season, tg.team_id
),
final as (
    select
        t.team_name,
        t.team_state,
        t.team_state_iso,
        s.season_label,
        a.season,
        a.games_played,
        a.wins,
        a.losses,
        a.win_pct,
        a.total_pts_scored,
        a.total_pts_allowed,
        a.avg_pts_scored,
        a.avg_pts_allowed,
        a.avg_pt_diff,
        a.home_games,
        a.home_wins,
        a.home_win_pct,
        a.away_games,
        a.away_wins,
        a.away_win_pct,
        a.neutral_games,
        a.neutral_wins,
        a.neutral_win_pct,
        a.avg_fgm,
        a.avg_fga,
        a.fg_pct,
        a.avg_fgm3,
        a.avg_fga3,
        a.fg3_pct,
        a.avg_fgm2,
        a.avg_fga2,
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
        a.avg_pf,
        a.tourney_games_played,
        coalesce(seed.made_tourney, false)  as made_tourney,
        seed.tourney_seed_number
    from aggregated a
    left join teams          t    on a.team_id = t.team_id
    left join seasons        s    on a.season  = s.season
    left join tourney_seeds  seed on a.season  = seed.season and a.team_id = seed.team_id
)
select * from final
