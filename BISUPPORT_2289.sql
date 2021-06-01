select 
    year(first_enrollment_date) as enrolment_year, 
    count(enrollment_id) as enrolment_count
from 
    prod.core.dim_enrollments
where 
    courserun_key like '%DelftX+ST2x%'
    and current_mode='verified'
group by 
    enrolment_year
order by 
    enrolment_year desc
