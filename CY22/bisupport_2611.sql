--program certificates awarded

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
order by program_certs_awarded desc

--course certificates earned towards program completion (some may or may not have completed full program)
--tableau_user_awarded_credentials is accurate at the program level but not course, needs updating

select count(user_id)  as course_certs_awarded
     , program_type
     , program_title
     , courserun_title as course
from bi_user_course_certificate      as bc
     join core.program_courserun_all as pc
          on bc.courserun_id = pc.courserun_id
     join core.dim_courseruns        as dc
          on bc.courserun_id = dc.courserun_id
              and pc.courserun_id = dc.courserun_id
where program_title in ('Design Thinking', 'Project Management', 'Cybersecurity', 'Leadership Essentials', 'Communication Skills',
                        'Data Analytics for Decision Making', 'Unreal Engine Foundations')
  and pc.partner_key like '%RIT%'
  and is_certified = 1
group by program_title
       , program_type
       , course
order by program_title

--%verified learners who completed courses

with course_certificates as (
    select de.user_id       as enroll_id
         , pc.program_title as program
         , courserun_title  as course
         , sort_value       as program_course_order
         , is_certified
    from core.dim_enrollments                 as de
         left join bi_user_course_certificate as bcert
                   on de.user_id = bcert.user_id
                       and de.courserun_key = bcert.courserun_key
         join      core.dim_courseruns        as dc
                   on de.courserun_key = dc.courserun_key
         join      core.program_courserun     as pc
                   on pc.courserun_id = de.courserun_id
    where pc.program_title in ('Design Thinking', 'Project Management', 'Cybersecurity', 'Leadership Essentials', 'Communication Skills',
                               'Data Analytics for Decision Making', 'Unreal Engine Foundations')
      and pc.partner_key like '%RIT%'
      and current_mode = 'verified'
)


select program
     , course
     , program_course_order
     , sum(is_certified) / count(enroll_id) as pct_verified_learners_certified
     , count(enroll_id)                     as total_verified_enrolls
from course_certificates
group by course
       , program
       , program_course_order
order by program
       , program_course_order

--All goes back to 2017, 03/2017 for first individual course certificate awarded, 05/2017 for first full program certification awarded

