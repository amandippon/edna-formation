with tourney_games as (
    select * from {{ ref('fct_tourney_games') }}
),
all_tourney_team_games as (
    select season, w_team_id as team_id, 1 as is_win, w_score as pts_scored, l_score as pts_allowed
    from tourney_games

    union all

    select season, l_team_id as team_id, 0 as is_win, l_score as pts_scored, w_score as pts_allowed
    from tourney_games
),
team_tourney_stats as (
    select
        season,
        team_id,
        sum(is_win)                         as tourney_wins,
        count(*) - sum(is_win)              as tourney_losses,
        round(avg(pts_scored), 1)           as avg_pts_scored_tourney,
        round(avg(pts_allowed), 1)          as avg_pts_allowed_tourney
    from all_tourney_team_games
    group by season, team_id
),
seeds as (
    select * from {{ ref('stg_tourney_seeds') }}
),
final as (
    select
        t.team_name,
        t.team_state,
        t.team_state_iso,
        tts.season,
        s.season_label,
        seed.seed_number,
        tts.tourney_wins,
        tts.tourney_losses,
        tts.avg_pts_scored_tourney,
        tts.avg_pts_allowed_tourney,
        tts.tourney_wins = 6            as is_champion,
        case tts.tourney_wins
            when 6 then 'Champion'
            when 5 then 'Runner-Up'
            when 4 then 'Final Four'
            when 3 then 'Elite Eight'
            when 2 then 'Sweet Sixteen'
            when 1 then 'Second Round'
            else        'First Round Exit'
        end                             as tournament_result
    from team_tourney_stats tts
    left join {{ ref('dim_teams') }}   t    on tts.team_id = t.team_id
    left join {{ ref('dim_seasons') }} s    on tts.season  = s.season
    left join seeds                    seed on tts.season  = seed.season and tts.team_id = seed.team_id
)
select * from final
