with seasons as (
    select * from {{ ref('stg_seasons') }}
),
final as (
    select
        season,
        day_zero,
        'Season ' || season                         as season_label,
        season                                      as season_year,
        season - 1998                               as seasons_since_start,
        region_w,
        region_x,
        region_y,
        region_z
    from seasons
)
select * from final
