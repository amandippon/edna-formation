with results as (
    select * from {{ ref('stg_results') }}
),

final as (
    select
        result_id,
        athlete_id,
        competition_id,
        rank,
        medal,
        performance_value,
        performance_unit,
        -- Indicateurs calculés
        case when medal != 'None' then true else false end as is_medalist,
        case when medal = 'Gold'   then 3
             when medal = 'Silver' then 2
             when medal = 'Bronze' then 1
             else 0
        end                                                as medal_points
    from results
)

select * from final
