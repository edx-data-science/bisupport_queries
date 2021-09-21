-- https://openedx.atlassian.net/browse/BISUPPORT-2278

select *
from prod.core.dim_courseruns
where courserun_key ilike '%ASUx+MAT170x+2T2017%'
   or courserun_key ilike '%ASUx+MAT117x+1T2016%'

select count(*)
from prod.core.fact_booking

-- do I need to worry about anything but seats?
-- there are 12 enrollment code purchases
select count(*)
     , avg(fb.booking_amount)
     , fb.order_product_class
     , itoe.order_product_detail
     , fb.courserun_key
from prod.core.fact_booking                                   fb
     join prod.core.core_imd_transaction_orderline_enrollment itoe
          on fb.transaction_orderline_enrollment_hash = itoe.transaction_orderline_enrollment_hash
where course_key in ('ASUx+MAT170x', 'ASUx+MAT117x')
  and booking_date >= '2020-05-01'
      --'2019-07-01'
  and (fb.transaction_type = 'sale' or fb.transaction_type is null)
group by fb.order_product_class
       , itoe.order_product_detail
       , fb.courserun_key
order by 4
       , 3
       , 2


with rws as
         (
             select itoe.order_line_id
             from prod.core.fact_booking                                   fb
                  join prod.core.core_imd_transaction_orderline_enrollment itoe
                       on fb.transaction_orderline_enrollment_hash = itoe.transaction_orderline_enrollment_hash
             where course_key in ('ASUx+MAT170x', 'ASUx+MAT117x')
               and booking_date >= '2019-07-01'
               and (fb.transaction_type = 'sale' or fb.transaction_type is null)
               and itoe.order_product_detail = 'credit'
         )
select *
from prod.core.core_imd_transaction_orderline_enrollment
where transaction_type = 'refund'
  and order_line_id in (select * from rws)
