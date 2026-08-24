with source as (
    select *
    from {{ source('music_raw', 'engagement_events') }}
),

cleaned as (
    select 
        trim(engagement_id) as engagement_id,
        trim(listener_id) as listener_id,
        trim(track_id) as track_id,
        cast(event_timestamp as timestamp) as event_timestamp,
        coalesce(
            nullif(trim(lower(event_type)), ''),
            'unknown'
            ) as event_type
    from source 
)

select *
from cleaned 