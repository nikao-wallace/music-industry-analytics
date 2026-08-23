{{ config(severity='warn') }}

select
    s.stream_id,
    s.track_id,
    s.ms_played,
    t.duration_ms
from {{ ref('stg_stream_events') }} as s
inner join {{ ref('stg_tracks') }} as t
    on s.track_id = t.track_id
where s.ms_played > t.duration_ms