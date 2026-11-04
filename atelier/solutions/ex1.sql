-- Solutions de l'échauffement (à lancer depuis la racine du projet, dans : duckdb)

-- 1. Combien de matchs de saison régulière par saison ?
select Season, count(*) as matchs
from read_parquet('processed-resources/WRegularSeasonCompactResults/*.parquet')
group by Season
order by Season;

-- 2. Quelles sont les 5 équipes avec le plus de victoires en saison régulière 2019 ?
select t.TeamName, count(*) as victoires
from read_parquet('processed-resources/WRegularSeasonCompactResults/*.parquet') r
join read_parquet('processed-resources/WTeams/*.parquet') t on r.WTeamID = t.TeamID
where r.Season = 2019
group by t.TeamName
order by victoires desc
limit 5;

-- 3. Le score moyen d'un match (les deux équipes) a-t-il évolué entre 1998 et 2019 ?
select Season, round(avg(WScore + LScore), 1) as points_par_match
from read_parquet('processed-resources/WRegularSeasonCompactResults/*.parquet')
group by Season
order by Season;

-- Bonus : comparer la taille du CSV et du Parquet
-- (dans le terminal : ls -lh resources/WRegularSeasonCompactResults.csv processed-resources/WRegularSeasonCompactResults/)
