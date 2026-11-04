-- Mission 1 (staging) : vérifie stg_tourney_seeds. 0 ligne renvoyée = test vert.
-- 1 408 seeds attendus ; chaque seed brut (ex : 'W01') doit se recomposer
-- à partir de la région ('W') et du numéro (1).
-- Vérifie aussi que les tests demandés sont déclarés dans _staging_models.yml.
-- Détail des problèmes : task show M=mission_1_stg_tourney_seeds
{%- set attendus = [('seed_region', 'not_null'), ('seed_region', 'accepted_values'), ('seed_number', 'not_null')] %}
{%- set declares = [] %}
{%- if execute %}
  {%- for node in graph.nodes.values()
        if node.resource_type == 'test'
        and node.attached_node == 'model.transformation.stg_tourney_seeds'
        and node.test_metadata is not none %}
    {%- do declares.append((node.column_name, node.test_metadata.name)) %}
  {%- endfor %}
{%- endif %}
select 'nombre de lignes' as probleme, count(*)::varchar as obtenu
from {{ ref('stg_tourney_seeds') }}
having count(*) <> 1408

union all

select 'seed_number doit être un entier : ajoute cast(... as integer)', any_value(typeof(seed_number))
from {{ ref('stg_tourney_seeds') }}
having any_value(typeof(seed_number)) not in ('INTEGER', 'BIGINT', 'SMALLINT', 'TINYINT')

union all

select 'seeds mal découpés : ' || count(*) || ' sur ' || (select count(*) from {{ ref('stg_tourney_seeds') }}),
       'ex. ' || min(seed_raw) || ' -> ' || coalesce(arg_min(seed_region, seed_raw), 'null')
              || ' / ' || coalesce(arg_min(seed_number, seed_raw)::varchar, 'null')
from {{ ref('stg_tourney_seeds') }}
where seed_region is null
   or seed_number is null
   or try_cast(seed_number as integer) not between 1 and 16
   or seed_raw <> seed_region || lpad(try_cast(seed_number as integer)::varchar, 2, '0')
having count(*) > 0
{%- for colonne, test in attendus if (colonne, test) not in declares %}

union all

select 'test absent du YAML : {{ test }} sur {{ colonne }}', null
{%- endfor %}
