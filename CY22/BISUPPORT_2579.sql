//* code taken from bi_program_completion and modified to fit enterprise use case
with d_user_course           as (select * from /*{{cref('*/dim_enrollments/*')}}*/ )
   , course_master           as (select * from /*{{cref('*/dim_courseruns/*')}}*/ )
   , d_program_course        as (select * from /*{{cref('*/program_courserun_all/*')}}*/ )
   , course_completion       as (select * from /*{{cref('*/business_intelligence.bi_course_completion/*')}}*/ )
   , distinct_program_course as
    (
        select distinct program_type, program_title, program_id, course_id
        from d_program_course pc
    )
   , courses_in_program      as
    (
        select program_type, program_title, program_id, count(distinct course_id) as cnt_courses_in_program
        from d_program_course
        group by program_type
               , program_title
               , program_id
    )
   , program_completion_stg  as
    (
        select uc.user_id
             , ee.enterprise_customer_uuid
             , cm.course_id
             , cm.partner_key
             , pc.program_type
             , pc.program_title
             , pc.program_id
             , min(uc.first_enrollment_date)                                              as first_enrollment_date
             , max(case when uc.current_mode not in ('audit', 'honor') then 1 else 0 end) as is_verified
             , case when max(passed_timestamp) is not null then 1 else 0 end              as has_passed
             , max(passed_timestamp)                                                      as last_pass_time
             -- convert to 1/0 for adding
             , iff(max(ee.consent_granted), 1, 0)                                         as is_consent_granted
        from d_user_course                                       uc
             join      course_master                             cm
                       on uc.courserun_id = cm.courserun_id
             join      distinct_program_course                   pc
                       on cm.course_id = pc.course_id
             left join course_completion                         cc
                       on uc.user_id = cc.user_id and uc.courserun_key = cc.courserun_key
             left join enterprise.ent_base_enterprise_enrollment ee
                       on uc.enrollment_id = ee.lms_enrollment_id
        group by uc.user_id
               , ee.enterprise_customer_uuid
               , cm.course_id
               , pc.program_type
               , pc.program_title
               , pc.program_id
               , cm.partner_key
        order by uc.user_id
               , cm.course_id
    )
   , program_completion      as (
    select pcs.user_id
         , pcs.enterprise_customer_uuid
         , pcs.partner_key
         , pcs.program_type
         , pcs.program_title
         , pcs.program_id
         , cp.cnt_courses_in_program
         , sum(is_verified)                                                        as cnt_verified
         , count(distinct course_id)                                               as cnt_enrolled
         , sum(has_passed)                                                         as cnt_passed
         , sum(has_passed) / cp.cnt_courses_in_program                             as pct_complete_of_program
         , case when sum(has_passed) = cp.cnt_courses_in_program then 1 else 0 end as program_completion
         , sum(is_consent_granted)                                                 as cnt_consent_granted
         , max(last_pass_time)                                                     as program_completion_date
    from program_completion_stg  pcs
         join courses_in_program cp
              on pcs.program_id = cp.program_id
    group by pcs.user_id
           , pcs.partner_key
           , pcs.enterprise_customer_uuid
           , pcs.program_type
           , pcs.program_title
           , pcs.program_id
           , cp.cnt_courses_in_program
    having sum(is_verified) > 1
)
select pc.*
     , dp.program_status
     , user_username
     , user_email
     , enterprise_user_id
from program_completion                                 pc
     left join prod.enterprise.ent_base_enterprise_user u
               on u.lms_user_id = pc.user_id
     left join prod.core.dim_program                    dp
               on dp.program_id = pc.program_id
where pc.enterprise_customer_uuid = '12aacfee8ffa4cb3bed1059565a57f06'
  and pc.program_completion = 1
  and cnt_consent_granted = cnt_passed
  and year(program_completion_date) = 2021
and program_status='active'
order by user_id;