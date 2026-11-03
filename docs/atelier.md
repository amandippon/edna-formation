# Fiche atelier : un dashboard par équipe

Objectif : en une heure, chaque équipe choisit **une question**, construit **un dashboard** Superset qui y répond, et le présente en 4 minutes.

Prérequis : Superset tourne (`task superset:up`), base **NCAA Basketball (DuckDB)** déjà connectée. Voir le [README](../README.md) en cas de souci.

## Déroulé de l'heure

| Temps | Jalon |
|---|---|
| 0 à 10 min | Choisir la question (liste plus bas ou la vôtre), repérer la table, lancer Superset sur une machine. |
| 10 à 25 min | Créer le ou les datasets, premier chart qui répond à la question, même brut. |
| 25 à 50 min | Enrichir : 3 à 5 charts, filtres natifs du dashboard (saison, équipe), titres explicites. Niveau 2 : un modèle dbt dédié. |
| 50 à 60 min | Figer le dashboard, choisir l'insight à raconter, préparer la restitution. |

Deux façons d'obtenir les données qu'il vous faut :

- **Dataset virtuel** : SQL Lab, requête, **Save > Save dataset**. Le plus rapide.
- **Modèle dbt** : `transformation/models/reporting/rpt_<sujet>.sql` puis `task superset:refresh`. Plus propre, testé, visible dans le lineage. Exemples dans `transformation/models/reporting/examples/`.

## Les tables `reporting`

