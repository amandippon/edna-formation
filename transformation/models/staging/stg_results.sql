with source as (
    select * from read_parquet('../processed-resources/results/*.parquet')
),

renamed as (
    select
        result_id,
        athlete_id,
        competition_id,
        rank,
        medal,
        performance_value,
        performance_unit
    from source
)

select * from renamed
