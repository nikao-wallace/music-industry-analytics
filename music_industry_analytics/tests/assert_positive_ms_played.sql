select * 
from {{ ref('stg_stream_events') }}
where ms_played <= 0