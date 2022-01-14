--first email list: active mm students within the last two years

with active_mm as (
  select program_id as dim_program_id
  from dim_program
  where program_type = 'MicroMasters'
  and program_status = 'active'
  ),

active_mm_stu as (
  select user_id
  from dim_enrollments
  join active_mm
  on program_id_at_first_enrollment = dim_program_id
  where is_active = 'TRUE'
  and first_enrollment_date > '2020-01-01'  --within the last two years rounded to jan 1--
   )


select distinct(email)
from lms_pii.auth_user
join active_mm_stu
on user_id = id

--second email list: students who completed mm in the last two years

with active_mm as (
  select program_id as dim_program_id
  from dim_program
  where program_type = 'MicroMasters'
  and program_status = 'active'
  ),

completed_mm as (
  select user_id as bi_user_id
  from business_intelligence.bi_program_completion
  join active_mm
  on dim_program_id = business_intelligence.bi_program_completion.program_id
  ),

completed_mm_stu as (
  select user_id
  from completed_mm
  join dim_enrollments
  on bi_user_id = user_id
  where first_enrollment_date > '2020-01-01'  --within the last two years rounded to jan 1--
  )

select distinct(email)
from lms_pii.auth_user
join completed_mm_stu
on user_id = id

--third email list: students who unenrolled or asked for refund from mm in the last two years

with active_mm as (
  select distinct(program_id) as dim_program_id
  from dim_program
  where program_type = 'MicroMasters'
  and program_status = 'active'
  ),

unenrolled_mm_stu as (
   select distinct(user_id) as dim_id
   from dim_enrollments
   join active_mm
   on program_id_at_first_enrollment = dim_program_id
   where is_active = 'FALSE'
   and first_enrollment_date > '2020-01-01'  --within the last two years rounded to jan 1--
   ),

refund_added_stu as (
  select distinct(user_id),
         dim_id
  from unenrolled_mm_stu
  full join fact_booking
  on dim_id = user_id
  where transaction_type = 'refund')

select distinct (email)
from lms_pii.auth_user
join refund_added_stu
on id = user_id
or id = dim_id