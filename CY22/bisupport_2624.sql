with pre             as (
    select course_key
         , booking_date
         , sum(booking_amount) as total_bookings_pre
         , avg(booking_amount) as avg_bookings_pre
    from fact_booking
    where booking_date < '2021-09-22'
      and program_id in (690, 691)
    group by course_key
           , booking_date
)

   , post            as (
    select course_key
         , booking_date
         , sum(booking_amount) as total_bookings_post
         , avg(booking_amount) as avg_bookings_post
    from fact_booking
    where booking_date > '2021-09-22'
      and program_id in (690, 691)
    group by course_key
           , booking_date
)

   , program_courses as (
    select dp.program_title as program
         , dp.program_id
         , courserun_title  as course
         , course_key       as dim_course
    from program_courserun   as pc
         join dim_program    as dp
              on pc.program_id = dp.program_id
         join dim_courseruns as dc
              on pc.courserun_id = dc.courserun_id
    where dp.program_title in ('Leadership and Communication', 'Leading in a Remote Environment')
)

select distinct
       program
     , course
     , sum(total_bookings_pre)  as total_bookings_pre
     , sum(total_bookings_post) as total_bookings_post
     , avg(avg_bookings_pre)    as avg_daily_bookings_pre
     , avg(avg_bookings_post)   as avg_daily_bookings_post
from program_courses as prog
     join pre
          on dim_course = pre.course_key
     join post
          on dim_course = post.course_key
group by program
       , course
order by program
       , course

