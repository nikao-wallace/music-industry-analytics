with source as (

    select *
    from {{ source('music_raw', 'artists') }}

), 
    cleaned as (

    select
        trim(artist_id) as artist_id,
        initcap(trim(artist_name)) as artist_name,

        trim(genre) as genre,
        case
            when lower(trim(genre)) in 
                ('indie pop', 'synthpop','pop', 'latin pop', 'dance pop', 'jazz pop') then 'Pop'
            when lower(trim(genre)) in 
                ('alternative r&b','neo-soul') then 'R&B'
            when lower(trim(genre)) in 
                ('hip-hop', 'alternative hip-hop') then 'Hip-Hop'
            when lower(trim(genre)) in
                ('alternative', 'indie rock', 'pop punk') then 'Rock'
            when lower(trim(genre)) in 
                ('folk', 'singer-songwriter') then 'Folk'
            when lower(trim(genre)) = 
                'country' then 'Country'
            when lower(trim(genre)) = 
                'electronic' then 'Electronic'
            when lower(trim(genre)) = 
                'afrobeats' then 'World'
            else 'Other'
end as genre_group,

        cast(signed_date as date) as signed_date,
        lower(trim(artist_status)) as artist_status
    from source

)

select *
from cleaned