with compact as (
    select * from {{ ref('stg_tourney_compact_results') }}
),
detailed as (
    select * from {{ ref('stg_tourney_detailed_results') }}
),
seeds as (
    select * from {{ ref('stg_tourney_seeds') }}
),
game_cities as (
    select * from {{ ref('stg_game_cities') }}
),
seasons as (
    select season, day_zero from {{ ref('stg_seasons') }}
),
enriched as (
    select
        -- identifiant
        'T_' || cast(c.season as varchar) || '_' || cast(c.day_num as varchar) || '_' || cast(c.w_team_id as varchar) || '_' || cast(c.l_team_id as varchar) as game_id,
        'Tournament'                                                                            as game_type,

        -- calendrier
        c.season,
        c.day_num,
        (s.day_zero + interval (c.day_num) days)::date                                         as game_date,

        -- équipes
        c.w_team_id,
        c.l_team_id,

        -- scores
        c.w_score,
        c.l_score,
        c.w_score - c.l_score                                                                   as score_margin,
        c.w_score + c.l_score                                                                   as total_points,

        -- lieu
        c.w_loc,
        case c.w_loc
            when 'H' then 'Home'
            when 'A' then 'Away'
            else          'Neutral'
        end                                                                                     as game_location,

        -- overtime
        c.num_ot,
        c.num_ot > 0                                                                            as has_overtime,
        (c.w_score - c.l_score) <= 5                                                            as is_close_game,

        -- ville (nullable)
        gc.city_id,

        -- seeds
        ws.seed_raw                                                                             as w_seed_raw,
        ws.seed_region                                                                          as w_seed_region,
        ws.seed_number                                                                          as w_seed_number,
        ls.seed_raw                                                                             as l_seed_raw,
        ls.seed_region                                                                          as l_seed_region,
        ls.seed_number                                                                          as l_seed_number,

        -- upset analysis
        ws.seed_number > ls.seed_number                                                         as is_upset,
        ws.seed_number - ls.seed_number                                                         as seed_difference,

        -- box score winner (nullable)
        d.w_fgm,
        d.w_fga,
        round(d.w_fgm::double / nullif(d.w_fga, 0), 3)                                         as w_fg_pct,
        d.w_fgm3,
        d.w_fga3,
        round(d.w_fgm3::double / nullif(d.w_fga3, 0), 3)                                       as w_fg3_pct,
        d.w_ftm,
        d.w_fta,
        round(d.w_ftm::double / nullif(d.w_fta, 0), 3)                                         as w_ft_pct,
        coalesce(d.w_or, 0) + coalesce(d.w_dr, 0)                                              as w_reb,
        d.w_or,
        d.w_dr,
        d.w_ast,
        d.w_to,
        d.w_stl,
        d.w_blk,
        d.w_pf,

        -- box score loser (nullable)
        d.l_fgm,
        d.l_fga,
        round(d.l_fgm::double / nullif(d.l_fga, 0), 3)                                         as l_fg_pct,
        d.l_fgm3,
        d.l_fga3,
        round(d.l_fgm3::double / nullif(d.l_fga3, 0), 3)                                       as l_fg3_pct,
        d.l_ftm,
        d.l_fta,
        round(d.l_ftm::double / nullif(d.l_fta, 0), 3)                                         as l_ft_pct,
        coalesce(d.l_or, 0) + coalesce(d.l_dr, 0)                                              as l_reb,
        d.l_or,
        d.l_dr,
        d.l_ast,
        d.l_to,
        d.l_stl,
        d.l_blk,
        d.l_pf,

        d.season is not null                                                                    as has_box_score

    from compact c
    left join detailed d
        on  c.season    = d.season
        and c.day_num   = d.day_num
        and c.w_team_id = d.w_team_id
        and c.l_team_id = d.l_team_id
    left join seeds ws
        on  c.season    = ws.season
        and c.w_team_id = ws.team_id
    left join seeds ls
        on  c.season    = ls.season
        and c.l_team_id = ls.team_id
    left join game_cities gc
        on  c.season    = gc.season
        and c.day_num   = gc.day_num
        and c.w_team_id = gc.w_team_id
        and c.l_team_id = gc.l_team_id
    left join seasons s on c.season = s.season
)
select * from enriched
