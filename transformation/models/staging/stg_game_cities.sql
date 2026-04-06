with source as (
    select * from read_parquet('../processed-resources/WGameCities/*.parquet')
),
renamed as (
    select
        Season    as season,
        DayNum    as day_num,
        WTeamID   as w_team_id,
        LTeamID   as l_team_id,
        CRType    as cr_type,
        CityID    as city_id
    from source
)
select * from renamed
