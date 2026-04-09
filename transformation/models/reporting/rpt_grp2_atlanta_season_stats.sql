with regular as (
    select * from {{ ref('fct_regular_season_games') }}
),
tourney as (
    select * from {{ ref('fct_tourney_games') }}
),
all_games as (
    select
        game_id, game_type, season,
        w_team_id, l_team_id,
        w_score, l_score, score_margin,
        game_location,
        null::integer as w_seed_number,
        null::integer as l_seed_number,
        null::boolean as is_upset,
        null::integer as seed_difference
    from regular

    union all

    select
        game_id, game_type, season,
        w_team_id, l_team_id,
        w_score, l_score, score_margin,
        game_location,
        w_seed_number,
        l_seed_number,
        is_upset,
        seed_difference
    from tourney
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
atlanta_team_ids as (
    select team_id from teams where team_state = 'GA'
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
tourney_seeds as (
    select season, team_id, seed_number as tourney_seed_number, true as made_tourney
    from {{ ref('stg_tourney_seeds') }}
),
-- Unpivot: one row per Atlanta team per game
team_games as (
    select
        g.season,
        g.w_team_id                            as team_id,
        1                                      as is_win,
        g.w_score                              as pts_scored,
        g.l_score                              as pts_allowed,
        g.score_margin,
        g.game_location,
        g.game_type,
        g.is_upset,
        g.seed_difference
    from all_games g
    where g.w_team_id in (select team_id from atlanta_team_ids)

    union all

    select
        g.season,
        g.l_team_id                            as team_id,
        0                                      as is_win,
        g.l_score                              as pts_scored,
        g.w_score                              as pts_allowed,
        -g.score_margin,
        case g.game_location
            when 'Home' then 'Away'
            when 'Away' then 'Home'
            else 'Neutral'
        end                                    as game_location,
        g.game_type,
        g.is_upset,
        g.seed_difference
    from all_games g
    where g.l_team_id in (select team_id from atlanta_team_ids)
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
        -- tournament upsets
        count(case when tg.game_type = 'Tournament' then 1 end)            as tourney_games,
        count(case when tg.is_upset then 1 end)                            as upsets_involved
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
        a.tourney_games,
        a.upsets_involved,
        coalesce(seed.made_tourney, false)  as made_tourney,
        seed.tourney_seed_number,
        -- season ranking (among Atlanta teams)
        rank() over (partition by a.season order by a.win_pct desc, a.avg_pt_diff desc) as season_rank
    from aggregated a
    left join teams          t    on a.team_id = t.team_id
    left join seasons        s    on a.season  = s.season
    left join tourney_seeds  seed on a.season  = seed.season and a.team_id = seed.team_id
)
select * from final
