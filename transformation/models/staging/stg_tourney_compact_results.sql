with source as (
    select * from read_parquet('../processed-resources/WNCAATourneyCompactResults/*.parquet')
),
renamed as (
    select
        Season    as season,
        DayNum    as day_num,
        WTeamID   as w_team_id,
        WScore    as w_score,
        LTeamID   as l_team_id,
        LScore    as l_score,
        WLoc      as w_loc,
        NumOT     as num_ot
    from source
)
select * from renamed
