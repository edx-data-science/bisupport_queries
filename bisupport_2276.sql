select *
from dim_enrollments
where courserun_key = 'course-v1:MITx+11.S198x+1T2020'

with itoe as (select * from prod.core.core_imd_transaction_orderline_enrollment)
select date_trunc(month, nvl(itoe.transaction_date, itoe.order_timestamp))::date as enroll_month
     , itoe.is_online_campus_free
     , itoe.is_partner_no_rev
     , itoe.is_remote_access_program
     , count(distinct itoe.enrollment_id)                                        as enrollment_count
from itoe
where itoe.courserun_key = 'course-v1:MITx+11.S198x+1T2020'
  and enroll_month <= '2020-08-01'
group by enroll_month
       , is_partner_no_rev
       , is_remote_access_program
       , is_online_campus_free


select *
from prod.financial_reporting_archive.finrep_royalty_order_report_archive
where "COURSE ID" = 'course-v1:MITx+11.S198x+1T2020'
order by report_timestamp

select "CUMULATIVE PAID ENROLLMENTS", "CUMULATIVE # OF REFUNDS", *
from prod.financial_reporting_archive.finrep_royalty_order_report_archive
where "COURSE ID" = 'course-v1:MITx+11.S198x+1T2020'
  and report_archive_timestamp between '2020-09-01' and '2020-09-30'



with itoe  as (select * from prod.core.core_imd_transaction_orderline_enrollment)
   , dts as (select date_column                     as cut_off
                    , dateadd(month, -1, date_column) as report_month
               from prod.core.dim_date
               where date_column between '2020-06-01' and '2021-04-01'
                 and day_num_in_month = 1)
select dts.report_month
     , count(distinct iff(itoe.is_online_campus_free, enrollment_id, null)) as online_campus_free_enrollment_count
     , count(distinct iff(itoe.is_partner_no_rev, enrollment_id, null)) as partner_no_rev_enrollment_count
     , count(distinct iff(itoe.is_remote_access_program, enrollment_id, null)) as remote_access_program_enrollment_count
     , count(distinct iff(not (itoe.is_online_campus_free or itoe.is_partner_no_rev or itoe.is_remote_access_program), enrollment_id, null)) as paid_enrollment_count
from itoe
cross join dts
where nvl(itoe.transaction_date, itoe.order_timestamp)::date < dts.cut_off
  and itoe.courserun_key = 'course-v1:MITx+11.S198x+1T2020'
group by dts.report_month
order by report_month
