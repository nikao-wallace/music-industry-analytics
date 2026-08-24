select *
from {{ ref('stg_marketing_campaigns') }}
where start_date > end_date