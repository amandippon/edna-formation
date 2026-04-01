with results as (
    select * from {{ ref('fct_results') }}
),

athletes as (
    select * from {{ ref('dim_athletes') }}
),

competitions as (
    select * from {{ ref('dim_competitions') }}
),

final as (
    select
        r.result_id,
        -- Athlète
        a.athlete_id,
        a.full_name                 as athlete_name,
        a.first_name,
        a.last_name,
        a.country_code,
        a.country_name,
        a.gender,
        a.age,
        a.sport_name,
        a.discipline,
        a.sport_category,
        -- Compétition
        c.competition_id,
        c.competition_name,
        c.edition,
        c.year,
        c.season,
        c.city,
        c.country                   as host_country,
        -- Résultat
        r.rank,
        r.medal,
        r.performance_value,
        r.performance_unit,
        r.is_medalist,
        r.medal_points
    from results r
    left join athletes    a on r.athlete_id    = a.athlete_id
    left join competitions c on r.competition_id = c.competition_id
)

select * from final
