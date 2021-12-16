-- Create a graph that shows the % of learners taking their 2nd course or higher, and the size of the catalog.
-- Data should be grouped per partner
with enrolls as (
select enrollment_id,user_id,date(first_enrollment_date) as first_enrollment_date,cr.course_key
    ,case when row_number() over (partition by user_id order by first_enrollment_date)>=2
        then 1 else 0 end as secondenrollmentflag
    ,case when row_number() over (partition by user_id,partner_key order by first_enrollment_date)>=2
        then 1 else 0 end as secondenrollmentatpartnerflag
    , partner_key
from prod.core.dim_enrollments de
    inner join prod.core.dim_courseruns cr on de.courserun_key = cr.courserun_key
-- where user_id = 7542048
order by first_enrollment_date),

enrollsummary as (
select sum(secondenrollmentflag) as users_multiple_enroll
     ,sum(secondenrollmentatpartnerflag) as users_multiple_enroll_at_partner
     ,count(enrollment_id) as enrolls
    ,partner_key
from enrolls
group by partner_key),

course_summary as (
select partner
    ,count(distinct course_key) as totalcourses
--    ,count(distinct case when in_revenue_window = 1 and event_date = '2021-09-03' then course_key else null end)
from prod.business_intelligence.bi_all_course_window_status
group by partner)

select *,users_multiple_enroll_at_partner/enrolls as Continuing_Education_learners_at_partner
from course_summary cs
    left join enrollsummary es on cs.partner = es.partner_key