with source as (
    select * from read_parquet('../processed-resources/WNCAATourneySlots/*.parquet')
),
renamed as (
    select
        Slot       as slot,
        StrongSeed as strong_seed,
        WeakSeed   as weak_seed
    from source
)
select * from renamed
