select *
from {{ ref('int_artists_monthly') }}
where repeat_listeners > unique_listeners