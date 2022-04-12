--Info on bundle purchases for specific Purdue programs requested
select distinct
       user_id
     , program_title
     , booking_date
     , booking_date > '2021-10-1' as is_in_ref_window
     , is_redeemed
     , transaction_type
from fact_booking                               as fb
     join core_courserun_all_program_membership as pm
          on fb.program_id = pm.program_id
     join dim_courses                           as dc
          on pm.course_id = dc.course_id
              and fb.course_key = dc.course_key
where pm.partner_key = 'PurdueX'
  and program_title in ('Nanoscience and Technology', 'Quantum Technology: Computing', 'Quantum Technology: Detectors and Networking')
  and is_program_from_order = 'TRUE' --change to false and add course title for non-bundle programs
order by program_title
       , user_id
       , transaction_type desc


--this part is aimed at addressing course/program persistence for those who have enrolled
select distinct
       bc.user_id
     , bp.program_title
     , courserun_title              as course
     , passed_timestamp is not null as has_passed_course
     , cnt_enrolled
     , cnt_verified
     , pct_complete_of_program
from bi_program_completion                           as bp
     join core.core_courserun_all_program_membership as pm
          on bp.program_id = pm.program_id
     join core.dim_courseruns                        as dc
          on pm.courserun_id = dc.courserun_id
     join bi_course_completion                       as bc
          on bp.user_id = bc.user_id
              and bc.courserun_id = pm.courserun_id
where pm.partner_key = 'PurdueX'
  and bp.program_title in ('Nanoscience and Technology', 'Quantum Technology: Computing', 'Quantum Technology: Detectors and Networking')
order by program_title
       , bc.user_id

