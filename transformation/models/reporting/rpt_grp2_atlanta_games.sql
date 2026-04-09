with regular as (
    select * from {{ ref('fct_regular_season_games') }}
),
tourney as (
    select * from {{ ref('fct_tourney_games') }}
),
all_games as (
    select
        game_id, game_type, season, day_num, game_date,
        w_team_id, l_team_id,
        w_score, l_score, score_margin,
        game_location, has_overtime, is_close_game,
        city_id, has_box_score,
        null::integer as w_seed_number,
        null::integer as l_seed_number,
        null::boolean as is_upset,
        null::integer as seed_difference
    from regular

    union all

    select
        game_id, game_type, season, day_num, game_date,
        w_team_id, l_team_id,
        w_score, l_score, score_margin,
        game_location, has_overtime, is_close_game,
        city_id, has_box_score,
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
cities as (
    select city_id, city, state from {{ ref('dim_cities') }}
),
atlanta_games as (
    select g.*
    from all_games g
    where g.w_team_id in (select team_id from atlanta_team_ids)
       or g.l_team_id in (select team_id from atlanta_team_ids)
),
final as (
    select
        g.game_id,
        g.game_type,
        g.season,
        s.season_label,
        g.game_date,
        wt.team_name                    as w_team_name,
        wt.team_state                   as w_team_state,
        lt.team_name                    as l_team_name,
        lt.team_state                   as l_team_state,
        g.w_score,
        g.l_score,
        g.score_margin,
        g.game_location,
        g.has_overtime,
        g.is_close_game,
        c.city,
        c.state                         as game_state,
        g.w_seed_number,
        g.l_seed_number,
        g.is_upset,
        case
            when g.seed_difference >= 10  then 'Cinderella (10+ seeds)'
            when g.seed_difference >= 5   then 'Major Upset (5-9 seeds)'
            when g.seed_difference >= 1   then 'Upset (1-4 seeds)'
            when g.seed_difference = 0    then 'Same Seed'
            when g.seed_difference is null then null
            else                               'Expected Result'
        end                             as upset_label,
        -- flag: is the Atlanta team the winner or the loser?
        case
            when wt.team_state = 'GA' then wt.team_name
            else lt.team_name
        end                             as atlanta_team,
        case
            when wt.team_state = 'GA' then 1
            else 0
        end                             as atlanta_team_won
    from atlanta_games g
    left join teams   wt on g.w_team_id = wt.team_id
    left join teams   lt on g.l_team_id = lt.team_id
    left join seasons  s on g.season    = s.season
    left join cities   c on g.city_id   = c.city_id
)
select * from final
