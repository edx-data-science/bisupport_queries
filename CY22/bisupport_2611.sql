--Certifcates awared for completing any courses in program as percentage of total verified enrolls

with course_certificates as (
    select de.user_id       as enroll_id
         , pc.program_title as program
         , courserun_title  as course
         , sort_value       as program_course_order
         , is_certified
    from core.dim_enrollments                 as de
         left join bi_user_course_certificate as bcert
                   on de.user_id = bcert.user_id
         join      core.dim_courseruns        as dc
                   on de.courserun_key = dc.courserun_key
         join      core.program_courserun     as pc
                   on pc.courserun_id = de.courserun_id
    where pc.program_title in ('Design Thinking', 'Project Management', 'Cybersecurity', 'Leadership Essentials', 'Communication Skills',
                               'Data Analytics for Decision Making', 'Unreal Engine Foundations')
      and pc.partner_key like '%RIT%'
      and current_mode = 'verified'
      and first_enrollment_date >= '2017-03-24'
)

select program
     , course
     , program_course_order
     , sum(is_certified) / count(enroll_id) as pct_verified_learners_certified
     , count(enroll_id)                     as total_enrolls
from course_certificates
group by course
       , program
       , program_course_order
order by program
       , program_course_order


--Program Completion Cerficates awarded (full program)

select count(user_id) as program_certs_awarded
     , program_type
     , program_title
from tableau_user_awarded_credentials
where program_title in ('Design Thinking', 'Project Management', 'Cybersecurity', 'Leadership Essentials', 'Communication Skills',
                        'Data Analytics for Decision Making', 'Unreal Engine Foundations')
  and course_partner like '%RIT%'
  and credential_type = 'programcertificate'
group by program_title
       , credential_type
       , program_type
       , first_certificate_date

--course certificates earned towards program completion (some may or may not have completed full program)

select count(user_id) as course_certs_awarded
     , program_type
     , program_title
from tableau_user_awarded_credentials
where program_title in ('Design Thinking', 'Project Management', 'Cybersecurity', 'Leadership Essentials', 'Communication Skills',
                        'Data Analytics for Decision Making', 'Unreal Engine Foundations')
  and course_partner like '%RIT%'
  and credential_type = 'coursecertificate'
group by program_title
       , credential_type
       , program_type

--All goes back to 2017, 03/2017 for first individual course certificate awarded, 05/2017 for first full program certification awarded

