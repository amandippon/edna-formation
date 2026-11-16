-- Une ligne par saison : les indicateurs du dashboard « Vue d'ensemble ».
-- Volumes, physionomie des matchs (saison régulière) et palmarès du tournoi.
-- Les taux sont entre 0 et 1 ; ils sont nuls quand la donnée n'existe pas
-- (prolongations avant 2005, box score avant 2010, tournoi 2019).

with regular_games as (
    select * from {{ ref('fct_regular_season_games') }}
),

tourney_games as (
    select * from {{ ref('fct_tourney_games') }}
),

seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),

teams as (
    select team_id, team_name from {{ ref('dim_teams') }}
),

-- équipes ayant joué au moins un match de saison régulière
regular_teams as (
    select season, w_team_id as team_id from regular_games
    union
    select season, l_team_id as team_id from regular_games
),

teams_per_season as (
    select season, count(*)::integer as teams_count
    from regular_teams
    group by season
),

regular_stats as (
    select
        season,
        count(*)::integer                                       as regular_games,
        round(avg(total_points), 1)                             as avg_total_points,
        round(avg(score_margin), 1)                             as avg_score_margin,
        round(avg(case when is_close_game then 1 else 0 end), 3) as close_game_pct,
        -- aucune prolongation n'est renseignée avant 2005 dans les données sources
        case when season >= 2005
            then round(avg(case when has_overtime then 1 else 0 end), 3)
        end                                                     as overtime_pct,
        -- matchs non neutres : part gagnée par l'équipe qui reçoit
        round(avg(case game_location when 'Home' then 1 when 'Away' then 0 end), 3)
                                                                as home_win_pct,
        -- box score à partir de 2010 : nul avant
        round(
            sum(case when has_box_score then w_fga3 + l_fga3 end)::double
            / sum(case when has_box_score then w_fga + l_fga end),
            3
        )                                                       as three_pt_attempt_share
    from regular_games
    group by season
),

tourney_stats as (
    select
        season,
        count(*)::integer                                       as tourney_games,
        sum(case when is_upset then 1 else 0 end)::integer      as tourney_upsets,
        round(avg(case when is_upset then 1 else 0 end), 3)     as tourney_upset_pct
    from tourney_games
    group by season
),

-- la finale est le dernier match du tournoi de la saison
finals as (
    select
        season,
        w_team_id     as champion_id,
        l_team_id     as runner_up_id,
        w_seed_number as champion_seed,
        w_score || '-' || l_score as final_score
    from tourney_games
    qualify row_number() over (partition by season order by game_date desc) = 1
),

final as (
    select
        s.season,
        s.season_label,
        -- 1er janvier de l'année de la saison : axe temporel pour Superset
        -- (day_zero tombe en novembre de l'année précédente et décalerait d'un an)
        make_date(s.season::integer, 1, 1)                      as season_date,

        -- volumes
        tps.teams_count,
        rs.regular_games,
        coalesce(ts.tourney_games, 0)                           as tourney_games,
        rs.regular_games + coalesce(ts.tourney_games, 0)        as total_games,

        -- physionomie des matchs de saison régulière
        rs.avg_total_points,
        rs.avg_score_margin,
        rs.close_game_pct,
        rs.overtime_pct,
        rs.home_win_pct,
        rs.three_pt_attempt_share,

        -- tournoi NCAA (nul pour 2019)
        ts.tourney_upsets,
        ts.tourney_upset_pct,
        champ.team_name                                         as champion_name,
        f.champion_seed,
        runner.team_name                                        as runner_up_name,
        f.final_score

    from seasons s
    inner join regular_stats     rs  on s.season = rs.season
    left join teams_per_season   tps on s.season = tps.season
    left join tourney_stats      ts  on s.season = ts.season
    left join finals             f   on s.season = f.season
    left join teams              champ  on f.champion_id  = champ.team_id
    left join teams              runner on f.runner_up_id = runner.team_id
)

select * from final
