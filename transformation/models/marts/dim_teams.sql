with teams as (
    select * from {{ ref('stg_teams') }}
),
compact as (
    select * from {{ ref('stg_regular_season_compact_results') }}
),
game_cities as (
    select * from {{ ref('stg_game_cities') }}
),
cities as (
    select * from {{ ref('stg_cities') }}
),
home_games as (
    select c.season, c.day_num, c.w_team_id as home_team_id, c.w_team_id, c.l_team_id
    from compact c
    where c.w_loc = 'H'

    union all

    select c.season, c.day_num, c.l_team_id as home_team_id, c.w_team_id, c.l_team_id
    from compact c
    where c.w_loc = 'A'
),
home_game_states as (
    select
        hg.home_team_id as team_id,
        ci.state
    from home_games hg
    inner join game_cities gc
        on  hg.season    = gc.season
        and hg.day_num   = gc.day_num
        and hg.w_team_id = gc.w_team_id
        and hg.l_team_id = gc.l_team_id
    inner join cities ci on gc.city_id = ci.city_id
),
team_state_ranked as (
    select
        team_id,
        state,
        count(*)       as cnt,
        row_number() over (partition by team_id order by count(*) desc) as rn
    from home_game_states
    group by team_id, state
),
team_states as (
    select
        team_id,
        state          as team_state,
        'US-' || state as team_state_iso
    from team_state_ranked
    where rn = 1
),
final as (
    select
        t.team_id,
        t.team_name,
        ts.team_state,
        ts.team_state_iso
    from teams t
    left join team_states ts on t.team_id = ts.team_id
)
select * from final
