with seeds as (
    select * from {{ ref('stg_tourney_seeds') }}
),
teams as (
    select team_id, team_name from {{ ref('stg_teams') }}
),
seasons as (
    select * from {{ ref('stg_seasons') }}
),
final as (
    select
        s.season,
        s.team_id,
        t.team_name,
        s.seed_raw,
        s.seed_region,
        s.seed_number,
        case s.seed_region
            when 'W' then se.region_w
            when 'X' then se.region_x
            when 'Y' then se.region_y
            when 'Z' then se.region_z
        end as region_name
    from seeds s
    left join teams   t  on s.team_id = t.team_id
    left join seasons se on s.season  = se.season
)
select * from final
