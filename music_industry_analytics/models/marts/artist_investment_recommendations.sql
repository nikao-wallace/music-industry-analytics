--=============================================================
-- Grain: 1 row per artist
-- Jan-Jul 2026 performance compared with Jan-Jul 2025
--=============================================================

with artists as (
select
    a.artist_id,
    s.artist_name,
    year(a.month) as year,
    sum(a.total_streams) as total_streams,
    sum(a.new_listeners) as new_listeners,
    sum(a.monthly_spend) as monthly_spend,
    sum(a.total_engagements) / nullif(sum(a.total_streams), 0) as engagement_rate,
    sum(a.repeat_listeners) / nullif(sum(a.unique_listeners), 0) as repeat_listener_rate,
    sum(a.monthly_spend) / nullif(sum(a.total_streams),0) as cost_per_stream,
    sum(a.monthly_spend) / nullif(sum(a.new_listeners),0) as cost_per_new_listener

from {{ ref('artists_monthly') }} as a 
join {{ ref('stg_artists') }} as s 
on a.artist_id = s.artist_id
where month(a.month) < 8
group by a.artist_id, s.artist_name, year 
),

-- 2025 Metrics

year_2025 as (
    select *
    from artists 
    where year = 2025

),
-- 2026 Metrics

year_2026 as (
    select *,
        
    from artists 
    where year = 2026
   
),

-- one row per artist with YoY comparisons

comparison as (
select
    x.artist_id,
    x.artist_name,

    y.monthly_spend as spend_2025,
    x.monthly_spend as spend_2026,
    (x.monthly_spend - y.monthly_spend)
        / nullif(y.monthly_spend, 0) as spend_pct_change,

    y.cost_per_stream as cps_2025,
    x.cost_per_stream as cps_2026,
    (x.cost_per_stream - y.cost_per_stream)
        / nullif(y.cost_per_stream, 0) as cps_pct_change,

    y.cost_per_new_listener as cpnl_2025,
    x.cost_per_new_listener as cpnl_2026,
    (x.cost_per_new_listener - y.cost_per_new_listener)
        / nullif(y.cost_per_new_listener, 0) as cpnl_pct_change,

    y.total_streams as streams_2025,
    x.total_streams as streams_2026,
    (x.total_streams - y.total_streams)
        / nullif(y.total_streams, 0) as stream_pct_change,

    y.new_listeners as new_listeners_2025,
    x.new_listeners as new_listeners_2026,
    (x.new_listeners - y.new_listeners)
        / nullif(y.new_listeners, 0) as new_listener_pct_change,

    y.repeat_listener_rate as repeat_listener_rate_2025,
    x.repeat_listener_rate as repeat_listener_rate_2026,
    x.repeat_listener_rate - y.repeat_listener_rate
        as repeat_listener_rate_change,

    y.engagement_rate as engagement_rate_2025,
    x.engagement_rate as engagement_rate_2026,
    x.engagement_rate - y.engagement_rate
        as engagement_rate_change

from year_2026 as x
inner join year_2025 as y
    on x.artist_id = y.artist_id

)

-- Final one row per artist comparison metrics with 2027 marketing investment recommendations

select
    *,
    case 
    when stream_pct_change > 0
    and new_listener_pct_change > 0
    and cps_pct_change < 0
    and cpnl_pct_change < 0
    and repeat_listener_rate_change > 0
        then 'Increase Investment'

    when cps_pct_change > 0
     and cpnl_pct_change > 0
     and spend_pct_change > 0
        then 'Reduce / Reassess'

    else 'Maintain / Monitor'
    end as recommendation
    
    
from comparison




