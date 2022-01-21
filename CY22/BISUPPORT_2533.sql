--first email list: active mm students within the last two years

with active_mm as (
  select distinct program_id as dim_program_id
  from dim_program
  where program_type = 'MicroMasters'
  and program_status = 'active'
  ),

  active_mm_stu as (
  select max(first_enrollment_date) as last_enrollment,
         dim_enrollments.user_id as learner_id
  from dim_enrollments
  join active_mm
  on program_id_at_first_enrollment = dim_program_id
      where is_active = 'TRUE'
  and first_enrollment_date > '2020-01-01'  --within the last two years rounded to jan 1--
  group by learner_id
  ),

  active_mm_stu_plus as (
  select distinct learner_id,
         country_label,
         last_enrollment
   from dim_users
   join active_mm_stu
   on user_id = learner_id
  )

select distinct email,
       first_name,
       last_name,
       learner_id,
       country_label,
       last_enrollment
from lms_pii.auth_user
join active_mm_stu_plus
on id = learner_id
where country_label is not null

--second email list: students who completed mm in the last two years

with complete_mm_stu as (
  select distinct bi_program_completion.user_id as learner_id,
         program_id as bi_program,
         max(first_enrollment_date) as last_enrollment
 from bi_program_completion
 join core.dim_enrollments
 on bi_program_completion.user_id = core.dim_enrollments.user_id
 where program_completion = 1
 and first_enrollment_date > '2020-01-01'  --within the last two years rounded to jan 1--
 group by learner_id, bi_program
 order by learner_id
  ),

complete_mm_stu_prog as (
   select learner_id,
          last_enrollment
   from complete_mm_stu
   join core.dim_program
   where program_type = 'MicroMasters'
  and program_status = 'active'
 ),

complete_mm_stu_plus as (
   select learner_id,
         country_label,
         last_enrollment
   from core.dim_users
   join complete_mm_stu_prog
   on dim_users.user_id = learner_id
 )

select distinct email,
         first_name,
         last_name,
         learner_id,
         country_label,
         last_enrollment
from lms_pii.auth_user
join complete_mm_stu_plus
on id = learner_id
where country_label is not null

--third email list: students who unenrolled or asked for refund from mm in the last two years

with active_mm as (
  select distinct program_id as dim_program_id,
         program_title as program_name
  from dim_program
  where program_type = 'MicroMasters'
  and program_status = 'active'
  ),

unenrolled_mm_stu as (
   select distinct dim_enrollments.user_id as learner_id,
          courserun_key as dim_key,
          enrollment_id as dim_enroll_id,
          first_enrollment_date as enrollment,
          program_name
   from dim_enrollments
   join active_mm
   on program_id_at_first_enrollment = dim_program_id
   where is_active = 'FALSE'
   and first_enrollment_date > '2020-01-01'  --within the last two years rounded to jan 1--
   ),

refund_added_stu as (
  select distinct fact_booking.user_id,
         learner_id,
         enrollment,
         program_name
  from unenrolled_mm_stu
  full join fact_booking
  on learner_id = fact_booking.user_id
  and dim_key = courserun_key
  and dim_enroll_id = enrollment_id
  where transaction_type = 'refund'
),

refund_added_stu_plus as (
  select distinct learner_id,
         country_label,
         enrollment,
         program_name
   from dim_users
   join refund_added_stu
   on dim_users.user_id = learner_id
  )

select distinct email,
         first_name,
         last_name,
         learner_id,
         country_label,
         max(enrollment) as last_enrollment,
         program_name
from lms_pii.auth_user
join refund_added_stu_plus
on id = learner_id
where country_label is not null
group by learner_id, country_label, program_name, email, first_name, last_name
order by email

 