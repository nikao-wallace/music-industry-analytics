with artists as (
select 
    t.artist_id as artist_id,
    date_trunc('month', s.stream_timestamp) as month,
    count(s.stream_id) as total_streams,
    count(DISTINCT s.listener_id) as unique_listeners,
    sum(s.ms_played) as total_ms_played
from {{ ref('stg_stream_events') }} as s
inner join {{ ref('stg_tracks') }} as t
    on s.track_id = t.track_id
group by t.artist_id, month
),

listeners as (
select 
    s.listener_id,
    t.artist_id,
    count(s.stream_id) as listener_streams,
    date_trunc('month', s.stream_timestamp) as month 
from {{ ref('stg_stream_events') }} as s
inner join {{ ref('stg_tracks') }} as t
    on s.track_id = t.track_id
group by s.listener_id, t.artist_id, month 
),

repeat_stats as (
    select 
        l.artist_id,
        l.month, 
        sum(
        case when l.listener_streams > 1 then 1
        else 0 end 
    ) as repeat_listeners
    from listeners as l
    group by l.artist_id, l.month
)

select 
    a.artist_id as artist_id,
    r.month as month,
    a.unique_listeners as unique_listeners,
    a.total_streams as total_streams,
    r.repeat_listeners as repeat_listeners,
    a.total_streams/nullif(a.unique_listeners,0) as streams_per_listener,
    a.total_ms_played as total_ms_played,
    r.repeat_listeners/nullif(a.unique_listeners,0) as repeat_listener_rate
from artists as a 
inner join repeat_stats as r 
on a.artist_id = r.artist_id
and a.month = r.month
