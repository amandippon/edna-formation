-- Test de l'exercice bonus : aucune colonne en HUGEINT (0 ligne = test vert).
-- Dans DuckDB, sum() sur des entiers renvoie un HUGEINT, que Superset ne traite pas comme un nombre :
-- convertir avec ::integer, par exemple sum(...)::integer.
select 'colonne en HUGEINT (ajouter ::integer) : ' || column_name as probleme, data_type
from information_schema.columns
where table_schema = 'reporting'
  and table_name = '{{ ref('rpt_upsets_by_seed').identifier }}'
  and data_type = 'HUGEINT'
