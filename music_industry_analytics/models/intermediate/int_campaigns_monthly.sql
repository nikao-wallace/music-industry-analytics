-- ===================================================================
-- objective:
-- 1. create one row per campaign per active month
-- 2. calculate the number of active campaign days within each month
-- 3. allocate campaign spend to each month based on active days
-- ===================================================================

-- calculate # of campaign days and daily spend

with daily_spend as (
    select
        campaign_id,
        artist_id,
        campaign_name,
        start_date,
        end_date,
        spend,
        datediff('day', start_date, end_date) + 1 as campaign_days,
        spend / (datediff('day', start_date, end_date) + 1) as daily_spend
    from {{ ref('stg_marketing_campaigns') }}
),
-- generate month offsets used to expand campaigns across active months
-- generate up to 24 month offsets; source campaigns span less than 24 months

month_offsets as (

    select
        seq4() as month_offset
    from table(generator(rowcount => 24))

), 
-- expand each campaign into one row per active calendar month
-- filter month offsets that fall outside the campaign date range

campaign_months as (

    select
        d.campaign_id,
        d.artist_id,
        d.start_date,
        d.end_date,
        d.daily_spend,
        m.month_offset,
        dateadd(
            'month',
            m.month_offset,
            date_trunc('month', d.start_date)
        ) as campaign_month

    from daily_spend as d
    cross join month_offsets as m

    where m.month_offset <= datediff('month', d.start_date, d.end_date)

),

-- determine the portion of each calendar month when the campaign was active

active_dates as (

    select
        campaign_id,
        artist_id,
        campaign_month,
        daily_spend,

        greatest(
            start_date,
            campaign_month
        ) as active_start,

        least(
            end_date,
            last_day(campaign_month)
        ) as active_end, 
        datediff('day', active_start, active_end) + 1 as active_days

    from campaign_months

)
-- calculate active days and allocate campaign spend to each month

select 
    campaign_id,
    artist_id,
    campaign_month,
    active_start,
    active_end,
    active_days,
    round(
        daily_spend *  active_days,2) as allocated_spend
from active_dates  
