-- Distance parcourue par équipe et par saison (aller-retour par match)
-- Approximation basée sur les centroïdes des états US (formule de Haversine)
-- Données géographiques disponibles uniquement depuis 2010

with state_coords as (
    select * from (values
        -- US states (approximate centroids)
        ('AK', 64.20, -152.49), ('AL', 32.32, -86.90), ('AR', 34.97, -92.37),
        ('AZ', 34.05, -111.09), ('CA', 36.78, -119.42), ('CO', 39.55, -105.78),
        ('CT', 41.60, -72.76), ('DC', 38.91, -77.04), ('DE', 38.91, -75.53),
        ('FL', 27.66, -81.52), ('GA', 32.17, -82.91), ('HI', 19.90, -155.58),
        ('IA', 41.88, -93.10), ('ID', 44.07, -114.74), ('IL', 40.63, -89.40),
        ('IN', 40.27, -86.13), ('KS', 38.53, -98.77), ('KY', 37.84, -84.27),
        ('LA', 30.98, -91.96), ('MA', 42.41, -71.38), ('MD', 39.05, -76.64),
        ('ME', 45.25, -69.45), ('MI', 44.35, -85.41), ('MN', 46.73, -94.69),
        ('MO', 37.96, -91.83), ('MS', 32.35, -89.40), ('MT', 46.88, -110.36),
        ('NC', 35.76, -79.02), ('ND', 47.55, -101.00), ('NE', 41.49, -99.90),
        ('NH', 43.19, -71.57), ('NJ', 40.06, -74.41), ('NM', 34.52, -105.87),
        ('NV', 38.80, -116.42), ('NY', 43.30, -74.22), ('OH', 40.42, -82.91),
        ('OK', 35.47, -97.52), ('OR', 43.80, -120.55), ('PA', 41.20, -77.19),
        ('RI', 41.58, -71.48), ('SC', 33.84, -81.16), ('SD', 43.97, -99.90),
        ('TN', 35.52, -86.58), ('TX', 31.97, -99.90), ('UT', 39.32, -111.09),
        ('VA', 37.77, -78.17), ('VT', 44.56, -72.58), ('WA', 47.75, -120.74),
        ('WI', 43.78, -88.79), ('WV', 38.60, -80.45), ('WY', 43.08, -107.29),
        -- International / territories
        ('PR', 18.22, -66.59), ('VI', 18.34, -64.93),
        ('MX', 21.16, -86.85), ('BA', 25.03, -77.39),
        ('BC', 49.28, -123.12), ('ON', 43.65, -79.38),
        ('CH', 31.23, 121.47), ('SK', 35.91, 127.77),
        ('CI', 19.43, -99.13), ('GY', 6.80, -58.16),
        ('IR', 35.69, 51.39), ('JA', 18.11, -77.30)
    ) as t(state_code, lat, lon)
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
cities as (
    select city_id, city, state from {{ ref('dim_cities') }}
),
regular as (
    select game_id, season, w_team_id, l_team_id, city_id, game_location
    from {{ ref('fct_regular_season_games') }}
    where city_id is not null
),
tourney as (
    select game_id, season, w_team_id, l_team_id, city_id, game_location
    from {{ ref('fct_tourney_games') }}
    where city_id is not null
),
all_games as (
    select * from regular
    union all
    select * from tourney
),
-- Unpivot: one row per team per game, with correct location perspective
team_game_locations as (
    select
        g.season,
        g.w_team_id                as team_id,
        g.game_location,
        c.state                    as game_state
    from all_games g
    left join cities c on g.city_id = c.city_id

    union all

    select
        g.season,
        g.l_team_id                as team_id,
        case g.game_location
            when 'Home' then 'Away'
            when 'Away' then 'Home'
            else 'Neutral'
        end                        as game_location,
        c.state                    as game_state
    from all_games g
    left join cities c on g.city_id = c.city_id
),
-- Calculate round-trip distance per game using Haversine
distances as (
    select
        tgl.season,
        tgl.team_id,
        tgl.game_location,
        -- Haversine formula (result in km)
        case
            when t.team_state = tgl.game_state then 0
            else round(
                2 * 6371 * asin(sqrt(
                    power(sin(radians(gc.lat - hc.lat) / 2), 2)
                    + cos(radians(hc.lat)) * cos(radians(gc.lat))
                      * power(sin(radians(gc.lon - hc.lon) / 2), 2)
                )), 0)
        end                        as one_way_km
    from team_game_locations tgl
    left join teams          t  on tgl.team_id   = t.team_id
    left join state_coords   hc on t.team_state  = hc.state_code
    left join state_coords   gc on tgl.game_state = gc.state_code
),
aggregated as (
    select
        season,
        team_id,
        count(*)                                                as games_with_location,
        sum(one_way_km * 2)                                     as total_travel_km,
        round(avg(one_way_km * 2), 0)                           as avg_round_trip_km,
        max(one_way_km)                                         as max_one_way_km,
        sum(case when game_location != 'Home' then one_way_km * 2 else 0 end) as away_travel_km,
        count(case when one_way_km > 0 then 1 end)             as games_traveled,
        -- Empreinte carbone approximative (bus: ~0.03 kg CO2/km/passager, 15 joueuses + staff ~25 personnes)
        round(sum(one_way_km * 2) * 0.03 * 25, 0)              as estimated_co2_kg
    from distances
    group by season, team_id
),
final as (
    select
        t.team_name,
        t.team_state,
        t.team_state_iso,
        s.season_label,
        a.season,
        a.games_with_location,
        a.games_traveled,
        a.total_travel_km,
        a.avg_round_trip_km,
        a.max_one_way_km,
        a.away_travel_km,
        a.estimated_co2_kg
    from aggregated a
    left join teams   t on a.team_id = t.team_id
    left join seasons s on a.season  = s.season
)
select * from final
