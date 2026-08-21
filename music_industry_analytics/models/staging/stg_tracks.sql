with source as (

    select *
    from {{ source('music_raw', 'tracks') }}

),

renamed as (

    select
        trim(track_id) as track_id,
        trim(artist_id) as artist_id, 
        trim(track_name) as track_name,  
        cast(duration_ms as numeric) as duration_ms, 
        cast(release_date as date) as release_date
    from source 
    
)

select *
from renamed