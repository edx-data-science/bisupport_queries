-- This work is for the JIRA ticket: https://openedx.atlassian.net/browse/BISUPPORT-2244
-- Here, we want to look at 1 month, 3 month, 6 month, and 1 year re-enrollment/verification
-- rates for users who have completed a program. And we want to do it across product lines.

-- The final mash up of different time windows is gross and super redundant code, but I'm doing
-- it so that google sheets doesn't yell at me when I try to graph it (it needs really wide data)

with program_completers_long as (
    select
        du.user_id,
        first_value(dp.program_type) over (partition by du.user_id order by pc.first_program_certificate_date) as min_program_type,
        first_value(pc.first_program_certificate_date) over (partition by du.user_id order by pc.first_program_certificate_date) as min_program_complete_date
    from
        prod.business_intelligence.bi_program_certificate as pc
        join prod.core.dim_program as dp
            on pc.program_id = dp.program_id
        join prod.lms_pii.auth_user as au
            on pc.user_key = au.username
        join prod.core.dim_users as du
            on au.id = du.user_id
    where
        not du.is_staff
        and not du.is_superuser
        and pc.first_program_certificate_date >= to_date('2018-01-01')
        and pc.first_program_certificate_date < to_date('2021-01-01')
        and not dp.program_type in ('Professional Program', 'MicroBachelors')
),
program_completers_condensed as (
    select
        user_id,
        min(min_program_type) as program_type,
        min(min_program_complete_date) as program_complete_date
    from
        program_completers_long
    group by
        1
),
program_completers_w_enrolls as (
    select
        pcc.user_id,
        pcc.program_type,
        pcc.program_complete_date,
        min(dim_enrollments.first_enrollment_date) as min_enroll_date_post_program,
        min(dim_enrollments.first_verified_date) as min_verify_date_post_program
    from
        program_completers_condensed as pcc
        left join prod.core.dim_enrollments
            on pcc.user_id = dim_enrollments.user_id
            and dim_enrollments.first_enrollment_date >= pcc.program_complete_date
            and dim_enrollments.first_enrollment_date < dateadd('year', 1, pcc.program_complete_date)
    group by
        pcc.user_id,
        pcc.program_type,
        pcc.program_complete_date
)
select
    '1 Month' as time_since_program_complete,
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate', 1, 0)) pc_base_count,
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('day', 30, program_complete_date), 1, 0)) pc_enroller_count,
    round(pc_enroller_count / pc_base_count, 3) pc_enroller_prop,
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('day', 30, program_complete_date), 1, 0)) pc_verifier_count,
    round(pc_verifier_count / pc_base_count, 3) pc_verifier_prop,
    
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries', 1, 0)) xs_base_count,
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('day', 30, program_complete_date), 1, 0)) xs_enroller_count,
    round(xs_enroller_count / xs_base_count, 3) xs_enroller_prop,
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('day', 30, program_complete_date), 1, 0)) xs_verifier_count,
    round(xs_verifier_count / xs_base_count, 3) xs_verifier_prop,
    
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters', 1, 0)) mm_base_count,
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('day', 30, program_complete_date), 1, 0)) mm_enroller_count,
    round(mm_enroller_count / mm_base_count, 3) mm_enroller_prop,
    sum(iff(dateadd('day', 30, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('day', 30, program_complete_date), 1, 0)) mm_verifier_count,
    round(mm_verifier_count / mm_base_count, 3) mm_verifier_prop
    
from
    program_completers_w_enrolls

union all

select
    '3 Months' as time_since_program_complete,
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate', 1, 0)) pc_base_count,
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('day', 90, program_complete_date), 1, 0)) pc_enroller_count,
    round(pc_enroller_count / pc_base_count, 3) pc_enroller_prop,
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('day', 90, program_complete_date), 1, 0)) pc_verifier_count,
    round(pc_verifier_count / pc_base_count, 3) pc_verifier_prop,
    
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries', 1, 0)) xs_base_count,
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('day', 90, program_complete_date), 1, 0)) xs_enroller_count,
    round(xs_enroller_count / xs_base_count, 3) xs_enroller_prop,
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('day', 90, program_complete_date), 1, 0)) xs_verifier_count,
    round(xs_verifier_count / xs_base_count, 3) xs_verifier_prop,
    
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters', 1, 0)) mm_base_count,
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('day', 90, program_complete_date), 1, 0)) mm_enroller_count,
    round(mm_enroller_count / mm_base_count, 3) mm_enroller_prop,
    sum(iff(dateadd('day', 90, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('day', 90, program_complete_date), 1, 0)) mm_verifier_count,
    round(mm_verifier_count / mm_base_count, 3) mm_verifier_prop
    
from
    program_completers_w_enrolls

union all

select
    '6 Months' as time_since_program_complete,
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate', 1, 0)) pc_base_count,
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('month', 6, program_complete_date), 1, 0)) pc_enroller_count,
    round(pc_enroller_count / pc_base_count, 3) pc_enroller_prop,
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('month', 6, program_complete_date), 1, 0)) pc_verifier_count,
    round(pc_verifier_count / pc_base_count, 3) pc_verifier_prop,
    
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries', 1, 0)) xs_base_count,
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('month', 6, program_complete_date), 1, 0)) xs_enroller_count,
    round(xs_enroller_count / xs_base_count, 3) xs_enroller_prop,
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('month', 6, program_complete_date), 1, 0)) xs_verifier_count,
    round(xs_verifier_count / xs_base_count, 3) xs_verifier_prop,
    
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters', 1, 0)) mm_base_count,
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('month', 6, program_complete_date), 1, 0)) mm_enroller_count,
    round(mm_enroller_count / mm_base_count, 3) mm_enroller_prop,
    sum(iff(dateadd('month', 6, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('month', 6, program_complete_date), 1, 0)) mm_verifier_count,
    round(mm_verifier_count / mm_base_count, 3) mm_verifier_prop
from
    program_completers_w_enrolls

union all

select
    '12 Months' as time_since_program_complete,
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate', 1, 0)) pc_base_count,
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('month', 12, program_complete_date), 1, 0)) pc_enroller_count,
    round(pc_enroller_count / pc_base_count, 3) pc_enroller_prop,
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'Professional Certificate' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('month', 12, program_complete_date), 1, 0)) pc_verifier_count,
    round(pc_verifier_count / pc_base_count, 3) pc_verifier_prop,
    
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries', 1, 0)) xs_base_count,
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('month', 12, program_complete_date), 1, 0)) xs_enroller_count,
    round(xs_enroller_count / xs_base_count, 3) xs_enroller_prop,
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'XSeries' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('month', 12, program_complete_date), 1, 0)) xs_verifier_count,
    round(xs_verifier_count / xs_base_count, 3) xs_verifier_prop,
    
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters', 1, 0)) mm_base_count,
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters' and coalesce(min_enroll_date_post_program, to_date('2025-01-01')) <= dateadd('month', 12, program_complete_date), 1, 0)) mm_enroller_count,
    round(mm_enroller_count / mm_base_count, 3) mm_enroller_prop,
    sum(iff(dateadd('month', 12, coalesce(program_complete_date, current_date())) < current_date() and program_type = 'MicroMasters' and coalesce(min_verify_date_post_program, to_date('2025-01-01')) <= dateadd('month', 12, program_complete_date), 1, 0)) mm_verifier_count,
    round(mm_verifier_count / mm_base_count, 3) mm_verifier_prop
from
    program_completers_w_enrolls
	