| Table | Grain (une ligne =) | Lignes | Usage typique |
|---|---|---|---|
| `rpt_team_games` | une équipe dans un match | 216 912 | Table la plus souple : tout l'historique d'une équipe, domicile/extérieur, box score de son point de vue |
| `rpt_games` | un match (format gagnant/perdant) | 108 456 | Volumes de matchs, écarts de score, upsets au tournoi, carte des villes hôtes |
| `rpt_team_season_stats` | une équipe sur une saison régulière | 7 364 | Classements, bilans victoires/défaites, qualification au tournoi, carte par état |
| `rpt_tourney_runs` | une équipe sur un tournoi NCAA | 1 344 | Parcours au tournoi, titres, résultats par seed |
| `rpt_uconn_tennessee_*` | variable (5 tables d'exemple) | 2 à 1 574 | Rivalité Connecticut vs Tennessee, modèle à copier pour votre propre question |

### Colonnes clés

**`rpt_team_games`** : `team_name`, `opponent_name`, `season`, `game_date`, `game_type` (`Regular` ou `Tournament`), `is_win`, `result` (`W`/`L`), `pts_for`, `pts_against`, `pt_diff` (signé), `team_location` (`Home`, `Away`, `Neutral`, du point de vue de l'équipe), `has_overtime`, `num_ot`, `is_close_game`, `city`, `state`, `state_iso`, `team_state`, `team_state_iso`, `team_seed`, `opponent_seed`, `is_upset_win`, `is_upset_loss`, box score (`fgm`, `fga`, `fg_pct`, `fgm3`, `fga3`, `fg3_pct`, `ftm`, `fta`, `ft_pct`, `oreb`, `dreb`, `reb`, `ast`, `tov`, `stl`, `blk`, `pf`) et quelques stats adverses (`opp_fg_pct`, `opp_fg3_pct`, `opp_reb`, `opp_tov`).

**`rpt_games`** : `w_team_name`, `l_team_name`, `w_score`, `l_score`, `score_margin` (toujours positif), `game_location` (lieu du point de vue du gagnant), `is_close_game`, `has_overtime`, `city`, `state`, `state_iso`, `w_seed_number`, `l_seed_number`, `is_upset`, `upset_label`.

**`rpt_team_season_stats`** : `team_name`, `team_state`, `team_state_iso`, `season`, `games_played`, `wins`, `losses`, `win_pct`, `avg_pts_scored`, `avg_pts_allowed`, `avg_pt_diff`, `made_tourney`, `tourney_seed_number`.

**`rpt_tourney_runs`** : `team_name`, `team_state`, `season`, `seed_number`, `tourney_wins`, `tourney_losses`, `is_champion`, `tournament_result` (`Champion`, `Runner-Up`, `Final Four`, `Elite Eight`, `Sweet Sixteen`, `Second Round`, `First Round Exit`).

Les descriptions complètes sont dans `transformation/models/reporting/_reporting_models.yml` et dans le lineage Colibri (`task documentation`).

### Pièges à connaître

- **Couverture temporelle** : saison régulière de 1998 à 2019, tournoi de 1998 à **2018** (la compétition Kaggle portait sur 2019). Box score détaillé et villes des matchs seulement **à partir de 2010** : filtrez `has_box_score` ou `season >= 2010` pour ces colonnes.
- **Seeds** : `team_seed`, `opponent_seed`, `is_upset*` et `upset_label` sont nuls en saison régulière.
- **Saison** : `season = 2019` désigne la saison 2018-2019.
- **État d'une équipe** : `team_state` est déduit de l'état où l'équipe joue le plus à domicile (sur 2010-2019). Il est nul pour 4 équipes des tables reporting (14 dans `dim_teams`), faute de match localisé.
- **`rpt_team_games` compte chaque match deux fois** : pour compter des matchs, filtrez `is_win = true` ou comptez les `game_id` distincts.
- **`rpt_team_season_stats` ne couvre que la saison régulière** : les matchs de tournoi n'y sont pas.
- **Pourcentages entre 0 et 1** (`fg_pct`, `win_pct`…) : réglez le format d'affichage en `%` dans Superset.
- **Booléens** : pour un taux, créez une métrique SQL `AVG(CASE WHEN is_win THEN 1 ELSE 0 END)` ; pour un compte, `SUM(CASE WHEN is_close_game THEN 1 ELSE 0 END)`.
- **Cartes** : le chart **Country Map** (pays `usa`) attend des codes ISO comme `US-TX` : utilisez `team_state_iso` ou `state_iso`.
- **Temps** : `game_date` est la colonne temporelle pour les séries chronologiques ; `season` pour des agrégats par saison.

## Six idées de dashboards

Les chiffres d'accroche ont été calculés sur la base du projet ; les requêtes sont en annexe.

### 1. L'avantage du terrain existe-t-il ?

- **Table** : `rpt_team_games` (filtre `game_type = 'Regular'`).
- **Charts** : Big Number du taux de victoire à domicile ; line chart de ce taux par `season` ; table des équipes les plus fortes à domicile vs à l'extérieur.
- **Accroche** : en saison régulière, l'équipe qui reçoit gagne **61,6 %** des matchs non neutres (les deux taux Home/Away sont complémentaires par construction : comparez plutôt les saisons ou les équipes).

### 2. Le tir à 3 points prend-il le pouvoir ?

- **Table** : `rpt_team_games` (filtre `has_box_score`, saisons 2010 à 2019).
- **Charts** : line chart de la part des tirs tentés à 3 points (`SUM(fga3) / SUM(fga)`) et de l'adresse à 3 points par saison ; scatter plot équipes (tentatives à 3 points vs `win_pct`, via une requête SQL Lab qui joint `rpt_team_games` et `rpt_team_season_stats` sur `team_name` et `season`).
- **Accroche** : la part des tirs tentés à 3 points passe de **28,3 %** en 2010 à **32,5 %** en 2019, alors que l'adresse à 3 points reste stable autour de **31 %**.

### 3. Les surprises du tournoi

- **Table** : `rpt_games` (filtre `game_type = 'Tournament'`), ou `rpt_team_games` avec `is_upset_win`.
- **Charts** : bar chart des matchs par `upset_label` ; heatmap seed du gagnant x seed du perdant ; table des plus gros écarts de seed.
- **Accroche** : **21,7 %** des matchs du tournoi (287 sur 1 323) sont gagnés par l'équipe la moins bien classée, mais un seul match gagné avec 10 seeds d'écart ou plus en 21 tournois.

### 4. Les dynasties

- **Tables** : `rpt_tourney_runs`, `rpt_team_season_stats`, ou les exemples `rpt_uconn_tennessee_*`.
- **Charts** : bar chart des titres par équipe ; line chart du `win_pct` des meilleures équipes ; table des saisons régulières invaincues.
- **Accroche** : Connecticut remporte **10 des 21 titres** entre 1998 et 2018 ; Tennessee suit avec 3.

### 5. La géographie du basket féminin

- **Tables** : `rpt_team_season_stats` (par état d'équipe), `rpt_games` (par état du match, 2010+).
- **Charts** : Country Map US des qualifications au tournoi par `team_state_iso` ; Country Map des matchs accueillis par `state_iso` ; bar chart top 10 des états.
- **Accroche** : le Texas cumule le plus de qualifications au tournoi sur 1998-2019 (**101** participations d'équipes, devant la Californie avec 94).

### 6. Matchs serrés et prolongations

- **Tables** : `rpt_games`, `rpt_team_games`.
- **Charts** : Big Number de la part de matchs serrés ; histogramme de `score_margin` ; bar chart des équipes au meilleur bilan dans les matchs serrés ; table des matchs à plusieurs prolongations (`num_ot`, disponible dans `rpt_team_games`).
- **Accroche** : en saison régulière, **21,4 %** des matchs se jouent à 5 points ou moins et **3,1 %** vont en prolongation (jusqu'à 5 prolongations dans un même match).

## Restitution : 4 minutes par équipe

1. **La question** (30 s) : ce que vous vouliez savoir et pourquoi.
2. **Le dashboard** (2 min) : démonstration en direct, sans tout commenter.
3. **Une insight** (1 min) : le chiffre ou le graphique à retenir.
4. **Une difficulté** (30 s) : ce qui a coincé (donnée, outil, modélisation) et comment vous l'avez contourné.

## Annexe : requêtes de vérification

À lancer dans SQL Lab ou avec `duckdb -readonly edna-sports-data.duckdb`.

```sql
-- 1. Avantage du terrain (saison régulière)
SELECT team_location, count(*) AS lignes,
       round(avg(CASE WHEN is_win THEN 1 ELSE 0 END) * 100, 1) AS win_pct
FROM reporting.rpt_team_games
WHERE game_type = 'Regular'
GROUP BY team_location ORDER BY team_location;

-- 2. Part des tirs à 3 points et adresse à 3 points par saison (box score, 2010+)
SELECT season,
       round(sum(fga3)::double / sum(fga) * 100, 1)  AS part_tirs_3pts,
       round(sum(fgm3)::double / sum(fga3) * 100, 1) AS adresse_3pts
FROM reporting.rpt_team_games
WHERE has_box_score AND game_type = 'Regular'
GROUP BY season ORDER BY season;

-- 3. Upsets au tournoi
SELECT count(*) AS matchs,
       sum(CASE WHEN is_upset THEN 1 ELSE 0 END) AS upsets,
       round(avg(CASE WHEN is_upset THEN 1 ELSE 0 END) * 100, 1) AS pct_upsets,
       sum(CASE WHEN upset_label = 'Cinderella (10+ seeds)' THEN 1 ELSE 0 END) AS ecart_10_seeds_ou_plus
FROM reporting.rpt_games
WHERE game_type = 'Tournament';

-- 4. Titres par équipe
SELECT team_name, count(*) AS titres
FROM reporting.rpt_tourney_runs
WHERE is_champion
GROUP BY team_name ORDER BY titres DESC;

-- 5. Qualifications au tournoi par état d'équipe
SELECT team_state,
       count(DISTINCT team_name) AS equipes,
       sum(CASE WHEN made_tourney THEN 1 ELSE 0 END) AS qualifications
FROM reporting.rpt_team_season_stats
GROUP BY team_state ORDER BY qualifications DESC LIMIT 5;

-- 6. Matchs serrés et prolongations (saison régulière)
SELECT round(avg(CASE WHEN is_close_game THEN 1 ELSE 0 END) * 100, 1) AS pct_serres,
       round(avg(CASE WHEN has_overtime THEN 1 ELSE 0 END) * 100, 1) AS pct_prolongation,
       (SELECT max(num_ot) FROM reporting.rpt_team_games) AS max_prolongations
FROM reporting.rpt_games
WHERE game_type = 'Regular';
```
