--count of users from countries in Europe by enrolled in courses, sliced by country of course creation

select country_label                             as user_country
     , language_locale                           as course_country
     , dim_courseruns.partner_key                as partner_key
     , program_title
     , courserun_title                           as course_title
     , count(distinct (dim_enrollments.user_id)) as total_learners
from dim_courseruns
     join dim_enrollments
          on dim_courseruns.courserun_id = dim_enrollments.courserun_id
              and dim_courseruns.courserun_key = dim_enrollments.courserun_key
     join dim_users
          on dim_enrollments.user_id = dim_users.user_id
     join dim_country
          on dim_users.country_code = dim_country.country_code
     join program_courserun
          on dim_enrollments.courserun_id = program_courserun.courserun_id
              and dim_courseruns.courserun_id = program_courserun.courserun_id
where region = 'Europe'                    --stakeholder request was for European learners only
  and sub_region = 'Western Europe'        --narrowed to subregion to limit results, swapped for Eastern, Northern, or Southern and created separate sheets for each
  and course_country is not null
  and course_country != ''
  and first_enrollment_date > '2017-01-01' --stakeholder requested data from the last 5 years
group by user_country
       , course_country
       , dim_courseruns.partner_key
       , program_title
       , course_title
order by user_country

--users counted per each course enrollment, so users enrolled in multiple courses counted more than once
--used this to get an aggregate table with unique learner totals per country

with enrollment_by_courserun_europe as (
    select count(distinct (dim_enrollments.user_id)) as total_learners
         , country_label                             as user_country
         , language_locale                           as course_country
         , dim_courseruns.partner_key                as partner_key
         , program_title
         , courserun_title                           as course_title
    from dim_courseruns
         join dim_enrollments
              on dim_courseruns.courserun_id = dim_enrollments.courserun_id
                  and dim_courseruns.courserun_key = dim_enrollments.courserun_key
         join dim_users
              on dim_enrollments.user_id = dim_users.user_id
         join dim_country
              on dim_users.country_code = dim_country.country_code
         join program_courserun
              on dim_enrollments.courserun_id = program_courserun.courserun_id
                  and dim_courseruns.courserun_id = program_courserun.courserun_id
    where region = 'Europe'
      and course_country is not null
      and course_country != ''
      and first_enrollment_date > '2017-01-01'
    group by user_country
           , course_country
           , dim_courseruns.partner_key
           , program_title
           , course_title
)

select count(distinct (user_id)) as eu_learners_per_course_country
     , course_country
from enrollment_by_courserun_europe
group by course_country
order by eu_learners_per_course_country desc

