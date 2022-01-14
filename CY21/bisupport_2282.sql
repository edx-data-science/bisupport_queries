select date_trunc('month', booking_date) as month
     , sum(booking_amount)               as bookings
from prod.core.fact_booking                                   b
     join prod.core.core_imd_transaction_orderline_enrollment e
          on e.transaction_orderline_enrollment_hash = b.transaction_orderline_enrollment_hash
where e.order_line_voucher_code = 'HSBC15'
group by 1
order by 1;