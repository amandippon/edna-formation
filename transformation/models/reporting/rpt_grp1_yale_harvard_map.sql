with teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
coordinates as (
    select *
    from (values
        ('Harvard', 42.3736, -71.1097, 'Cambridge, MA'),
        ('Yale',    41.3083, -72.9279, 'New Haven, CT')
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
