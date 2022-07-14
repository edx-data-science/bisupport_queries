with program_completers as
    (
        select distinct
               user_id
             , cert.program_id
             , program_type
             , program_title
             , program_status
             , partner_key
             , first_program_certificate_date
        from business_intelligence.bi_program_certificate as cert
             join core_courserun_all_program_membership   as part
                  on part.program_id = cert.program_id
        where first_program_certificate_date is not null
    )

   , other_enrollment   as
    (
        select distinct
               user_id
               -- ,prog.program_id
             , program_type
             , program_title
--  ,pct_complete_of_program
--  ,program_completion
             , partner_key
             , min(first_enrollment_date) as enrollment_date
        from dim_enrollments                            as de
                 --  join business_intelligence.bi_program_completion as prog
--  on de.user_id = prog.user_id
             join core_courserun_all_program_membership as prog
                  on prog.courserun_key = de.courserun_key
        where sort_revenue_order = 1
        group by 1
               , 2
               , 3
               , 4
    )

   , list_of_users      as (
    select comp.user_id
         , comp.program_type              as completed_program_type
         , comp.program_title             as completed_program_title
         , comp.program_status
         , comp.partner_key               as first_partner_key
         , first_program_certificate_date as program_completed_date
         , other.program_type             as next_program_type
         , other.program_title            as next_program_title
         , other.partner_key              as next_partner_key
         , enrollment_date                as next_program_enrollment
--,pct_complete_of_program as next_program_progress
--,program_completion as next_program_complete
    from program_completers    as comp
         join other_enrollment as other
              on comp.user_id = other.user_id
    where next_program_enrollment > program_completed_date
      and comp.partner_key = other.partner_key
--and comp.user_id = 5757
--order by comp.partner_key, first_program_completed asc
    order by user_id
           , completed_program_title
           , next_program_enrollment
           , next_program_title
)

   , condensed_list     as (
    select user_id
         , first_partner_key             as partner
         , completed_program_type
         , completed_program_title       as completed_program
         , year(program_completed_date)  as year_completed
         , next_program_type
         , next_program_title            as next_program
         , year(next_program_enrollment) as year_next_enrolled
    from list_of_users
)

   , user_list          as (
    select distinct
           condensed_list.user_id
         , gender
         , education_level
         , country_label as country
         , age_group
    from condensed_list
         join dim_users
              on condensed_list.user_id = dim_users.user_id
)

   , user_credit_list   as (
    select lms_user_id
    from credentials.records_usercreditpathway as credit
         join credentials.core_user            as core_user
              on core_user.id = credit.user_id
)

select *
     , case when lms_user_id is not null then 'True' else 'False' end as shared_record_for_credit
from user_list
     left join user_credit_list
               on user_list.user_id = user_credit_list.lms_user_id


