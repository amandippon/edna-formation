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
        game_location, has_overtime, is_close_game, num_ot,
        city_id, has_box_score,
        null::integer as w_seed_number,
        null::integer as l_seed_number,
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
        game_location, has_overtime, is_close_game, num_ot,
        city_id, has_box_score,
        w_seed_number,
        l_seed_number,
        w_fgm, w_fga, w_fg_pct, w_fgm3, w_fga3, w_fg3_pct,
        w_ftm, w_fta, w_ft_pct, w_reb, w_or, w_dr, w_ast, w_to, w_stl, w_blk, w_pf,
        l_fgm, l_fga, l_fg_pct, l_fgm3, l_fga3, l_fg3_pct,
        l_ftm, l_fta, l_ft_pct, l_reb, l_or, l_dr, l_ast, l_to, l_stl, l_blk, l_pf
    from tourney
),
teams as (
    select team_id, team_name from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
cities as (
    select city_id, city, state from {{ ref('dim_cities') }}
),
-- Connecticut = 3163, Tennessee = 3397
head_to_head as (
    select g.*
    from all_games g
    where (g.w_team_id = 3163 and g.l_team_id = 3397)
       or (g.w_team_id = 3397 and g.l_team_id = 3163)
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
        g.w_score + g.l_score           as total_points,
        g.game_location,
        g.has_overtime,
        g.num_ot,
        g.is_close_game,
        c.city,
        c.state                         as game_state,
        g.w_seed_number,
        g.l_seed_number,
        -- running totals for rivalry tracking
        sum(case when g.w_team_id = 3163 then 1 else 0 end)
            over (order by g.season, g.day_num rows unbounded preceding) as uconn_cumulative_wins,
        sum(case when g.w_team_id = 3397 then 1 else 0 end)
            over (order by g.season, g.day_num rows unbounded preceding) as tennessee_cumulative_wins,
        -- box score
        g.has_box_score,
        g.w_fgm, g.w_fga, g.w_fg_pct, g.w_fgm3, g.w_fga3, g.w_fg3_pct,
        g.w_ftm, g.w_fta, g.w_ft_pct, g.w_reb, g.w_or, g.w_dr,
        g.w_ast, g.w_to, g.w_stl, g.w_blk, g.w_pf,
        g.l_fgm, g.l_fga, g.l_fg_pct, g.l_fgm3, g.l_fga3, g.l_fg3_pct,
        g.l_ftm, g.l_fta, g.l_ft_pct, g.l_reb, g.l_or, g.l_dr,
        g.l_ast, g.l_to, g.l_stl, g.l_blk, g.l_pf
    from head_to_head g
    left join teams   wt on g.w_team_id = wt.team_id
    left join teams   lt on g.l_team_id = lt.team_id
    left join seasons  s on g.season    = s.season
    left join cities   c on g.city_id   = c.city_id
)
select * from final
order by season, game_date
