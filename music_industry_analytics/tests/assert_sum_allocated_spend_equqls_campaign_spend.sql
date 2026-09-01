select 
    c.campaign_id,
    m.spend as source_spend,
    sum(c.allocated_spend)
from {{ ref('int_campaigns_monthly') }} as c 
inner join {{ ref('stg_marketing_campaigns') }} as m 
on c.campaign_id = m.campaign_id
group by c.campaign_id, source_spend
having abs(sum(c.allocated_spend) - m.spend) > 0.01