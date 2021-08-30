-- users under age of 13
select au.email
     , au.username
     , au.first_name
     , au.last_name
     , users.country_label as country
     , users.gender
     , users.year_of_birth
     , users.account_created_at
     , users.is_active
     , year(users.account_created_at) - users.year_of_birth as age
from prod.core.dim_users    as users
join prod.lms_pii.auth_user as au
     on users.user_id = au.id
where users.year_of_birth is not null
  and age < 13

-- under 13 users enrolled courses
select distinct au.email
     , au.username
     , au.first_name
     , au.last_name
     , users.country_label as country
     , users.gender
     , users.year_of_birth
     , users.account_created_at
     , users.is_active
     , year(users.account_created_at) - users.year_of_birth as age
     , count(distinct de.courserun_key, ', ') over (
            partition by
                au.email
        ) as no_of_enrolled_courses_by_user
from prod.core.dim_users    as users
join prod.lms_pii.auth_user as au
     on users.user_id = au.id
join prod.core.dim_enrollments as de
     on de.user_id = users.user_id
where users.year_of_birth is not null
  and age < 13
order by au.email

-- under 13 users completed courses
select distinct au.email
     , au.username
     , au.first_name
     , au.last_name
     , users.country_label as country
     , users.gender
     , users.year_of_birth
     , users.account_created_at
     , users.is_active
     , year(users.account_created_at) - users.year_of_birth as age
     , count(distinct de.courserun_key, ', ') over (
            partition by
                au.email
        ) as no_of_courses_completed_by_user
from prod.core.dim_users    as users
join prod.lms_pii.auth_user as au
     on users.user_id = au.id
join prod.core.dim_enrollments as de
     on de.user_id = users.user_id
join prod.lms.grades_persistentcoursegrade as cc
     on cc.user_id = users.user_id and cc.course_id = de.courserun_key
where users.year_of_birth is not null
  and age < 13
  and cc.passed_timestamp is not null
order by au.email

-- eu_users_14_15
select au.email
     , au.username
     , au.first_name
     , au.last_name
     , users.country_label as country
     , dc.region as continent
     , users.gender
     , users.year_of_birth
     , users.account_created_at
     , users.is_active
     , year(users.account_created_at) - users.year_of_birth as age
from prod.core.dim_users    as users
join prod.lms_pii.auth_user as au
     on users.user_id = au.id
join prod.core.dim_country  as dc
     on users.country_code = dc.country_code
where users.year_of_birth is not null
  and age in (14, 15)
  and dc.region = 'Europe'
order by au.email
