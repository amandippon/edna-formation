# Les données de l'atelier

Le dictionnaire des tables `reporting`, les pièges à connaître et des idées de dashboards pour le [dashboard](README.md#le-dashboard-40-min) ou pour aller plus loin.

## Les tables `reporting`

| Table | Grain (une ligne =) | Lignes | Usage typique |
|---|---|---|---|
| `rpt_season_overview` | une saison | 22 | Vue d'ensemble : KPI et tendances par saison, palmarès du tournoi |
| `rpt_team_games` | une équipe dans un match | 216 912 | Table la plus souple : tout l'historique d'une équipe, domicile/extérieur, box score de son point de vue |
| `rpt_games` | un match (format gagnant/perdant) | 108 456 | Distribution des scores et des écarts, upsets au tournoi, carte des villes hôtes |
| `rpt_team_season_stats` | une équipe sur une saison régulière | 7 364 | Classements, bilans victoires/défaites, qualification au tournoi, carte par état |
| `rpt_tourney_runs` | une équipe sur un tournoi NCAA | 1 344 | Parcours au tournoi, titres, résultats par seed |
| `rpt_uconn_tennessee_*` | variable (5 tables d'exemple) | 2 à 1 574 | Rivalité Connecticut vs Tennessee, modèle à copier pour votre propre question |
| Vos exercices bonus | une saison ou une affiche | 10 à 45 | `rpt_home_advantage_by_season`, `rpt_three_point_trend`, `rpt_upsets_by_seed` |

### Colonnes clés

**`rpt_season_overview`** : `season`, `season_date` (1er janvier de l'année de la saison, pour l'axe temporel), `teams_count`, `regular_games`, `tourney_games`, `total_games`, `avg_total_points`, `avg_score_margin`, `close_game_pct`, `overtime_pct`, `home_win_pct`, `three_pt_attempt_share`, `tourney_upsets`, `tourney_upset_pct`, `champion_name`, `champion_seed`, `runner_up_name`, `final_score`.

**`rpt_team_games`** : `team_name`, `opponent_name`, `season`, `game_date`, `game_type` (`Regular` ou `Tournament`), `is_win`, `result` (`W`/`L`), `pts_for`, `pts_against`, `pt_diff` (signé), `team_location` (`Home`, `Away`, `Neutral`, du point de vue de l'équipe), `has_overtime`, `num_ot`, `is_close_game`, `city`, `state`, `state_iso`, `team_state`, `team_state_iso`, `team_seed`, `opponent_seed`, `is_upset_win`, `is_upset_loss`, box score (`fgm`, `fga`, `fg_pct`, `fgm3`, `fga3`, `fg3_pct`, `ftm`, `fta`, `ft_pct`, `oreb`, `dreb`, `reb`, `ast`, `tov`, `stl`, `blk`, `pf`) et quelques stats adverses (`opp_fg_pct`, `opp_fg3_pct`, `opp_reb`, `opp_tov`).

**`rpt_games`** : `w_team_name`, `l_team_name`, `w_score`, `l_score`, `score_margin` (toujours positif), `total_points`, `game_location` (lieu du point de vue du gagnant), `num_ot`, `is_close_game`, `has_overtime`, `city`, `state`, `state_iso`, `w_seed_number`, `l_seed_number`, `is_upset`, `upset_label`.

**`rpt_team_season_stats`** : `team_name`, `team_state`, `team_state_iso`, `season`, `games_played`, `wins`, `losses`, `win_pct`, `avg_pts_scored`, `avg_pts_allowed`, `avg_pt_diff`, `made_tourney`, `tourney_seed_number`.

**`rpt_tourney_runs`** : `team_name`, `team_state`, `season`, `seed_number`, `tourney_wins`, `tourney_losses`, `is_champion`, `tournament_result` (`Champion`, `Runner-Up`, `Final Four`, `Elite Eight`, `Sweet Sixteen`, `Second Round`, `First Round Exit`).

Les descriptions complètes sont dans `transformation/models/reporting/_reporting_models.yml` et dans le lineage Colibri (`task docs`).

### Pièges à connaître

- **Couverture temporelle** : saison régulière de 1998 à 2019, tournoi de 1998 à **2018** (la compétition Kaggle portait sur 2019). Box score détaillé et villes des matchs seulement **à partir de 2010** : filtrez `has_box_score` ou `season >= 2010` pour ces colonnes.
- **Prolongations** : aucune n'est renseignée avant **2005** (`num_ot` vaut 0, `has_overtime` false). `overtime_pct` est nul sur 1998-2004 ; ailleurs, filtrez `season >= 2005`.
- **Seeds** : `team_seed`, `opponent_seed`, `is_upset*` et `upset_label` sont nuls en saison régulière.
- **Saison** : `season = 2019` désigne la saison 2018-2019.
- **État d'une équipe** : `team_state` est déduit de l'état où l'équipe joue le plus à domicile (sur 2010-2019). Il est nul pour 4 équipes des tables reporting (14 dans `dim_teams`), faute de match localisé.
- **`rpt_team_games` compte chaque match deux fois** : pour compter des matchs, filtrez `is_win = true` ou comptez les `game_id` distincts.
- **`rpt_team_season_stats` ne couvre que la saison régulière** : les matchs de tournoi n'y sont pas.
- **Pourcentages entre 0 et 1** (`fg_pct`, `win_pct`, `close_game_pct`…) : réglez le format d'affichage en `%` dans Superset.
- **Moyenne de moyennes** : sur `rpt_season_overview`, une métrique `AVG(close_game_pct)` sur plusieurs saisons donne le même poids à chaque saison. Pour un KPI sur la dernière saison, filtrez `season = 2019` ; pour un total, utilisez `SUM(total_games)`.
- **Entiers issus d'un `sum()`** : dans DuckDB, `sum()` sur un entier renvoie un `HUGEINT`, que Superset ne traite pas comme un nombre. Convertissez dans le modèle : `sum(is_win)::integer`.
- **Booléens** : pour un taux, créez une métrique SQL `AVG(CASE WHEN is_win THEN 1 ELSE 0 END)` ; pour un compte, `SUM(CASE WHEN is_close_game THEN 1 ELSE 0 END)`.
- **Cartes** : le chart **Country Map** (pays `usa`) attend des codes ISO comme `US-TX` : utilisez `team_state_iso` ou `state_iso`.
- **Temps** : `game_date` est la colonne temporelle des tables de matchs ; `season_date` celle de `rpt_season_overview` (découpage **Year**). Sans colonne temporelle, utilisez `season` en dimension.

## Commencer par une vue d'ensemble

Avant de creuser une question, un dashboard d'ouverture situe le terrain de jeu : combien de matchs, combien d'équipes, à quoi ressemble un match type, qui gagne. Il sert de page d'accueil et fait apparaître les trous et les anomalies des données, ce qui évite de mal interpréter les dashboards suivants.

- **Table** : `rpt_season_overview` (une ligne par saison, tout est déjà agrégé).
- **Rangée de KPI** (charts **Big Number with Trendline**, colonne temporelle `season_date`, découpage Year) :
  - matchs joués (`SUM(total_games)`) : de 3 997 en 1998 à 5 240 en 2019 (+31 %) ;
  - équipes engagées (`SUM(teams_count)`) : de 303 à 351 ;
  - points par match (`AVG(avg_total_points)`) : autour de 130 ;
  - part des matchs serrés (`AVG(close_game_pct)`) : stable autour de 21 % ;
  - victoires à domicile (`AVG(home_win_pct)`) : 60 à 63 % chaque saison.
- **Évolution** : **Bar Chart** empilé `regular_games` + `tourney_games` par `season` ; **Line Chart** de `avg_total_points` et `avg_score_margin`.
- **Palmarès** : **Table** `season`, `champion_name`, `champion_seed`, `runner_up_name`, `final_score`, triée par saison décroissante.
- **Lecture** : la moyenne de points fait un saut en 2014 (134,8 contre 123,6 en 2013), puis redescend à 128,6. La médiane fait le même saut, donc ce ne sont pas quelques matchs aberrants. Un changement de règles est possible, mais rien dans les données ne permet de le confirmer : c'est le genre de question que la vue d'ensemble doit soulever.
- **Données manquantes visibles** : pas de prolongations avant 2005, pas de part des tirs à 3 points avant 2010, pas de tournoi en 2019. Laissez ces trous apparents sur les courbes plutôt que de les remplir par des zéros.

## Six dashboards thématiques

Chacun répond à une question, avec un chiffre qui l'ouvre. Les chiffres ont été calculés sur la base du projet ; les requêtes sont en annexe.

### 1. Le terrain ou le classement ?

- **Question** : l'avantage du terrain existe-t-il, et pèse-t-il autant que l'écart de niveau ?
- **Table** : `rpt_team_games`.
- **Charts** : Big Number du taux de victoire à domicile (filtre `game_type = 'Regular'`, `team_location = 'Home'`) ; Line Chart de `home_win_pct` par saison depuis `rpt_season_overview` ; Bar Chart du taux de victoire du mieux classé au tournoi, par `team_location` (filtre `team_seed < opponent_seed`).
- **Accroche** : en saison régulière, l'équipe qui reçoit gagne **61,6 %** des matchs non neutres. Au tournoi, elle en gagne **80 %**, mais c'est surtout parce que les mieux classées accueillent les premiers tours (93 % des cas). À seed meilleur égal, le favori gagne **75 %** des matchs sur terrain neutre et **83 %** chez lui : le terrain ajoute environ 8 points de pourcentage.
- **Piège** : les taux Home et Away sont complémentaires par construction (le perdant de l'un est le gagnant de l'autre) ; comparez des saisons, des contextes ou des équipes, pas Home contre Away.

### 2. Le tir à 3 points prend-il le pouvoir ?

- **Question** : le jeu se déplace-t-il derrière l'arc, et ceux qui tirent plus de loin gagnent-ils plus ?
- **Tables** : `rpt_season_overview` pour la tendance, `rpt_team_games` pour les équipes (filtre `has_box_score`).
- **Charts** : Line Chart de `three_pt_attempt_share` par saison ; Line Chart de l'adresse à 3 points (`SUM(fgm3) / SUM(fga3)` sur `rpt_team_games`) ; **Bubble Chart** une bulle par `team_name` sur une saison : x = `SUM(fga3) / SUM(fga)`, y = `AVG(CASE WHEN is_win THEN 1 ELSE 0 END)`, taille = `COUNT(*)`.
- **Accroche** : la part des tirs tentés à 3 points passe de **28,3 %** en 2010 à **32,5 %** en 2019, et l'essentiel de la hausse se fait après 2015, alors que l'adresse à 3 points reste stable autour de **31 %**.

### 3. Les surprises du tournoi

- **Question** : le tournoi est-il une loterie ?
- **Tables** : `rpt_games` (filtre `game_type = 'Tournament'`), `rpt_season_overview` pour les colonnes `champion_seed` et `tourney_upset_pct`.
- **Charts** : Bar Chart des matchs par `upset_label` ; **Heatmap** `w_seed_number` x `l_seed_number` ; Line Chart de `tourney_upset_pct` par saison ; Pie Chart des titres par `champion_seed`.
- **Accroche** : **21,7 %** des matchs du tournoi (287 sur 1 323) sont gagnés par l'équipe la moins bien classée, mais un seul avec 10 seeds d'écart ou plus en 21 tournois, et les 21 champions étaient tous seed 1 (17) ou seed 2 (4). Les surprises existent au premier tour, jamais au bout.

### 4. Les dynasties

- **Question** : qui domine, et pendant combien de temps ?
- **Tables** : `rpt_tourney_runs`, `rpt_team_season_stats`, ou les exemples `rpt_uconn_tennessee_*`.
- **Charts** : Bar Chart des titres et des Final Four par équipe (`tourney_wins >= 4`) ; Line Chart du `win_pct` des 5 meilleures équipes par saison ; Table des saisons régulières invaincues (`losses = 0`).
- **Accroche** : Connecticut remporte **10 des 21 titres** entre 1998 et 2018 et atteint **16** Final Four ; Tennessee suit avec 3 titres et 8 Final Four.

### 5. Où sont les puissances ?

- **Question** : quels États produisent les meilleures équipes, une fois corrigé du nombre d'équipes ?
- **Tables** : `rpt_team_season_stats` (par état d'équipe), `rpt_tourney_runs`.
- **Charts** : deux **Country Map** côte à côte sur `team_state_iso` : qualifications au tournoi en volume (`SUM(CASE WHEN made_tourney THEN 1 ELSE 0 END)`) puis par équipe (la même somme divisée par `COUNT(DISTINCT team_name)`) ; Bar Chart des Final Four par état.
- **Accroche** : en volume, le Texas mène (**101** qualifications, 23 équipes) devant la Californie (94, 25 équipes) : ce sont surtout les États qui ont le plus d'équipes. Par équipe, le Tennessee arrive en tête des grands États (**7,2** qualifications par équipe, contre 4,4 au Texas), et le Connecticut cumule **16** Final Four avec une seule équipe. Une carte en volume ressemble souvent à une carte de la population.

### 6. Matchs serrés et prolongations

- **Question** : combien de matchs se jouent dans les dernières possessions, et certaines équipes y sont-elles meilleures ?
- **Tables** : `rpt_games`, `rpt_team_games`.
- **Charts** : **Histogram** de `score_margin` (ou de `total_points`) ; Big Number de la part des matchs serrés ; Table des équipes au meilleur bilan dans les matchs serrés (filtre `is_close_game`, au moins 30 matchs) à côté de leur bilan global ; Table des matchs à plusieurs prolongations (`num_ot >= 3`, filtre `season >= 2005`).
- **Accroche** : en saison régulière, **21,4 %** des matchs se jouent à 5 points ou moins et **4,3 %** vont en prolongation sur 2005-2019, jusqu'à 5 prolongations dans un même match. Si le bilan d'une équipe dans les matchs serrés suit de près son bilan global, c'est du niveau plus que du sang-froid.

## Annexe : requêtes de vérification

À lancer dans SQL Lab ou dans le terminal DuckDB (`task duckdb`).

```sql
-- 0. Vue d'ensemble : premières et dernières saisons
SELECT season, total_games, teams_count, avg_total_points, close_game_pct, champion_name
FROM reporting.rpt_season_overview
WHERE season IN (1998, 2013, 2014, 2015, 2019)
ORDER BY season;

-- 1. Avantage du terrain (saison régulière)
SELECT team_location, count(*) AS lignes,
       round(avg(CASE WHEN is_win THEN 1 ELSE 0 END) * 100, 1) AS win_pct
FROM reporting.rpt_team_games
WHERE game_type = 'Regular'
GROUP BY team_location ORDER BY team_location;

-- 1 bis. Au tournoi, taux de victoire du mieux classé selon le lieu
SELECT team_location, count(*) AS matchs,
       round(avg(CASE WHEN is_win THEN 1 ELSE 0 END) * 100, 1) AS win_pct
FROM reporting.rpt_team_games
WHERE game_type = 'Tournament' AND team_seed < opponent_seed
GROUP BY team_location ORDER BY team_location;

-- 2. Part des tirs à 3 points et adresse à 3 points par saison (box score, 2010+)
SELECT season,
       round(sum(fga3)::double / sum(fga) * 100, 1)  AS part_tirs_3pts,
       round(sum(fgm3)::double / sum(fga3) * 100, 1) AS adresse_3pts
FROM reporting.rpt_team_games
WHERE has_box_score AND game_type = 'Regular'
GROUP BY season ORDER BY season;

-- 3. Upsets au tournoi, puis seed des champions
SELECT count(*) AS matchs,
       sum(CASE WHEN is_upset THEN 1 ELSE 0 END) AS upsets,
       round(avg(CASE WHEN is_upset THEN 1 ELSE 0 END) * 100, 1) AS pct_upsets,
       sum(CASE WHEN upset_label = 'Cinderella (10+ seeds)' THEN 1 ELSE 0 END) AS ecart_10_seeds_ou_plus
FROM reporting.rpt_games
WHERE game_type = 'Tournament';

SELECT champion_seed, count(*) AS titres
FROM reporting.rpt_season_overview
WHERE champion_seed IS NOT NULL
GROUP BY champion_seed ORDER BY champion_seed;

-- 4. Titres et Final Four par équipe
SELECT team_name,
       sum(CASE WHEN is_champion THEN 1 ELSE 0 END) AS titres,
       sum(CASE WHEN tourney_wins >= 4 THEN 1 ELSE 0 END) AS final_four
FROM reporting.rpt_tourney_runs
GROUP BY team_name ORDER BY titres DESC, final_four DESC LIMIT 5;

-- 5. Qualifications au tournoi par état d'équipe, en volume et par équipe
SELECT team_state,
       count(DISTINCT team_name) AS equipes,
       sum(CASE WHEN made_tourney THEN 1 ELSE 0 END) AS qualifications,
       round(sum(CASE WHEN made_tourney THEN 1 ELSE 0 END) / count(DISTINCT team_name), 1) AS qualifications_par_equipe
FROM reporting.rpt_team_season_stats
GROUP BY team_state ORDER BY qualifications DESC LIMIT 6;

-- 6. Matchs serrés et prolongations (saison régulière, prolongations à partir de 2005)
SELECT round(avg(CASE WHEN is_close_game THEN 1 ELSE 0 END) * 100, 1) AS pct_serres,
       round(avg(CASE WHEN has_overtime AND season >= 2005 THEN 1
                      WHEN season >= 2005 THEN 0 END) * 100, 1) AS pct_prolongation_2005,
       max(num_ot) AS max_prolongations
FROM reporting.rpt_games
WHERE game_type = 'Regular';
```
