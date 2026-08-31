-- =======================================================================
-- grain: 1 row per listener per artist
-- goal: identify the first stream timestamp for each listener-artist pair
-- =======================================================================

select
    s.listener_id,
    t.artist_id,
    min(s.stream_timestamp) as first_stream_timestamp

from {{ ref('stg_stream_events') }} as s
inner join {{ ref('stg_tracks') }} as t
    on s.track_id = t.track_id

group by
    s.listener_id,
    t.artist_id


