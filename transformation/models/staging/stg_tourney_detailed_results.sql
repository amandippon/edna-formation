with source as (
    select * from read_parquet('../processed-resources/WNCAATourneyDetailedResults/*.parquet')
),
renamed as (
    select
        Season  as season,
        DayNum  as day_num,
        WTeamID as w_team_id,
        WScore  as w_score,
        LTeamID as l_team_id,
        LScore  as l_score,
        WLoc    as w_loc,
        NumOT   as num_ot,
        WFGM    as w_fgm,
        WFGA    as w_fga,
        WFGM3   as w_fgm3,
        WFGA3   as w_fga3,
        WFTM    as w_ftm,
        WFTA    as w_fta,
        WOR     as w_or,
        WDR     as w_dr,
        WAst    as w_ast,
        WTO     as w_to,
        WStl    as w_stl,
        WBlk    as w_blk,
        WPF     as w_pf,
        LFGM    as l_fgm,
        LFGA    as l_fga,
        LFGM3   as l_fgm3,
        LFGA3   as l_fga3,
        LFTM    as l_ftm,
        LFTA    as l_fta,
        LOR     as l_or,
        LDR     as l_dr,
        LAst    as l_ast,
        LTO     as l_to,
        LStl    as l_stl,
        LBlk    as l_blk,
        LPF     as l_pf
    from source
)
select * from renamed
