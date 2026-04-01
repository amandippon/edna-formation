with source as (
    select * from read_parquet('../processed-resources/athletes/*.parquet')
),

renamed as (
    select
        athlete_id,
        first_name,
        last_name,
        country_code,
        country_name,
        birth_year,
        gender,
        sport_id
    from source
)

select * from renamed
