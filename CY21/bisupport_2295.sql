-- this work is for this BISUPPORT ticket: https://openedx.atlassian.net/browse/BISUPPORT-2295

with enrollment_engagement as (
    select
        ee.enrollment_id,
        ee.user_id,
        ee.courserun_key,
        ee.courserun_id,
        ee.engagement_anchor_date,
        dc.primary_subject_name,
        coalesce(pc.program_type, 'Non-program') as program_type,
        pc.program_id,
        coalesce(dc.partner_key, 'missing') as partner_key,
        ee.engagement_anchor_date < dateadd('day', -16, current_timestamp()) has_completed_metric_window, -- we wait 16 days for a user's engagement window to complete (14 days for metric + 2 days for loading)
        ee.eng_day_cnt_14d >= 2 is_engaged_14d -- enrollment is engaged if they do at least 2 days of engagement actions in first 14 days
    from
        prod.core.fact_enrollment_engagement as ee
        join prod.core.dim_enrollments as de
            on ee.user_id = de.user_id
            and ee.courserun_key = de.courserun_key
        join prod.core.dim_courseruns as dc
            on ee.courserun_key = dc.courserun_key
        left join prod.core.program_courserun as pc
            on dc.courserun_id = pc.courserun_id
            and pc.sort_revenue_order = 1
    where
        ee.engagement_anchor_date >= to_date('2020-05-01')
        and ee.engagement_anchor_date < to_date('2021-05-01')
        and not de.is_privileged_or_internal_user -- get rid of privileged or internal users
        and not de.is_enterprise_enrollment -- eliminate b2b enrollments
        and dc.reporting_type not in ('demo', 'test') -- get rid of demo/test courseruns
        and not dc.is_whitelabel -- no whitelabel ccourseruns
        and lower(dc.partner_key) != 'edx' -- no internal edx courses
        and ee.late_enrollment_yn = 0 -- get rid of people who enroll late
)
select
    sum(iff(partner_key = 'ArmEducationX', 1, 0)) aex_enrollments,
    sum(iff(partner_key = 'ArmEducationX' and is_engaged_14d, 1, 0)) aex_engaged_enrollments,
    round(sum(iff(partner_key = 'ArmEducationX' and is_engaged_14d, 1, 0)) / sum(iff(partner_key = 'ArmEducationX', 1, 0)), 4) aex_engagement_rate,
    sum(iff(program_id = 623, 1, 0)) embedded_systems_enrollments,
    sum(iff(program_id = 623 and is_engaged_14d, 1, 0)) embedded_systems_engaged_enrollments,
    round(sum(iff(program_id = 623 and is_engaged_14d, 1, 0)) / sum(iff(program_id = 623, 1, 0)), 4) embedded_systems_engagement_rate,
    sum(iff(program_id = 624, 1, 0)) physical_computing_enrollments,
    sum(iff(program_id = 624 and is_engaged_14d, 1, 0)) physical_computing_engaged_enrollments,
    round(sum(iff(program_id = 624 and is_engaged_14d, 1, 0)) / sum(iff(program_id = 624, 1, 0)), 4) physical_computing_engagement_rate,
    round(sum(iff(primary_subject_name = 'computer-science' and is_engaged_14d, 1, 0)) / sum(iff(primary_subject_name = 'computer-science', 1, 0)), 4) cs_engagement_rate,
    round(sum(iff(primary_subject_name = 'education-teacher-training' and is_engaged_14d, 1, 0)) / sum(iff(primary_subject_name = 'education-teacher-training', 1, 0)), 4) ett_engagement_rate,
    round(sum(iff(program_type = 'Professional Certificate' and is_engaged_14d, 1, 0)) / sum(iff(program_type = 'Professional Certificate', 1, 0)), 4) prof_cert_engagement_rate,
    round(sum(iff(is_engaged_14d, 1, 0)) / count(*), 4) edx_engagement_rate
from
    enrollment_engagement