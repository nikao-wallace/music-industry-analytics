SELECT e.*
from {{ ref('stg_engagement_events') }} as e
inner join {{ ref('stg_tracks') }} as t
    on e.track_id = t.track_id
where e.event_timestamp < t.release_date