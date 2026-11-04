-- Mission 1 (Bronze) : vérifie stg_seasons. 0 ligne renvoyée = test vert.
-- 22 saisons attendues, et la saison 1998 commence le 27 octobre 1997.
select 'nombre de saisons' as probleme, count(*)::varchar as obtenu
from {{ ref('stg_seasons') }}
having count(*) <> 22

union all

select 'day_zero de la saison 1998', coalesce(day_zero::varchar, 'null')
from {{ ref('stg_seasons') }}
where season = 1998 and day_zero is distinct from date '1997-10-27'
