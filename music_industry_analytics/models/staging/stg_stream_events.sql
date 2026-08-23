with source as (
    select *
    from {{ source('music_raw', 'stream_events') }}
), 

    cleaned as (
    
    select 
        trim(stream_id) as stream_id,
        trim(track_id) as track_id,
        trim(listener_id) as listener_id,
        cast(stream_timestamp as timestamp) as stream_timestamp,
        cast(ms_played as numeric) as ms_played,
        coalesce(nullif(trim(streaming_platform), ''), 'unknown') as streaming_platform,
        coalesce(nullif(trim(country),''), 'unknown') as country,
        coalesce(nullif(trim(lower(stream_source)), ''), 'unknown') as stream_source,
        coalesce(nullif(trim(lower(device_type)), ''), 'unknown') as device_type
    from source 

)

select *
from cleaned 