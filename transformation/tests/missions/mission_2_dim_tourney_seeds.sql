-- Mission 2 (Silver) : vérifie dim_tourney_seeds. 0 ligne renvoyée = test vert.
-- Une ligne par équipe qualifiée et par saison (1 408), seeds de 1 à 16,
-- et en 2019 Connecticut est tête de série n°2 de la région d'Albany.
select 'nombre de lignes' as probleme, count(*)::varchar as obtenu
from {{ ref('dim_tourney_seeds') }}
having count(*) <> 1408

union all

select 'seed hors de 1 à 16', seed_raw
from {{ ref('dim_tourney_seeds') }}
where seed_number not between 1 and 16

union all

select 'Connecticut 2019', coalesce(seed_number::varchar, 'null') || ' / ' || coalesce(region_name, 'null')
from {{ ref('dim_tourney_seeds') }}
where season = 2019 and team_name = 'Connecticut'
  and (seed_number is distinct from 2 or region_name is distinct from 'Albany')
