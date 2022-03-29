select count(*)
     , first_verified_date is not null as is_verified
     , courserun_key
from dim_enrollments
where courserun_key ilike '%course-v1:UQx+Write101x+2T2020%'
group by is_verified
       , courserun_key

select enr.net_paid_enrollments
from prod.financial_reporting.finrep_royalty_order_summary            sum
     join prod.financial_reporting.finrep_royalty_order_dimension     dim
          on dim.report_output_row_id = sum.report_output_row_id
     join prod.financial_reporting.finrep_royalty_enrollment_discount enr
          on enr.courserun_key = dim.courserun_key
where dim.courserun_key = 'course-v1:UQx+Write101x+2T2020'

with vpc as (select * from prod.core.)
select count(*)
     , first_verified_date is not null as is_verified
     , is_subscription
     , courserun_key
from dim_enrollments
where courserun_key ilike '%course-v1:UQx+Write101x+2T2020%'
group by is_verified
       , is_subscription
       , courserun_key
order by 1 desc


select count(*)
     , order_product_class
from prod.core.fact_booking_line_rollup
where courserun_key ilike '%course-v1:UQx+Write101x+2T2020%'
group by order_product_class

select count(*)
     , sum(amount_learner_paid)
     , sum(citoe.amount_invoice)
     , citoe.amount_learner_paid <> 0          as is_learner_pay
     , citoe.amount_invoice <> 0               as is_b2b_pay
     , citoe.order_line_voucher_id is not null as has_voucher
     , bb.voucher_product_category_slug
from prod.core.dim_enrollments                                         de
     left join prod.core.core_imd_transaction_orderline_enrollment     citoe
               on citoe.enrollment_id = de.enrollment_id
     left join prod.core.core_imd_transaction_orderline_enrollment_b2b bb
               on bb.transaction_orderline_enrollment_hash = citoe.transaction_orderline_enrollment_hash
     left join dim_voucher                                             dv
               on dv.voucher_id = citoe.order_line_voucher_id
where de.courserun_key = 'course-v1:UQx+Write101x+2T2020'
  and de.first_verified_date is not null
group by is_learner_pay
       , is_b2b_pay
       , has_voucher
       , bb.voucher_product_category_slug
order by 1 desc

with orap as
    (
        select enrollment_id
        from core_imd_transaction_orderline_enrollment_b2b
        where voucher_product_category_slug = 'partner-no-rev-orap'
    )
   , pp   as
    (
        select enrollment_id
        from core_imd_transaction_orderline_enrollment_b2b
        where voucher_product_category_slug = 'partner-no-rev-prepay'
    )
select count(*)
     , enrollment_id in (select * from orap) as is_no_rev_orap
     , enrollment_id in (select * from pp)   as is_no_rev_prepay
     , is_subscription
from dim_enrollments de
where de.courserun_key = 'course-v1:UQx+Write101x+2T2020'
  and de.first_verified_date is not null
group by is_no_rev_orap
       , is_no_rev_prepay
       , is_subscription
order by 1 desc

with arch as (select * from prod.financial_reporting_archive.finrep_royalty_order_report_archive)
   , ord  as (select * from arch where report_archive_timestamp between '2022-01-01' and '2022-01-31')
select "B2B - CUMULATIVE PAID ENROLLS"
     , "B2C - CUMULATIVE PAID ENROLLS"
from ord
where "COURSE ID" = 'course-v1:UQx+Write101x+2T2020'

select 802 + 644


select count(*) as count
     , bb.voucher_product_category_slug
     , dv.voucher_name
from prod.core.dim_enrollments                                         de
     left join prod.core.core_imd_transaction_orderline_enrollment     citoe
               on citoe.enrollment_id = de.enrollment_id
     left join prod.core.core_imd_transaction_orderline_enrollment_b2b bb
               on bb.transaction_orderline_enrollment_hash = citoe.transaction_orderline_enrollment_hash
     left join dim_voucher                                             dv
               on dv.voucher_id = citoe.order_line_voucher_id
where de.courserun_key = 'course-v1:UQx+Write101x+2T2020'
  and de.first_verified_date is not null
  and bb.voucher_product_category_slug in ('partner-no-rev-prepay', 'partner-no-rev-orap')
group by bb.voucher_product_category_slug
       , dv.voucher_name
order by 1 desc
