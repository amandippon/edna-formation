with source as (
    select * from read_parquet('../processed-resources/WSeasons/*.parquet')
),
renamed as (
    select
        Season                                      as season,
        strptime(DayZero, '%m/%d/%Y')::date         as day_zero,
        RegionW                                     as region_w,
        RegionX                                     as region_x,
        RegionY                                     as region_y,
        RegionZ                                     as region_z
    from source
)
select * from renamed
