    
with enrolments as (
    select * 
    from "PROD"."CORE"."DIM_ENROLLMENTS" de
    join "PROD"."CORE"."DIM_COURSERUNS" dr 
    on de.courserun_id = dr.courserun_id
    left join prod.financial_reporting.finrep_intermediate_enrollment_masters iem --exclude masters enrollment records from the initial data set
    on iem.enrollment_id = de.enrollment_id
    where iem.enrollment_id is null
    and partner_key='GTx'
    and to_date (FIRST_ENROLLMENT_DATE) >= dateadd('year', -1, current_date) 
)
 
select distinct course_key, first_name, last_name, email
from enrolments er
join PROD.LMS_PII.AUTH_USER user
on er.user_id = user.id
where user.is_active
order by course_key
