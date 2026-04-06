with source as (
    select * from read_parquet('../processed-resources/WCities/*.parquet')
),
renamed as (
    select
        CityID as city_id,
        City   as city,
        State  as state
    from source
)
select * from renamed
