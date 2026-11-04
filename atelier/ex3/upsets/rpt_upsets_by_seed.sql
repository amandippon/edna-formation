-- Atelier ex. 3 : les surprises du tournoi NCAA
-- Objectif : une ligne par affiche (ex : '8 vs 9') avec le nombre de matchs
-- et le nombre gagnés par l'outsider (l'équipe au plus grand numéro de seed).
-- Source : marts.fct_tourney_games (une ligne par match de tournoi)
--   colonnes utiles : w_seed_number, l_seed_number (seed du gagnant / du perdant),
--   is_upset (true si le gagnant avait le moins bon seed)
-- Vérifier : task atelier:check   (tous les tests doivent passer au vert)

with games as (
    select *
    from {{ ref('fct_tourney_games') }}
    -- TODO 1 : exclure les matchs entre deux équipes de même seed
),
matchups as (
    select
        null::integer           as favorite_seed,   -- TODO 2 : le plus petit des deux seeds (fonction least)
        null::integer           as underdog_seed,   -- TODO 3 : le plus grand des deux seeds (fonction greatest)
        is_upset
    from games
),
final as (
    select
        favorite_seed || ' vs ' || underdog_seed   as matchup,
        favorite_seed,
        underdog_seed,
        underdog_seed - favorite_seed              as seed_gap,
        count(*)                                   as games,
        null::bigint                               as upsets,     -- TODO 4 : compter les matchs où is_upset est vrai
        null::double                               as upset_pct   -- TODO 5 : upsets / games, arrondi à 3 décimales
    from matchups
    group by favorite_seed, underdog_seed
)
select * from final
