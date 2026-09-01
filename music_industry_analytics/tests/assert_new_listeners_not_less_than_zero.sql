select *
from {{ ref('int_new_listeners_monthly') }}
where new_listeners < 0