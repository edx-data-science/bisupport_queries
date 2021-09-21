--bisupport-2420
--active users in the last 3 months
with active_users as (
select distinct user_id
from prod.core_event_sources.fact_active_user_day
where activity_day >= '2021-06-21'
--first enrollment date for each user
), first_enrollment_date as (
select min(first_enrollment_date) as first_enrollment_date, user_id
from prod.core.dim_enrollments de
group by 2
)
select count(au.user_id), year(first_enrollment_date)
from active_users au
join first_enrollment_date fe
on au.user_id=fe.user_id
group by 2
