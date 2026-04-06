with cities as (
    select * from {{ ref('stg_cities') }}
),
final as (
    select
        city_id,
        city,
        state,
        city || ', ' || state as city_state
    from cities
)
select * from final
