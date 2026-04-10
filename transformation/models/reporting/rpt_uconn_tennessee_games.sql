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
        null::integer as seed_difference,
        w_fgm, w_fga, w_fg_pct, w_fgm3, w_fga3, w_fg3_pct,
        w_ftm, w_fta, w_ft_pct, w_reb, w_or, w_dr, w_ast, w_to, w_stl, w_blk, w_pf,
        l_fgm, l_fga, l_fg_pct, l_fgm3, l_fga3, l_fg3_pct,
        l_ftm, l_fta, l_ft_pct, l_reb, l_or, l_dr, l_ast, l_to, l_stl, l_blk, l_pf
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
        seed_difference,
        w_fgm, w_fga, w_fg_pct, w_fgm3, w_fga3, w_fg3_pct,
        w_ftm, w_fta, w_ft_pct, w_reb, w_or, w_dr, w_ast, w_to, w_stl, w_blk, w_pf,
        l_fgm, l_fga, l_fg_pct, l_fgm3, l_fga3, l_fg3_pct,
        l_ftm, l_fta, l_ft_pct, l_reb, l_or, l_dr, l_ast, l_to, l_stl, l_blk, l_pf
    from tourney
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
rival_ids as (
    select team_id from teams where team_name in ('Connecticut', 'Tennessee')
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
cities as (
    select city_id, city, state from {{ ref('dim_cities') }}
),
rival_games as (
    select g.*
    from all_games g
    where g.w_team_id in (select team_id from rival_ids)
       or g.l_team_id in (select team_id from rival_ids)
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
        -- flag: is UConn/Tennessee the winner or the loser?
        case
            when wt.team_name in ('Connecticut', 'Tennessee') then wt.team_name
            else lt.team_name
        end                             as rival_team,
        case
            when wt.team_name in ('Connecticut', 'Tennessee') then 1
            else 0
        end                             as rival_team_won,
        -- is this a head-to-head game between the two rivals?
        case
            when wt.team_name in ('Connecticut', 'Tennessee')
             and lt.team_name in ('Connecticut', 'Tennessee')
            then true
            else false
        end                             as is_head_to_head,
        -- box score (null before 2010)
        g.has_box_score,
        g.w_fgm, g.w_fga, g.w_fg_pct, g.w_fgm3, g.w_fga3, g.w_fg3_pct,
        g.w_ftm, g.w_fta, g.w_ft_pct, g.w_reb, g.w_or, g.w_dr,
        g.w_ast, g.w_to, g.w_stl, g.w_blk, g.w_pf,
        g.l_fgm, g.l_fga, g.l_fg_pct, g.l_fgm3, g.l_fga3, g.l_fg3_pct,
        g.l_ftm, g.l_fta, g.l_ft_pct, g.l_reb, g.l_or, g.l_dr,
        g.l_ast, g.l_to, g.l_stl, g.l_blk, g.l_pf
    from rival_games g
    left join teams   wt on g.w_team_id = wt.team_id
    left join teams   lt on g.l_team_id = lt.team_id
    left join seasons  s on g.season    = s.season
    left join cities   c on g.city_id   = c.city_id
)
select * from final
