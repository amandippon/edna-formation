-- Une ligne par équipe et par match (saison régulière + tournoi NCAA),
-- vue depuis l'équipe : chaque match apparaît deux fois (gagnant puis perdant).
-- Table la plus souple pour Superset : filtrer sur une équipe suffit pour
-- obtenir tout son historique, sans union gagnant/perdant.

with regular as (
    select
        *,
        null::integer as w_seed_number,
        null::integer as l_seed_number,
        null::boolean as is_upset
    from {{ ref('fct_regular_season_games') }}
),

tourney as (
    select * from {{ ref('fct_tourney_games') }}
),

all_games as (
    select * exclude (w_seed_number, l_seed_number, is_upset), w_seed_number, l_seed_number, is_upset
    from regular
    union all by name
    select * exclude (w_seed_raw, w_seed_region, l_seed_raw, l_seed_region, seed_difference)
    from tourney
),

-- point de vue du gagnant
winner_view as (
    select
        game_id,
        game_type,
        season,
        game_date,
        w_team_id                                           as team_id,
        l_team_id                                           as opponent_id,
        true                                                as is_win,
        w_score                                             as pts_for,
        l_score                                             as pts_against,
        case w_loc when 'H' then 'Home' when 'A' then 'Away' else 'Neutral' end
                                                            as team_location,
        num_ot,
        has_overtime,
        is_close_game,
        city_id,
        w_seed_number                                       as team_seed,
        l_seed_number                                       as opponent_seed,
        is_upset                                            as is_upset_win,
        case when game_type = 'Tournament' then false end   as is_upset_loss,
        has_box_score,
        w_fgm   as fgm,   w_fga   as fga,   w_fg_pct  as fg_pct,
        w_fgm3  as fgm3,  w_fga3  as fga3,  w_fg3_pct as fg3_pct,
        w_ftm   as ftm,   w_fta   as fta,   w_ft_pct  as ft_pct,
        w_or    as oreb,  w_dr    as dreb,
        w_ast   as ast,   w_to    as tov,   w_stl     as stl,
        w_blk   as blk,   w_pf    as pf,
        l_fg_pct  as opp_fg_pct,
        l_fg3_pct as opp_fg3_pct,
        l_or + l_dr as opp_reb,
        l_to      as opp_tov
    from all_games
),

-- point de vue du perdant
loser_view as (
    select
        game_id,
        game_type,
        season,
        game_date,
        l_team_id                                           as team_id,
        w_team_id                                           as opponent_id,
        false                                               as is_win,
        l_score                                             as pts_for,
        w_score                                             as pts_against,
        case w_loc when 'H' then 'Away' when 'A' then 'Home' else 'Neutral' end
                                                            as team_location,
        num_ot,
        has_overtime,
        is_close_game,
        city_id,
        l_seed_number                                       as team_seed,
        w_seed_number                                       as opponent_seed,
        case when game_type = 'Tournament' then false end   as is_upset_win,
        is_upset                                            as is_upset_loss,
        has_box_score,
        l_fgm   as fgm,   l_fga   as fga,   l_fg_pct  as fg_pct,
        l_fgm3  as fgm3,  l_fga3  as fga3,  l_fg3_pct as fg3_pct,
        l_ftm   as ftm,   l_fta   as fta,   l_ft_pct  as ft_pct,
        l_or    as oreb,  l_dr    as dreb,
        l_ast   as ast,   l_to    as tov,   l_stl     as stl,
        l_blk   as blk,   l_pf    as pf,
        w_fg_pct  as opp_fg_pct,
        w_fg3_pct as opp_fg3_pct,
        w_or + w_dr as opp_reb,
        w_to      as opp_tov
    from all_games
),

team_games as (
    select * from winner_view
    union all
    select * from loser_view
),

teams as (
    select team_id, team_name, team_state, team_state_iso from {{ ref('dim_teams') }}
),

seasons as (
    select season, season_label from {{ ref('dim_seasons') }}
),

cities as (
    select city_id, city, state from {{ ref('dim_cities') }}
),

final as (
    select
        -- identifiants
        g.game_id || '_' || cast(g.team_id as varchar)     as team_game_id,
        g.game_id,
        g.game_type,

        -- calendrier
        g.season,
        s.season_label,
        g.game_date,

        -- équipe et adversaire
        g.team_id,
        t.team_name,
        t.team_state,
        t.team_state_iso,
        g.opponent_id,
        o.team_name                                         as opponent_name,

        -- résultat
        g.is_win,
        case when g.is_win then 'W' else 'L' end            as result,
        g.pts_for,
        g.pts_against,
        g.pts_for - g.pts_against                           as pt_diff,
        g.team_location,
        g.num_ot,
        g.has_overtime,
        g.is_close_game,

        -- lieu du match (nullable : données villes à partir de 2010)
        c.city,
        c.state,
        case when c.state is not null then 'US-' || c.state end
                                                            as state_iso,

        -- tournoi (null en saison régulière)
        g.team_seed,
        g.opponent_seed,
        g.is_upset_win,
        g.is_upset_loss,

        -- box score de l'équipe (nullable : détaillé à partir de 2010)
        g.has_box_score,
        g.fgm,
        g.fga,
        g.fg_pct,
        g.fgm3,
        g.fga3,
        g.fg3_pct,
        g.ftm,
        g.fta,
        g.ft_pct,
        g.oreb,
        g.dreb,
        g.oreb + g.dreb                                     as reb,
        g.ast,
        g.tov,
        g.stl,
        g.blk,
        g.pf,

        -- quelques stats de l'adversaire
        g.opp_fg_pct,
        g.opp_fg3_pct,
        g.opp_reb,
        g.opp_tov

    from team_games g
    left join teams   t on g.team_id     = t.team_id
    left join teams   o on g.opponent_id = o.team_id
    left join seasons s on g.season      = s.season
    left join cities  c on g.city_id     = c.city_id
)

select * from final
