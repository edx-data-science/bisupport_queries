--first email list: US learners enrolled in Public Library Management Prof Cert Program

select distinct
       (de.user_id) as user_id
     , first_name
     , last_name
     , email
     , gender
     , education_level
     , country_code
     , age_group
     , language_preference
     , de.is_active as is_active
     , is_verified_track
     , pct_complete_of_program
     , dp.program_title
     , dp.program_type
     , partner_key
from dim_enrollments                                       as de
     join      dim_users                                   as du
               on du.user_id = de.user_id
     join      dim_courseruns                              as dc
               on de.courserun_key = dc.courserun_key
     join      dim_program                                 as dp
               on program_id_at_first_enrollment = program_id
     left join business_intelligence.bi_program_completion as bi
               on bi.user_id = de.user_id
     join      core_pii.corepii_user_profile               as cp
               on de.user_id = cp.user_id
where partner_key like '%Michigan%'
  and dp.program_type = 'Professional Certificate'
  and dp.program_title = 'Public Library Management'
  and pct_complete_of_program is not null
  and country_code = 'US'
order by pct_complete_of_program desc

--second email list: US learners enrolled in courses associated with Public Library Management Prof Cert Program but not enrolled in program

select distinct
       (de.user_id) as user_id
     , first_name
     , last_name
     , email
     , gender
     , education_level
     , country_code
     , age_group
     , language_preference
     , de.is_active as is_active
     , is_verified_track
     , pct_complete_of_program
     , dp.program_title
     , dp.program_type
     , partner_key
from dim_enrollments                                       as de
     join      dim_users                                   as du
               on du.user_id = de.user_id
     join      dim_courseruns                              as dc
               on de.courserun_key = dc.courserun_key
     join      dim_program                                 as dp
               on program_id_at_first_enrollment = program_id
     left join business_intelligence.bi_program_completion as bi
               on bi.user_id = de.user_id
     join      core_pii.corepii_user_profile               as cp
               on de.user_id = cp.user_id
where partner_key like '%Michigan%'
  and dp.program_type = 'Professional Certificate'
  and dp.program_title = 'Public Library Management'
  and pct_complete_of_program is null
  and de.is_active = 'TRUE'
  and de.is_verified_track = 'TRUE'
  and country_code = 'US'

