with source as (
    select * from read_parquet('../processed-resources/WNCAATourneySeeds/*.parquet')
),
renamed as (
    select
        Season                                              as season,
        TeamID                                              as team_id,
        Seed                                                as seed_raw,
        left(Seed, 1)                                       as seed_region,
        cast(regexp_extract(Seed, '[0-9]+') as integer)     as seed_number
    from source
)
select * from renamed
