-- ===============================================================================
-- grain: 1 row per artist per month
-- goal: count listeners whose first stream for the artist occurred in each month
-- ===============================================================================

select 
    artist_id,
    date_trunc('month',first_stream_timestamp) as month,
    count(listener_id) as new_listeners
from {{ ref('int_artist_listener_first_stream') }}
group by artist_id, month 