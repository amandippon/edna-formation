with source as (
    select * from read_parquet('../processed-resources/WTeams/*.parquet')
),
renamed as (
    select
        TeamID   as team_id,
        TeamName as team_name
    from source
)
select * from renamed
