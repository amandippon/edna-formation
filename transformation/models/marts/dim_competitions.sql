with competitions as (
    select * from {{ ref('stg_competitions') }}
),

sports as (
    select * from {{ ref('stg_sports') }}
),

final as (
    select
        c.competition_id,
        c.competition_name,
        c.city,
        c.country,
        c.year,
        c.season,
        c.edition,
        s.sport_name,
        s.discipline,
        s.sport_category
    from competitions c
    left join sports s on c.sport_id = s.sport_id
)

select * from final
