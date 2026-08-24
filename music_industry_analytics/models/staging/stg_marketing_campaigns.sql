with source as (
    select *
    from {{ source('music_raw', 'marketing_campaigns') }}
),

cleaned as (
    select
        trim(campaign_id)as campaign_id,
        trim(artist_id) as artist_id,
        trim(campaign_name) as campaign_name,
        trim(lower(channel)) as channel,
        cast(start_date as date) as start_date,
        cast(end_date as date) as end_date,
        cast(spend as numeric (10,2)) as spend 
    from source   

)

select *
from source 

