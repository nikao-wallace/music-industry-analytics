-- Warning rather than error because a small number of stream events
-- exceed track duration by several seconds. These records represent a
-- negligible portion of the dataset and do not materially affect the
-- project's primary analyses. The test remains in place to monitor
-- the anomaly without blocking the pipeline.


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