-- Budget estimé vs performance au tournoi NCAA par équipe et saison
-- Les budgets sont des estimations basées sur :
--   - Données EADA publiques (Equity in Athletics Disclosure Act)
--   - Articles de presse (Extra Points, Sportico, USA Today)
--   - Corrélation connue entre investissement programme et seed NCAA
-- Budget de base 2010, avec croissance annuelle de ~5% (tendance NCAA)

with tourney as (
    select * from {{ ref('fct_tourney_games') }}
),
teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),
seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),
seeds as (
    select season, team_id, seed_number, seed_region
    from {{ ref('stg_tourney_seeds') }}
),
-- Budget de base 2010 par programme (en milliers $, estimations EADA)
-- Top programmes : données publiques connues
-- Autres : estimation par historique de seed moyen
known_budgets as (
    select * from (values
        ('Connecticut',    8000), ('Tennessee',      7500), ('Stanford',       6500),
        ('Notre Dame',     6000), ('Baylor',         5500), ('Duke',           5500),
        ('South Carolina', 5000), ('Louisville',     4800), ('Texas A&M',      4800),
        ('Maryland',       4500), ('Ohio St',        4500), ('Texas',          4500),
        ('North Carolina', 4500), ('LSU',            4200), ('Georgia',        4200),
        ('Oklahoma',       4000), ('Purdue',         4000), ('Rutgers',       4000),
        ('Florida St',     3800), ('Oregon',         3500), ('Iowa',           3500),
        ('Vanderbilt',     3500), ('Michigan St',    3500), ('Iowa St',        3400),
        ('NC State',       3400), ('Penn St',        3400), ('Kentucky',       3400),
        ('Arizona St',     3200), ('DePaul',         3000), ('Nebraska',       3000),
        ('Virginia',       3200), ('UCLA',           3200), ('Auburn',         3000),
        ('Gonzaga',        2800), ('Mississippi St',  3500), ('Kansas St',     2800),
        ('Syracuse',       3000), ('South Dakota St', 2200), ('West Virginia', 3000),
        ('Dayton',         2500), ('St John''s',     2500), ('Marquette',      2500),
        ('BYU',            2400), ('Florida',        3200), ('Villanova',      2800),
        ('Mississippi',    3000), ('South Florida',  2500), ('James Madison',  2000)
    ) as t(team_name, budget_base_2010_k)
),
-- Toutes les participations au tournoi (une ligne par équipe/saison via seeds)
tourney_teams as (
    select
        sd.season,
        sd.team_id,
        sd.seed_number,
        sd.seed_region
    from seeds sd
),
-- Résultats du tournoi par équipe
team_tourney_results as (
    select
        season, w_team_id as team_id, 1 as is_win,
        w_score as pts_scored, l_score as pts_allowed,
        is_upset, seed_difference
    from tourney

    union all

    select
        season, l_team_id as team_id, 0 as is_win,
        l_score as pts_scored, w_score as pts_allowed,
        is_upset, seed_difference
    from tourney
),
team_results_agg as (
    select
        season,
        team_id,
        count(*)                                as tourney_games,
        sum(is_win)                             as tourney_wins,
        count(*) - sum(is_win)                  as tourney_losses,
        round(avg(pts_scored), 1)               as avg_pts_scored,
        round(avg(pts_allowed), 1)              as avg_pts_allowed,
        round(avg(pts_scored - pts_allowed), 1) as avg_pt_diff,
        count(case when is_upset then 1 end)    as upsets_involved
    from team_tourney_results
    group by season, team_id
),
-- Budget estimé : connu ou estimé par seed
budget_estimates as (
    select
        tt.season,
        tt.team_id,
        tt.seed_number,
        tt.seed_region,
        t.team_name,
        -- Budget de base : connu ou estimé par seed
        coalesce(
            kb.budget_base_2010_k,
            case
                when tt.seed_number <= 2  then 5000
                when tt.seed_number <= 4  then 4000
                when tt.seed_number <= 6  then 3200
                when tt.seed_number <= 8  then 2800
                when tt.seed_number <= 10 then 2200
                when tt.seed_number <= 12 then 1800
                when tt.seed_number <= 14 then 1400
                else                           1100
            end
        ) as budget_base_k,
        -- Croissance annuelle ~5% depuis 2010
        round(
            coalesce(
                kb.budget_base_2010_k,
                case
                    when tt.seed_number <= 2  then 5000
                    when tt.seed_number <= 4  then 4000
                    when tt.seed_number <= 6  then 3200
                    when tt.seed_number <= 8  then 2800
                    when tt.seed_number <= 10 then 2200
                    when tt.seed_number <= 12 then 1800
                    when tt.seed_number <= 14 then 1400
                    else                           1100
                end
            ) * power(1.05, tt.season - 2010), 0
        ) as estimated_budget_k
    from tourney_teams tt
    left join teams t on tt.team_id = t.team_id
    left join known_budgets kb on t.team_name = kb.team_name
),
final as (
    select
        be.team_name,
        t.team_state,
        t.team_state_iso,
        s.season_label,
        be.season,
        be.seed_number,
        be.seed_region,
        be.estimated_budget_k,
        round(be.estimated_budget_k / 1000.0, 1)               as estimated_budget_m,
        coalesce(tr.tourney_games, 0)                           as tourney_games,
        coalesce(tr.tourney_wins, 0)                            as tourney_wins,
        coalesce(tr.tourney_losses, 0)                          as tourney_losses,
        tr.avg_pts_scored,
        tr.avg_pts_allowed,
        tr.avg_pt_diff,
        coalesce(tr.upsets_involved, 0)                         as upsets_involved,
        case coalesce(tr.tourney_wins, 0)
            when 6 then 'Champion'
            when 5 then 'Runner-Up'
            when 4 then 'Final Four'
            when 3 then 'Elite Eight'
            when 2 then 'Sweet Sixteen'
            when 1 then 'Second Round'
            when 0 then 'First Round Exit'
        end                                                     as tournament_result,
        coalesce(tr.tourney_wins, 0) = 6                        as is_champion,
        -- ROI simplifié : victoires tournoi par million $ investi
        round(
            coalesce(tr.tourney_wins, 0)::double
            / nullif(be.estimated_budget_k / 1000.0, 0), 2
        )                                                       as wins_per_million
    from budget_estimates be
    left join teams              t  on be.team_id = t.team_id
    left join seasons            s  on be.season  = s.season
    left join team_results_agg   tr on be.season  = tr.season and be.team_id = tr.team_id
)
select * from final
