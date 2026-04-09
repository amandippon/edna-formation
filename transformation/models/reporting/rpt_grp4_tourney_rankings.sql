with tourney as (
    select * from {{ ref('fct_tourney_games') }}
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
seeds as (
    select season, team_id, seed_number, seed_region
    from {{ ref('stg_tourney_seeds') }}
),
team_games as (
    select
        season, w_team_id as team_id, 1 as is_win,
        w_score as pts_scored, l_score as pts_allowed,
        is_upset, seed_difference
    from tourney

    union all

    select
        season, l_team_id as team_id, 0 as is_win,
        l_score as pts_scored, w_score as pts_allowed,
        is_upset, seed_difference
    from tourney
),
aggregated as (
    select
        season,
        team_id,
        count(*)                                            as tourney_games,
        sum(is_win)                                         as tourney_wins,
        count(*) - sum(is_win)                              as tourney_losses,
        round(avg(pts_scored), 1)                           as avg_pts_scored,
        round(avg(pts_allowed), 1)                          as avg_pts_allowed,
        round(avg(pts_scored - pts_allowed), 1)             as avg_pt_diff,
        count(case when is_upset then 1 end)                as upsets_involved
    from team_games
    group by season, team_id
),
final as (
    select
        t.team_name,
        t.team_state,
        t.team_state_iso,
        s.season_label,
        a.season,
        sd.seed_number,
        sd.seed_region,
        a.tourney_games,
        a.tourney_wins,
        a.tourney_losses,
        a.avg_pts_scored,
        a.avg_pts_allowed,
        a.avg_pt_diff,
        a.upsets_involved,
        case a.tourney_wins
            when 6 then 'Champion'
            when 5 then 'Runner-Up'
            when 4 then 'Final Four'
            when 3 then 'Elite Eight'
            when 2 then 'Sweet Sixteen'
            when 1 then 'Second Round'
            when 0 then 'First Round Exit'
        end                                                 as tournament_result,
        a.tourney_wins = 6                                  as is_champion,
        -- classement final tournoi : par nombre de victoires puis seed
        rank() over (
            partition by a.season
            order by a.tourney_wins desc, sd.seed_number asc, a.avg_pt_diff desc
        )                                                   as tourney_rank
    from aggregated a
    left join teams   t  on a.team_id = t.team_id
    left join seasons s  on a.season  = s.season
    left join seeds   sd on a.season  = sd.season and a.team_id = sd.team_id
)
select * from final
