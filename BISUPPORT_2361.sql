--A: Identify set of program courseruns considered "data science" by getting list of all
--course runs where primary subject is data-analysis-statistics
with data_courseruns      as (
    select distinct p_cr.courserun_id
    from prod.core.program_courserun        p_cr
         left join prod.core.dim_courseruns cr
                   on cr.courserun_id = p_cr.courserun_id
    where cr.primary_subject_name = 'data-analysis-statistics'
)
   --get a count of enrollments paid for via "course-entitlement" bookings in FY2021
   , bundle_verifications as (
    select count(distinct enrollment_id)
    from prod.core.fact_booking             fb
         left join prod.core.dim_date       d
                   on d.date_column = fb.booking_date
         left join prod.core.dim_courseruns cr
                   on cr.courserun_key = fb.courserun_key
         join      data_courseruns          dp
                   on dp.courserun_id = cr.courserun_id
    where fb.order_product_class = 'course-entitlement'
      and d.fiscal_year = 2021
)
--select * from bundle_verifications;  33,593
--get a count of total verifications in a data science program course: 166,409
--get a count of total verifications in ANY data science course: 179, 653
select e.is_enterprise_enrollment
     , e.is_subscription
     , ee.subscription_netsuite_product_id
     --  cr.partner_key
     , count(distinct e.enrollment_id)
from prod.core.dim_enrollments                     e
     left join prod.core.dim_date                  d
               on d.date_column = e.first_verified_date::date
     left join prod.core.dim_courseruns            cr
               on cr.courserun_id = e.courserun_id
     left join prod.core.imd_enterprise_enrollment ee
               on ee.enrollment_id = e.enrollment_id
                   --comment out below number to get count for ALL data courses, not just those in a program
     join      data_courseruns                     dp
               on dp.courserun_id = cr.courserun_id
where cr.primary_subject_name = 'data-analysis-statistics'
  and d.fiscal_year = 2021
  and not e.is_privileged_or_internal_user
  and first_verified_date is not null
group by 1
       , 2
       , 3

--PART 3:
with data_courseruns as (
    select distinct p_cr.courserun_id
    from prod.core.program_courserun        p_cr
         left join prod.core.dim_courseruns cr
                   on cr.courserun_id = p_cr.courserun_id
    where cr.primary_subject_name = 'data-analysis-statistics'
)
select p_cr.sort_value
     ,
     --  p_cr.program_title,
     --  p_cr.partner_key,
    count(distinct enrollment_id)
from prod.core.dim_enrollments                                                          e
     left join prod.core.dim_date                                                       d
               on d.date_column = e.first_verified_date::date
     left join prod.core.dim_courseruns                                                 cr
               on cr.courserun_id = e.courserun_id
     left join (select * from prod.core.program_courserun where sort_revenue_order = 1) p_cr
               on p_cr.courserun_id = cr.courserun_id
     join      data_courseruns                                                          dp
               on dp.courserun_id = cr.courserun_id
where cr.primary_subject_name = 'data-analysis-statistics'
  and d.fiscal_year = 2021
  and not e.is_privileged_or_internal_user
  and first_verified_date is not null
  -- and p_cr.partner_key <> 'IBM'
group by 1--,2,3
order by 1 --desc

