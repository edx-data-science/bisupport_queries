-- This work is for the ticket: https://openedx.atlassian.net/browse/BISUPPORT-2280
-- Alright, I'm just going to pull clean enrollments with content
-- availability dates in calendar year 2020 and look at:
-- first engagement (14-days), second engagement (14-days), verification (28-days), certification (90-days)

create or replace table user_data.thelbig.bisupport_2280_base as
with clean_enrollments as (
    select
        fefb.user_id,
        du.is_active,
        case
            when fefb.user_modality_category = 'Mobile App Only'
            then 'App Only'
            when fefb.user_modality_category in ('Desktop Web Only', 'Mobile Web Only', 'Desktop Web/Mobile Web')
            then 'Web Only'
            else 'Mixed Modality: App & Web'
        end as modality_category,
        fefb.courserun_key,
        fefb.content_availability_date,
        fefb.is_engaged1_14d,
        fefb.is_engaged2_14d,
        fefb.is_verified_28d,
        fefb.is_certified_90d
    from
        prod.engagement.fact_enrollment_funnel_b2c as fefb
        join prod.core.dim_users as du
            on fefb.user_id = du.user_id  
    where
        fefb.content_availability_date >= to_date('2020-01-01')
        and fefb.content_availability_date < to_date('2021-01-01')
)
select
    'Enroll' funnel_step,
    modality_category,
    count(*) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments
group by
    1, 2

union all

select
    'Engage: 1+' funnel_step,
    modality_category,
    sum(iff(is_engaged1_14d, 1, 0)) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active and is_engaged1_14d, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active and is_engaged1_14d, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments
group by
    1, 2
    
union all

select
    'Engage: 2+' funnel_step,
    modality_category,
    sum(iff(is_engaged2_14d, 1, 0)) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active and is_engaged2_14d, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active and is_engaged2_14d, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments
group by
    1, 2
    
union all

select
    'Purchase' funnel_step,
    modality_category,
    sum(iff(is_verified_28d, 1, 0)) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active and is_verified_28d, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active and is_verified_28d, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments
group by
    1, 2

union all

select
    'Certify' funnel_step,
    modality_category,
    sum(iff(is_certified_90d, 1, 0)) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active and is_certified_90d, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active and is_certified_90d, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments
group by
    1, 2    

select * from user_data.thelbig.bisupport_2280_base