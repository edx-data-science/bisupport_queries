-- queens university
select *
from prod.core.dim_organizations
where org_name ilike '%queens%'

select *
from prod.core.dim_course_authoring_orgs
where lower(partner_key) in ('uqx', 'cornellxuqx')

-- subscriptions?
with crs as
         (
             select course_key, courserun_key
             from prod.financial_reporting.finrep_royalty_order_dimension
             where organization_key = 'UQx'
         )
select count(*)
     , is_subscription
from prod.core.dim_enrollments
where courserun_key in (select crs.courserun_key from crs)
  and first_verified_date >= '2020-10-01'
group by is_subscription

-- +----------+-----------------+
-- | COUNT(*) | IS_SUBSCRIPTION |
-- +----------+-----------------+
-- |       25 | true            |
-- |     8717 | false           |
-- +----------+-----------------+

-- going to ignore subscriptions

-- enrollment codes
with crs as
         (
             select course_key, courserun_key
             from prod.financial_reporting.finrep_royalty_order_dimension
             where organization_key = 'UQx'
         )
select order_product_class
     , ec.purchase_enrollment_code_count
     , count(*)
from prod.core.fact_booking                  fb
     join prod.core.core_imd_enrollment_code ec
          on ec.purchase_order_line_id = fb.order_line_id
              and ec.purchase_order_processor = fb.order_processor
where course_key in (select course_key from crs)
  and booking_date between '2020-10-01' and '2021-03-31'
  and (fb.transaction_type is null or fb.transaction_type = 'sale')
group by order_product_class
       , ec.purchase_enrollment_code_count
order by purchase_enrollment_code_count desc

-- it looks like all enrollment code purchases were for singles, will treat them as seats

-- B2B
with crs as
         (
             select course_key, courserun_key
             from prod.financial_reporting.finrep_royalty_order_dimension
             where organization_key = 'UQx'
         )
select count(*)
     , sum(booking_amount_b2b)
     , sum(booking_amount_b2c)
     , (not fb.payment_ref_id ilike 'EDX%')   as is_abnormal
     , pelp.enrollment_id is not null         as has_pelp
     , base.order_line_id is not null         as has_ol
     , base.order_discount_amount is not null as has_discount_amt
from prod.core.fact_booking                                  fb
     left join prod.core.core_imd_paid_enrollment_list_price pelp
               on pelp.enrollment_id = fb.enrollment_id
     left join prod.core.core_base_orderline_transactions as base
               on equal_null(fb.transaction_id, base.transaction_id)
                   and equal_null(fb.order_line_id, base.order_line_id)
                   and equal_null(fb.order_processor, base.order_processor)
where course_key in (select course_key from crs)
  and booking_date between '2020-10-01' and '2021-03-31'
group by is_abnormal
       , has_pelp
       , has_ol
       , has_discount_amt



with crs as
         (
             select course_key, courserun_key
             from prod.financial_reporting.finrep_royalty_order_dimension
             where organization_key = 'UQx'
         )
select count(*)
     , sum(booking_amount_b2b)
     , sum(booking_amount_b2c)
     , sum(base.order_discount_amount)
     , booking_amount_b2b <> 0                                as has_b2b_amt
     , (not fb.payment_ref_id ilike 'EDX%')                   as is_abnormal
     , pelp.enrollment_id is not null                         as has_pelp
     , base.order_line_id is not null                         as has_ol
     , base.order_discount_amount is not null                 as has_discount_amt
     , (has_pelp and pelp.list_price = fb.booking_amount_b2b) as is_pelp_at_list
     , (not has_pelp and base.order_discount_amount = 0)      as has_no_discount
from prod.core.fact_booking                                  fb
     left join prod.core.core_imd_paid_enrollment_list_price pelp
               on pelp.enrollment_id = fb.enrollment_id
     left join prod.core.core_base_orderline_transactions as base
               on equal_null(fb.transaction_id, base.transaction_id)
                   and equal_null(fb.order_line_id, base.order_line_id)
                   and equal_null(fb.order_processor, base.order_processor)
where course_key in (select course_key from crs)
  and booking_date between '2020-10-01' and '2021-03-31'
group by is_abnormal
       , has_b2b_amt
       , has_pelp
       , has_ol
       , has_discount_amt
       , is_pelp_at_list
       , has_no_discount
;
-- the actual report
with crs as
    (
        select course_key, courserun_key
        from prod.financial_reporting.finrep_royalty_order_dimension
        where organization_key = 'UQx'
    )
   , raw as
    (
        select lru.course_key
             , lru.order_product_class
             , lru.order_line_id
             , lru.line_net_booking_amount                                                          as paid_amount
             , zeroifnull(base.order_discount_amount - zeroifnull(lru.line_net_booking_amount_b2b)) as discount_amount
        from prod.core.fact_booking_line_rollup                      lru
             left join prod.core.core_imd_paid_enrollment_list_price pelp
                       on pelp.enrollment_id = lru.enrollment_id
             left join prod.core.core_base_orderline_transactions as base
                       on equal_null(lru.order_line_id, base.order_line_id)
                           and equal_null(lru.order_processor, base.order_processor)
                           and (base.transaction_type is null or base.transaction_type = 'sale')
        where lru.course_key in (select course_key from crs)
          and lru.order_date between '2020-10-01' and '2021-03-31'
          and not lru.has_line_refund
    )
select course_key
     , iff(order_product_class = 'course-entitlement', 'bundle', 'individual') as purchase_type
     , count(*)                                                                as purchase_count
     , sum((discount_amount <> 0)::int)                                        as discount_count
     , sum(paid_amount)                                                        as paid_amount_total
     , sum(discount_amount)                                                    as discount_amount_total
from raw
group by course_key, purchase_type
order by course_key, purchase_type