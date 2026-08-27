-- Grain = 1 row per artist per month
-- Calculates total: engagements, shares, playlist_adds and saves


    select 
        t.artist_id as artist_id,
        date_trunc('month', e.event_timestamp) as month,
        count(e.engagement_id) as total_engagements,
        sum(
            case 
                when e.event_type = 'share' then 1 else 0 end
        ) as shares,
        sum(
            case 
                when e.event_type = 'save' then 1 else 0 end
        ) as saves,
        sum(
            case 
                when e.event_type = 'playlist_add' then 1 else 0 end
        ) as playlist_adds
    from {{ ref('stg_tracks') }} as t 
    inner join {{ ref('stg_engagement_events') }} as e 
    on t.track_id = e.track_id
    group by t.artist_id, month 
