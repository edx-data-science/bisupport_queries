select
     program.partner_key
    , program.program_title
     , YEAR(min(first_verified_date)) year_program_launched
     , count(distinct enrollment_id)                                                as total_enrollments
     , count(distinct case when is_verified_track then enrollment_id else null end) as total_verified_enrollments
     , count(distinct user_id)                                                      as total_users
     , count(distinct case when is_verified_track then user_id else null end)       as total_verified_users
from prod.core.dim_enrollments             enroll
     left join prod.core.program_courserun program
               on program.courserun_id = enroll.courserun_id
where not enroll.is_privileged_or_internal_user
  and first_enrollment_date between '2020-06-30' and '2021-06-30'
  and program.program_id in (
    select distinct program_id
    from prod.core.program_courserun --where partner_key='IBM'
    where program_title in
          ('Analytics: Essential Tools and Methods', 'AWS Developer Series', 'Information Systems', 'Supply Chain Management', 'Cybersecurity',
           'Software Development', 'Computer Science for Web Programming', 'Full Stack Cloud Developer', 'Data Engineering Fundamentals',
           'Data Engineering Fundamentals', 'Data Analyst', 'Cloud Native Foundations')
)
group by program.program_title, program.partner_key
order by total_verified_users desc

