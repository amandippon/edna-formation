{#-
    Par défaut, dbt préfixe les schémas personnalisés avec le schéma cible
    (ex. `main_staging`). On utilise ici le nom du schéma tel quel
    (`staging`, `marts`, `reporting`) pour une base plus lisible dans
    DBeaver et Superset.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
