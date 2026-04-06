with regular as (
    select
        game_id, game_type, season, game_date,
        w_team_id, l_team_id,
        w_score, l_score, score_margin,
        game_location, has_overtime, is_close_game,
        city_id,
        null::integer as w_seed_number,
        null::integer as l_seed_number,
        null::boolean as is_upset,
        null::integer as seed_difference
    from {{ ref('fct_regular_season_games') }}
),
tourney as (
    select
        game_id, game_type, season, game_date,
        w_team_id, l_team_id,
        w_score, l_score, score_margin,
        game_location, has_overtime, is_close_game,
        city_id,
        w_seed_number,
        l_seed_number,
        is_upset,
        seed_difference
    from {{ ref('fct_tourney_games') }}
),
all_games as (
    select * from regular
    union all
    select * from tourney
),
teams as (
    select team_id, team_name from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
cities as (
    select city_id, city, state, 'US-' || state as state_iso from {{ ref('dim_cities') }}
),
final as (
    select
        g.game_id,
        g.game_type,
        g.season,
        s.season_label,
        g.game_date,
        wt.team_name                    as w_team_name,
        lt.team_name                    as l_team_name,
        g.w_score,
        g.l_score,
        g.score_margin,
        g.game_location,
        g.has_overtime,
        g.is_close_game,
        c.city,
        c.state,
        c.state_iso,
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
        end                             as upset_label
    from all_games g
    left join teams   wt on g.w_team_id = wt.team_id
    left join teams   lt on g.l_team_id = lt.team_id
    left join seasons  s on g.season    = s.season
    left join cities   c on g.city_id   = c.city_id
)
select * from final
