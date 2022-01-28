with users_spanish_speaking_countries as
    (
        select distinct u.user_id, up.email
        from prod.core.dim_users                     u
             join prod.core.dim_country              c
                  on c.country_code = u.country_code_blended
             join prod.core_pii.corepii_user_profile up
                  on u.user_id = up.user_id
        where last_login_datetime::date > '2021-01-01'
          and c.spanish_speaking_country
    )
   , users_spanish_course             as (
    select distinct u.user_id, up.email
    from prod.core.dim_enrollments               e
         join prod.core.dim_courseruns           cr
              on e.courserun_key = cr.courserun_key
         join prod.core.dim_users                u
              on u.user_id = e.user_id
         join prod.core_pii.corepii_user_profile up
              on u.user_id = up.user_id
    where cr.is_spanish_language_content
      and u.last_login_datetime::date > '2021-01-01'
)
   , spanish_users                    as
    (
        select user_id, email
        from users_spanish_course
        union
        select user_id, email
        from users_spanish_speaking_countries
    )
select distinct e.user_id, u.email
from prod.core.dim_enrollments     e
     join prod.core.dim_courseruns cr
          on cr.courserun_key = e.courserun_key
     join spanish_users as         u
          on u.user_id = e.user_id
where primary_subject_name in
      ('computer-science', 'data-analysis-statistics')
																																													
