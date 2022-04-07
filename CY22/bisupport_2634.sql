--related to bisupport_2611, ritx program performance

with tot_ref  as (
    select program_title           as program
         , fb.course_key
         , sum(booking_amount)     as total_refunds
         , count(transaction_type) as num_refunds
    from fact_booking                as fb
         join      program_courserun as pc
                   on fb.program_id = pc.program_id
         left join dim_courseruns    as dc
                   on fb.courserun_key = dc.courserun_key
    where transaction_type = 'refund'
      and booking_date > '2017-03-01'
      and fb.program_id in (85, 64, 240, 492, 499, 530)
      and sort_revenue_order = 1
    group by program
           , fb.course_key
)

   , tot_book as (
    select program_title           as program
         , fb.course_key
         , count(transaction_type) as num_bookings
         , sum(booking_amount)     as total_bookings
    from fact_booking                as fb
         join      program_courserun as pc
                   on fb.program_id = pc.program_id
         left join dim_courseruns    as dc
                   on fb.courserun_key = dc.courserun_key
    where booking_date > '2017-03-01'
      and fb.program_id in (85, 64, 240, 492, 499, 530)
      and sort_revenue_order = 1
    group by program
           , fb.course_key
)


select tr.program
     , course_title
     , total_refunds
     , total_bookings
     , coalesce(num_refunds, 0)   as num_refunds
     , num_bookings
     , num_refunds / num_bookings as refund_rate
from tot_ref          as tr
     join tot_book    as tb
          on tr.course_key = tb.course_key
     join dim_courses as dc
          on tb.course_key = dc.course_key
order by program

