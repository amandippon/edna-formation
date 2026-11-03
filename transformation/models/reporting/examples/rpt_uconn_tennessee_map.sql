with teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
coordinates as (
    select *
    from (values
        ('Connecticut', 41.8077, -72.2540, 'Storrs, CT'),
        ('Tennessee',   35.9544, -83.9295, 'Knoxville, TN')
    ) as t(team_name, latitude, longitude, campus_city)
),
final as (
    select
        t.team_name,
        t.team_state,
        t.team_state_iso,
        c.campus_city,
        c.latitude,
        c.longitude
    from teams t
    inner join coordinates c on t.team_name = c.team_name
)
select * from final
