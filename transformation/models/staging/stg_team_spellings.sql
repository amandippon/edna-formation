with source as (
    select * from read_parquet('../processed-resources/WTeamSpellings/*.parquet')
),
renamed as (
    select
        TeamNameSpelling as team_name_spelling,
        TeamID           as team_id
    from source
)
select * from renamed
