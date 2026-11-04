-- Mission 3 (reporting) : vérifie rpt_tourney_runs. 0 ligne renvoyée = test vert.
-- Une ligne par équipe et par tournoi (1 344), un seul champion par saison,
-- et Connecticut championne en 2016.
-- Vérifie aussi que trois colonnes sont décrites dans _reporting_models.yml.
-- Détail des problèmes : task show M=mission_3_rpt_tourney_runs
{%- set colonnes = {} %}
{%- if execute %}
  {%- set colonnes = graph.nodes['model.transformation.rpt_tourney_runs'].columns %}
{%- endif %}
select 'nombre de lignes' as probleme, count(*)::varchar as obtenu
from {{ ref('rpt_tourney_runs') }}
having count(*) <> 1344

union all

select 'champions de la saison ' || season, count(*)::varchar
from {{ ref('rpt_tourney_runs') }}
group by season
having count(*) filter (where is_champion) <> 1

union all

select 'champion 2016', coalesce(max(team_name) filter (where is_champion), 'aucun')
from {{ ref('rpt_tourney_runs') }}
where season = 2016
having coalesce(max(team_name) filter (where is_champion), 'aucun') <> 'Connecticut'
{%- for colonne in ['seed_number', 'is_champion', 'tournament_result']
      if colonne not in colonnes or not colonnes[colonne].description %}

union all

select 'description absente du YAML : {{ colonne }}', null
{%- endfor %}
