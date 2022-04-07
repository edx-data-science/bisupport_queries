with pre_prog  as (
    select courserun_title                                          as course
         , sum(coalesce(verified_count, 0))                         as pre_verified
         , sum(enrollment_count)                                    as pre_enrolled
         , sum(coalesce(verified_count, 0)) / sum(enrollment_count) as pre_vtr
         , sum(b2c_booking_amount)                                  as pre_bookings
         , avg(b2c_booking_amount)                                  as pre_avg_bookings
    from tableau_fact_b2c_funnel as tf
         join dim_courseruns     as dc
              on tf.courserun_id = dc.courserun_id
    where courserun_title in ('Rhetoric: The Art of Persuasive Writing and Public Speaking',
                              'Exercising Leadership: Foundational Principles',
                              'Remote Work Revolution for Everyone')
      and metric_date < '2021-09-01'
    group by course
)

   , post_prog as (
    select courserun_title                                          as course
         , sum(coalesce(verified_count, 0))                         as post_verified
         , sum(enrollment_count)                                    as post_enrolled
         , sum(coalesce(verified_count, 0)) / sum(enrollment_count) as post_vtr
         , sum(b2c_booking_amount)                                  as post_bookings
         , avg(b2c_booking_amount)                                  as post_avg_bookings
    from tableau_fact_b2c_funnel as tf
         join dim_courseruns     as dc
              on tf.courserun_id = dc.courserun_id
    where courserun_title in ('Rhetoric: The Art of Persuasive Writing and Public Speaking',
                              'Exercising Leadership: Foundational Principles',
                              'Remote Work Revolution for Everyone')
      and metric_date > '2021-09-01'
    group by course
)

select post_prog.course as course
     , pre_enrolled
     , post_enrolled
     , pre_verified
     , post_verified
     , pre_vtr
     , post_vtr
     , pre_bookings
     , post_bookings
     , pre_avg_bookings
     , post_avg_bookings
from pre_prog
     right join post_prog
                on pre_prog.course = post_prog.course


