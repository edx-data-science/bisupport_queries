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

-- after clarification from requester

with iitc  as (select * from dim_courses where partner_key ilike 'IITBomb%')
   , iitcr as (select * from dim_courseruns where course_key in (select course_key from iitc))
select sum(booking_amount) as bookings
     , sum(royalty_amount) as royalty
     , courserun_key
from fact_booking
where booking_date between '2021-02-01' and '2022-01-31'
  and (courserun_key in (select courserun_key from iitcr))
group by courserun_key
order by courserun_key
;

select min(report_archive_timestamp)                                              as min_timestamp
     , count(*)
     , year(report_archive_timestamp) || 'Q' || quarter(report_archive_timestamp) as arch_quarter_name
     , date_trunc(quarter, report_archive_timestamp)::date                        as arch_quarter_date
from prod.financial_reporting_archive.finrep_royalty_order_report_archive
where report_archive_timestamp > '2021-01-01'
group by arch_quarter_name
       , arch_quarter_date
order by 1



with arch_all as (select * from prod.financial_reporting_archive.finrep_royalty_order_report_archive)
   , archs    as
    (
        select min(report_archive_timestamp)                                               as min_timestamp
             , count(*)
             , date_trunc(quarter, report_archive_timestamp)::date                         as arch_quarter_date
             , 'Y' || year(arch_quarter_date - 1) || 'Q' || quarter(arch_quarter_date - 1) as arch_quarter_name
        from arch_all
        where report_archive_timestamp > '2021-01-01'
        group by arch_quarter_name
               , arch_quarter_date
    )
   , src      as
    (
        select arch_all."COURSE ID" as courserun_key
             , payout               as val
             --, "PREVIOUSLY EARNED"  as val
             , arch_quarter_name
        from arch_all
             join archs
                  on arch_all.report_archive_timestamp = archs.min_timestamp
        where organization_key ilike 'IITBomb%'
          and val <> 0
          and courserun_key in
              ('course-v1:IITBombayX+CS101.2x+1T2020', 'course-v1:IITBombayX+CS213.2x+1T2021', 'course-v1:IITBombayX+CS101.1x+1T2020',
               'course-v1:IITBombayX+LaTeX101x+1T2021', 'course-v1:IITBombayX+CS213.3x+1T2020', 'course-v1:IITBombayX+CS213.1x+1T2021',
               'course-v1:IITBombayX+CS101.2x+1T2021', 'course-v1:IITBombayX+LaTeX101x+1T2020', 'course-v1:IITBombayX+CS101.1x+1T2021',
               'course-v1:IITBombayX+CS213.1x+1T2020')
    )
   , pv       as
    (
        select *
             , zeroifnull(y2021q1) + zeroifnull(y2021q2) + zeroifnull(y2021q3) + zeroifnull(y2021q4) as y2021_total
        from src pivot (sum(val) for arch_quarter_name in (/*'2020Q4',*/'Y2021Q1','Y2021Q2','Y2021Q3','Y2021Q4'))
                 as x (courserun_key, y2021q1, y2021q2, y2021q3, y2021q4)
    )
select *
from pv
order by 1
;

-- select nvl(new_src.courserun_key, old_src.courserun_key) courserun_key
--      , zeroifnull(old_src.payout) as payout_jan_2021
--      , zeroifnull(new_src.payout) as payout_jan_2022
-- from new_src
-- full outer join old_src
--     on new_src.courserun_key = old_src.courserun_key
-- order by new_src.courserun_key is not null, new_src.courserun_key, old_src.courserun_key