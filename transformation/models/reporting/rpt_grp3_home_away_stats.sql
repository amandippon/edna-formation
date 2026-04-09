with regular as (
    select * from {{ ref('fct_regular_season_games') }}
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
-- Unpivot: one row per team per game with correct location perspective
team_games as (
    -- Winner perspective: game_location is already from winner's POV
    select
        g.season,
        g.w_team_id   as team_id,
        1              as is_win,
        g.w_score      as pts_scored,
        g.l_score      as pts_allowed,
        g.game_location
    from regular g

    union all

    -- Loser perspective: flip location
    select
        g.season,
        g.l_team_id   as team_id,
        0              as is_win,
        g.l_score      as pts_scored,
        g.w_score      as pts_allowed,
        case g.game_location
            when 'Home' then 'Away'
            when 'Away' then 'Home'
            else 'Neutral'
        end            as game_location
    from regular g
),
aggregated as (
    select
        tg.season,
        tg.team_id,
        -- overall
        count(*)                                                                as games_played,
        sum(tg.is_win)                                                          as wins,
        count(*) - sum(tg.is_win)                                               as losses,
        round(sum(tg.is_win)::double / count(*), 3)                             as win_pct,
        round(avg(tg.pts_scored), 1)                                            as avg_pts_scored,
        round(avg(tg.pts_allowed), 1)                                           as avg_pts_allowed,
        -- Home
        count(case when tg.game_location = 'Home' then 1 end)                  as home_games,
        sum(case when tg.game_location = 'Home' then tg.is_win else 0 end)     as home_wins,
        round(
            sum(case when tg.game_location = 'Home' then tg.is_win else 0 end)::double
            / nullif(count(case when tg.game_location = 'Home' then 1 end), 0), 3
        )                                                                       as home_win_pct,
        -- Away
        count(case when tg.game_location = 'Away' then 1 end)                  as away_games,
        sum(case when tg.game_location = 'Away' then tg.is_win else 0 end)     as away_wins,
        round(
            sum(case when tg.game_location = 'Away' then tg.is_win else 0 end)::double
            / nullif(count(case when tg.game_location = 'Away' then 1 end), 0), 3
        )                                                                       as away_win_pct,
        -- Neutral
        count(case when tg.game_location = 'Neutral' then 1 end)                  as neutral_games,
        sum(case when tg.game_location = 'Neutral' then tg.is_win else 0 end)     as neutral_wins,
        round(
            sum(case when tg.game_location = 'Neutral' then tg.is_win else 0 end)::double
            / nullif(count(case when tg.game_location = 'Neutral' then 1 end), 0), 3
        )                                                                       as neutral_win_pct
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
        a.home_games,
        a.home_wins,
        a.home_win_pct,
        a.away_games,
        a.away_wins,
        a.away_win_pct,
        a.neutral_games,
        a.neutral_wins,
        a.neutral_win_pct
    from aggregated a
    left join teams   t on a.team_id = t.team_id
    left join seasons s on a.season  = s.season
)
select * from final
