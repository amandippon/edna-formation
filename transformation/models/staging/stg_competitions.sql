with source as (
    select * from read_parquet('../processed-resources/competitions/*.parquet')
),

renamed as (
    select
        competition_id,
        competition_name,
        sport_id,
        city,
        country,
        year,
        season,
        edition
    from source
)

select * from renamed
