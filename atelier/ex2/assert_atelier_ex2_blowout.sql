-- Test de l'atelier, ex. 2 : renvoie une ligne par match mal calculé (0 ligne = test vert)
-- is_blowout : vrai si l'écart de score est d'au moins 20 points
-- game_month : premier jour du mois du match (ex : 2019-03-01 pour un match le 17/03/2019)
select game_id, score_margin, is_blowout, game_date, game_month
from {{ ref('fct_regular_season_games') }}
where is_blowout is null
   or is_blowout <> (score_margin >= 20)
   or game_month is null
   or game_month <> date_trunc('month', game_date)::date
