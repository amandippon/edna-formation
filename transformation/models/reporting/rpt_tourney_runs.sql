-- Mission 3 (reporting) : rpt_tourney_runs
--
-- Une table large pour Superset : le parcours de chaque équipe dans chaque tournoi NCAA.
-- Le tournoi compte 64 équipes : 6 victoires = le titre, une défaite = éliminée.
--
-- ENTRÉE PRINCIPALE : fct_tourney_games, un match par ligne au format gagnant / perdant
--   season | w_team_id | l_team_id | w_score | l_score
--   2016   | 3163      | 3393      | 82      | 51        <- finale 2016 : Connecticut bat Syracuse
--
-- DÉJÀ FAIT (CTE all_tourney_team_games) : chaque match devient deux lignes, une par équipe
--   season | team_id | is_win | pts_scored | pts_allowed
--   2016   | 3163    | 1      | 82         | 51
--   2016   | 3393    | 0      | 51         | 82
--
-- SORTIE ATTENDUE : une ligne par équipe et par tournoi (1 344 lignes), par exemple en 2016
--   team_name     | season_label  | seed_number | tourney_wins | tourney_losses | tournament_result
--   'Connecticut' | 'Season 2016' | 1           | 6            | 0              | 'Champion'
--   'Syracuse'    | 'Season 2016' | 4           | 5            | 1              | 'Runner-Up'
--   'Albany NY'   | 'Season 2016' | 12          | 1            | 1              | 'Second Round'
--
-- À FAIRE
--   TODO 1 et 2 : compter victoires et défaites par équipe et par saison (CTE team_tourney_stats).
--   TODO 3 à 5  : joindre trois marts pour ajouter le nom de l'équipe, le libellé de la saison
--                 et le seed (CTE final).
--   TODO 6 (models/reporting/_reporting_models.yml) : décrire seed_number, is_champion et
--          tournament_result, puis les retrouver dans la documentation (task docs).
--
-- Aperçu du résultat : task show M=rpt_tourney_runs
-- Vérifier         : task build (au vert quand la mission est finie)
-- Détail d'un échec : task show M=mission_3_rpt_tourney_runs

with tourney_games as (
    select * from {{ ref('fct_tourney_games') }}
),
-- Une ligne par équipe et par match : le gagnant d'un côté, le perdant de l'autre (déjà fait)
all_tourney_team_games as (
    select season, w_team_id as team_id, 1 as is_win, w_score as pts_scored, l_score as pts_allowed
    from tourney_games

    union all

    select season, l_team_id as team_id, 0 as is_win, l_score as pts_scored, w_score as pts_allowed
    from tourney_games
),
team_tourney_stats as (
    select
        season,
        team_id,
        null::integer                       as tourney_wins,     -- TODO 1 : somme de is_win (1 = victoire, 0 = défaite).
                                                                 --   Convertir en entier : sum(colonne)::integer
                                                                 --   (sans ::integer, DuckDB renvoie un HUGEINT, mal géré par Superset)
        null::integer                       as tourney_losses,   -- TODO 2 : nombre de matchs (count(*)) moins les victoires,
                                                                 --   le tout en entier : (... - ...)::integer
        round(avg(pts_scored), 1)           as avg_pts_scored_tourney,
        round(avg(pts_allowed), 1)          as avg_pts_allowed_tourney
    from all_tourney_team_games
    group by season, team_id
),
final as (
    select
        null::varchar                   as team_name,       -- TODO 3 : joindre dim_teams (alias t) sur team_id,
        null::varchar                   as team_state,      --   puis remplacer ces trois lignes par
                                                            --   t.team_name, t.team_state, t.team_state_iso
        null::varchar                   as team_state_iso,
        tts.season,
        null::varchar                   as season_label,    -- TODO 4 : joindre dim_seasons (alias se) sur season,
                                                            --   puis se.season_label
        null::integer                   as seed_number,     -- TODO 5 : joindre dim_tourney_seeds (alias sd) sur season ET team_id,
                                                            --   puis sd.seed_number
        tts.tourney_wins,
        tts.tourney_losses,
        tts.avg_pts_scored_tourney,
        tts.avg_pts_allowed_tourney,
        tts.tourney_wins = 6            as is_champion,     -- 64 équipes : 6 victoires = titre
        case tts.tourney_wins                               -- déjà fait
            when 6 then 'Champion'
            when 5 then 'Runner-Up'
            when 4 then 'Final Four'
            when 3 then 'Elite Eight'
            when 2 then 'Sweet Sixteen'
            when 1 then 'Second Round'
            else 'First Round Exit'
        end                             as tournament_result
    from team_tourney_stats tts
    -- TODO 3 à 5 : les trois jointures, chacune vers un mart lu avec ref (comme tourney_games plus haut) :
    --   left join <ref vers dim_teams>         t  on tts.team_id = t.team_id
    --   left join <ref vers dim_seasons>       se on ...
    --   left join <ref vers dim_tourney_seeds> sd on ... and ...
    --   left join et non inner join : une ligne par équipe et par saison, la jointure ne doit ni en ajouter ni en retirer.
)
select * from final
