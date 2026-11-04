-- Mission 1 (staging) : vérifie stg_tourney_seeds. 0 ligne renvoyée = test vert.
-- 1 408 seeds attendus ; chaque seed brut (ex : 'W01') doit se recomposer
-- à partir de la région ('W') et du numéro (1).
select 'nombre de lignes' as probleme, count(*)::varchar as obtenu
from {{ ref('stg_tourney_seeds') }}
having count(*) <> 1408

union all

select 'seed mal découpé : ' || seed_raw,
       coalesce(seed_region, 'null') || ' / ' || coalesce(seed_number::varchar, 'null')
from {{ ref('stg_tourney_seeds') }}
where seed_region is null
   or seed_number is null
   or seed_number not between 1 and 16
   or seed_raw <> seed_region || lpad(seed_number::varchar, 2, '0')
