with eligible_artists as (

    select artist_id
    from {{ ref('artists_monthly') }}
    where year(month) in (2025, 2026)
      and month(month) < 8

    group by artist_id

    having count(distinct year(month)) = 2

),

recommendation_artists as (

    select artist_id
    from {{ ref('artist_investment_recommendations') }}

)

select
    e.artist_id

from eligible_artists e
left join recommendation_artists r
    on e.artist_id = r.artist_id

where r.artist_id is null