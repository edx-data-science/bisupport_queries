with paying_users as (
select *
from prod.core.tableau_fact_b2c_funnel
where b2c_verified_count = 1
--    and user_id = '18636966'
    )

, paid_amount as (
    select *
    from prod.core.tableau_fact_b2c_funnel
    where tableau_fact_b2c_funnel.b2c_booking_amount is not null
 --       and user_id = '18636966'
)

, data_composite as (
select de.*
     , row_number() over (partition by de.user_id order by first_enrollment_date) as enrollment_order
     , case when pa.user_id is null then null else
         rank() over (partition by de.user_id order by pa.metric_date)
         end as purchase_order
    , pa.b2c_booking_amount
from prod.core.dim_enrollments de
    left join paying_users pu on pu.user_id = de.user_id and pu.courserun_id = de.courserun_id
    left join paid_amount pa on pa.user_id = de.user_id and pa.courserun_id = de.courserun_id
-- where de.user_id = '18636966'
order by enrollment_order)

, first_enrollment_behavior as (
select *
from data_composite
where enrollment_order = 1)

, post_first_enrollment_behavior as (
    select count(dc.b2c_booking_amount) as secondary_enrollments_with_purchase
         ,sum(dc.b2c_booking_amount) as tot_secondary_purchase_amt
         ,count(enrollment_id) as secondary_enrollments
         ,user_id
    from data_composite dc
    where enrollment_order != 1
    group by user_id
)

, user_behavior_summary as (
    select enrollment_id
         , fe.user_id
         , secondary_enrollments_with_purchase
         , tot_secondary_purchase_amt
         , fe.b2c_booking_amount                                     as first_purchase_amount
         , case when fe.b2c_booking_amount is null then 0 else 1 end as first_purcahse_flag
    from first_enrollment_behavior                fe
         left join post_first_enrollment_behavior pe
                   on fe.user_id = pe.user_id
)

, avg_first_purchase_amt as
(
    select sum(case when purchase_order = 1 then (b2c_booking_amount) else null end) as tot_first_purchase_amt
         , user_id
    from first_enrollment_behavior fe
    group by user_id
)

/*
-- calculate first purchase amount and segment out post first purchase amount behavior
select avg(tot_first_purchase_amt)--,afpa.user_id
     ,sum(tot_secondary_purchase_amt)/sum(secondary_enrollments_with_purchase)
     ,tot_first_purchase_amt is null
from avg_first_purchase_amt afpa
    left join post_first_enrollment_behavior pfeb on pfeb.user_id = afpa.user_id
group by 3
--group by 2
 */

-- users who purchased on their first enroll
, first_enroll_purchasing_users as (
select
    case when enrollment_order = 1 and purchase_order is not null then 'purchase on first enroll'
         when enrollment_order = 1 and purchase_order is null then 'no purchase on first enroll'
       end as flag
    , user_id
from data_composite)
/*
select sum(secondary_enrollments_with_purchase)/sum(secondary_enrollments),flag,count(*)
from first_enroll_purchasing_users fepu
    left join post_first_enrollment_behavior pfeb on fepu.user_id = pfeb.user_id
group by flag
*/


select-- feb.user_id
     coalesce(purchase_order,0) = 1 as first_purchase_on_enrollment
    ,sum(secondary_enrollments_with_purchase)/sum(secondary_enrollments)
    ,sum(secondary_enrollments)
from first_enrollment_behavior feb
    left join post_first_enrollment_behavior pfeb on feb.user_id = pfeb.user_id
--where feb.user_id in ('18636966','1613495','35855982')
group by 1
--where purchase_order = 1 and enrollment_order = 1









