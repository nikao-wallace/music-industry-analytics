select
    artist_id,
    campaign_month as month,
    sum(allocated_spend) as monthly_spend

from {{ ref('int_campaigns_monthly') }}

group by
    artist_id,
    campaign_month