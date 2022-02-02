with old_src  as
    (
        select 'old' as src
             , net_revenue
             , courserun_key
        from vertica_reference.financial_reporting.revshare201906_oldmethod
        where organization_key ilike 'IITBomb%'
    )
   , new_src  as
    (
        with arch_all as (select * from prod.financial_reporting_archive.finrep_royalty_order_report_archive)
           , arch     as (select * from arch_all where report_archive_timestamp = (select max(report_archive_timestamp) from arch_all))
        select 'new'         as src
             , "NET REVENUE" as net_revenue
             , "COURSE ID"   as courserun_key
        from arch
        where organization_key ilike 'IITBomb%'
    )
   , combined as
    (
        select *
        from old_src
        union all
        select *
        from new_src
    )
select src
     , sum(net_revenue)              as rev
     , count(distinct courserun_key) as cnt
     , rev / cnt                     as rev_per_cr
from combined
group by rollup (src)

-- that gives $205K total which is more than total bookings (see below) and therefor must be wrong.

with iitc  as (select * from dim_courses where partner_key ilike 'IITBomb%')
   , iitcr as (select * from dim_courseruns where course_key in (select course_key from iitc))
select sum(booking_amount)                         as bookings
     , count(distinct course_key)                  as cnt_courses
     , (bookings / cnt_courses)::decimal(18, 2)    as bookings_per_course
     , count(distinct courserun_key)               as cnt_courseruns
     , (bookings / cnt_courseruns)::decimal(18, 2) as bookings_per_courserun
from fact_booking
where course_key in (select course_key from iitc)
   or courserun_key in (select courserun_key from iitcr)