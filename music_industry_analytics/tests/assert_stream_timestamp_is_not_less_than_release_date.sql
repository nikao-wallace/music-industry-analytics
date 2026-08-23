SELECT s.*
from {{ ref('stg_stream_events') }} as s 
inner join {{ ref('stg_tracks') }} as t
    on s.track_id = t.track_id
where s.stream_timestamp < t.release_date