select * 
from {{ ref('stg_tracks') }}
where duration_ms <= 0