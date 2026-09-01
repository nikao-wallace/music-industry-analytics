select
    a.artist_id,
    a.month

from {{ ref('int_artists_monthly') }} as a

left join {{ ref('artists_monthly') }} as m
    on a.artist_id = m.artist_id
    and a.month = m.month
where m.artist_id is null