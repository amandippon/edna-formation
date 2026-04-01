with athletes as (
    select * from {{ ref('stg_athletes') }}
),

sports as (
    select * from {{ ref('stg_sports') }}
),

final as (
    select
        a.athlete_id,
        a.first_name || ' ' || a.last_name   as full_name,
        a.first_name,
        a.last_name,
        a.country_code,
        a.country_name,
        a.birth_year,
        2024 - a.birth_year                  as age,
        a.gender,
        s.sport_name,
        s.discipline,
        s.sport_category
    from athletes a
    left join sports s on a.sport_id = s.sport_id
)

select * from final
