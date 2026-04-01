with source as (
    select * from read_parquet('../processed-resources/sports/*.parquet')
),

renamed as (
    select
        sport_id,
        sport_name,
        discipline,
        sport_category
    from source
)

select * from renamed
