with courserun_enrollments as
   (
        select enroll.enrollment_id
             , cr.courserun_key
             , enroll.user_id
             , cr.course_key
             , cr.start_datetime as courserun_start_datetime
             , cr.end_datetime   as courserun_end_datetime
             , cr.pacing_type
             , enroll.first_enrollment_date
             , cc.passed_timestamp
             , datediff(day, enroll.first_enrollment_date, cc.passed_timestamp) as completion_time
        from prod.core.dim_courseruns                        as cr
        join prod.core.dim_enrollments                       as enroll
             on cr.courserun_id = enroll.courserun_id
        join prod.business_intelligence.bi_course_completion as cc
             on cc.user_id = enroll.user_id
                and cc.courserun_id = enroll.courserun_id
        where pacing_type = 'self_paced'
          and cc.passed_timestamp is not null
          and cr.end_datetime <= current_timestamp
   )

select courserun_key
     , course_key
     , courserun_start_datetime
     , courserun_end_datetime
     , pacing_type
     , ceil(sum(completion_time)/count(completion_time)) as average_completion_time_in_days
from courserun_enrollments
group by courserun_key
       , course_key
       , courserun_start_datetime
       , courserun_end_datetime
       , pacing_type
order by courserun_start_datetime desc