select 
    a.artist_id as artist_id,
    a.month as month,
    a.total_streams as total_streams,
    a.unique_listeners as unique_listeners,
    a.repeat_listeners as repeat_listeners,
    a.streams_per_listener as streams_per_listener,
    a.repeat_listener_rate as repeat_listener_rate,
    a.total_ms_played as total_ms_played,
    coalesce(n.new_listeners, 0) as new_listeners,
    coalesce(e.total_engagements, 0) as total_engagements,
    coalesce(e.shares, 0) as shares,
    coalesce(e.saves, 0) as saves,
    coalesce(e.playlist_adds, 0) as playlist_adds,
    coalesce(c.monthly_spend, 0) as monthly_spend
from {{ ref('int_artists_monthly') }} as a

left join {{ ref('int_engagements_monthly') }} as e
    on a.artist_id = e.artist_id
    and a.month = e.month

left join {{ ref('int_new_listeners_monthly') }} as n
    on a.artist_id = n.artist_id
    and a.month = n.month

left join {{ ref('int_artist_campaigns_monthly') }} as c
    on a.artist_id = c.artist_id
    and a.month = c.month