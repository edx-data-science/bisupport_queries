-- these are the courses mentioned

-- from spreadsheet
create or replace temporary table courses as
    (
        select *
        from prod.core.dim_courses
        where course_key in (
                             'RICEx+ELEC301.3x', 'RiceX+ELEC301x', 'RICEx+Math355.1x'
            )
    )
;

-- from spreadsheet
create or replace temporary table users as
    (
        select *
        from prod.core.dim_users
        where user_id in (
                          2872865, 6015537, 10045327, 12298324, 14443820, 14698609, 18199175, 20643874, 21864278, 27031358, 29336062, 31669204,
                          33201313, 35097602, 35118665, 36295389, 2474941, 25441160
            )
    )
;

-- Q: are all the unrefunded lines for those courses from on of these users?
-- It appears not. :(
select count(*)
     , is_line_fully_refunded
     , user_id in (select u.user_id from users u) as is_user_in_xl
from prod.core.fact_booking_line_rollup
where course_key in (select course_key from courses)
  and order_product_class = 'course-entitlement'
group by is_line_fully_refunded
       , is_user_in_xl

-- Q: what would the full set be?

select ru.payment_ref_id
     , ru.course_key
     , ru.is_line_fully_refunded
     , ru.line_sale_amount_direct        as sale_amount
     , ru.line_refund_amount_direct      as refund_amount
     , ru.line_net_booking_amount_direct as net_amount
     , ru.is_redeemed
     , ru.user_id in (select u.user_id from users u) as is_user_in_xl
     , ru.user_id
     , au.email
from prod.core.fact_booking_line_rollup ru
join prod.lms_pii.auth_user au
   on au.id = ru.user_id
where course_key in (select course_key from courses)
  and order_product_class = 'course-entitlement'
  and line_sale_amount_direct <> 0
order by is_user_in_xl desc, is_line_fully_refunded, user_id, payment_ref_id
