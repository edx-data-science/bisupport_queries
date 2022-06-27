with parnter_by_month as (
    select date_trunc('month', s.enrollment_date) as month
         , cr.partner_key
         , count(distinct ee.lms_enrollment_id)   as enrollment_count
         , count(distinct cr.course_key)          as course_count
    from prod.enterprise._enterprise_dim_subscription_enrollment  s
         left join prod.enterprise.ent_base_enterprise_enrollment ee
                   on ee.enterprise_enrollment_id = s.enterprise_enrollment_id
         left join prod.core.dim_courseruns                       cr
                   on cr.courserun_key = ee.lms_courserun_key
    where s.subscription_plan_vertical in ('CORP', 'OCP')
    group by 1
           , 2
    order by 1
           , 2
)
select month
     , sum(enrollment_count)       as total_enrollmenta
     , count(distinct partner_key) as total_partners
     , avg(enrollment_count)       as average_enrollments_per_partner
     , median(enrollment_count)    as median_enrollments_per_partner
     , max(enrollment_count)       as max_enrollments_per_partner
     , avg(course_count)           as average_courses_per_partner
     , median(course_count)        as median_courses_per_partner
     , max(course_count)           as max_courses_per_partner
from parnter_by_month
group by 1
order by 1;

