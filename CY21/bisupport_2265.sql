-- This work is for the ticket: https://openedx.atlassian.net/browse/BISUPPORT-2265
-- Alright, I'm just going to pull clean enrollments with content
-- availability dates in calendar year 2020 and look at:
-- first engagement (14-days), second engagement (14-days), verification (28-days), certification (90-days)

create or replace table user_data.thelbig.bisupport_2265_base as
with verified_certificate as (
    select
        cert.user_id,
        cert.course_id courserun_key,
        to_date(min(cert.created_date)) first_verified_certificate_date
    from 
        prod.lms.certificates_generatedcertificate cert
    where 
        cert.status = 'downloadable'
        and cert.mode = 'verified'
    group by 
        cert.user_id,
        cert.course_id
), 
clean_enrollments as (
    select
        ee.user_id,
        du.is_active,
        ee.courserun_key,
        ee.engagement_anchor_date as content_anchor_date,
        ee.eng_day_cnt_14d >= 1 as is_engaged1_14d,
        ee.eng_day_cnt_14d >= 2 as is_engaged2_14d,
        coalesce(de.first_verified_date, dateadd('day', 29, ee.engagement_anchor_date)) <= dateadd('day', 28, ee.engagement_anchor_date) as is_verified_28d,
        coalesce(first_verified_certificate_date, dateadd('day', 91, ee.engagement_anchor_date)) <= dateadd('day', 90, ee.engagement_anchor_date) as is_certified_90d
    from
        prod.core.fact_enrollment_engagement as ee
        join prod.core.dim_enrollments as de
            on ee.user_id = de.user_id
            and ee.courserun_key = de.courserun_key
        join prod.core.dim_courseruns as dc
            on ee.courserun_key = dc.courserun_key
        join prod.core.dim_users as du
            on ee.user_id = du.user_id
        left outer join verified_certificate as vc
            on ee.user_id = vc.user_id
            and ee.courserun_key = vc.courserun_key
    where
        not de.is_privileged_or_internal_user -- get rid of privileged or internal users
        and not de.is_enterprise_enrollment -- eliminate b2b enrollments
        and dc.reporting_type not in ('demo', 'test') -- get rid of demo/test courseruns
        and not dc.is_whitelabel -- no whitelabel courseruns
        and not dc.partner_key = 'edX' -- no internal edx courses
        and ee.engagement_anchor_date >= to_date('2020-01-01')
        and ee.engagement_anchor_date < to_date('2021-01-01')
        and ee.late_enrollment_yn = 0 -- this is a little subjective, but I think it's the right thing to do; gets rid of archived course wackiness
        and courserun_type_slug in ('verified-audit', 'credit-verified-audit', 'masters-verified-audit')
)
select
    'Enroll' funnel_step,
    count(*) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments

union all

select
    'Engage: 1+' funnel_step,
    sum(iff(is_engaged1_14d, 1, 0)) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active and is_engaged1_14d, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active and is_engaged1_14d, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments

union all

select
    'Engage: 2+' funnel_step,
    sum(iff(is_engaged2_14d, 1, 0)) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active and is_engaged2_14d, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active and is_engaged2_14d, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments

union all

select
    'Purchase' funnel_step,
    sum(iff(is_verified_28d, 1, 0)) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active and is_verified_28d, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active and is_verified_28d, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments
    
union all

select
    'Certify' funnel_step,
    sum(iff(is_certified_90d, 1, 0)) total_count,
    round(total_count / count(*), 4) prop_total,
    sum(iff(is_active and is_certified_90d, 1, 0)) active_count,
    round(active_count / sum(iff(is_active, 1, 0)), 4) prop_active,
    sum(iff(not is_active and is_certified_90d, 1, 0)) inactive_count,
    round(inactive_count / sum(iff(not is_active, 1, 0)), 4) prop_inactive
from
    clean_enrollments
