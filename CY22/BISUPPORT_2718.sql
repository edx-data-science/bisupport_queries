/*PART 1: FIND LEARNERS ALREADY ENROLLED IN ANY 1 OF THE COURSES IN THE COGNIZANT SKILLS ACCELATOR PROGRAM*/

drop table list_1
create transient table list_1 as
with enterprise_learners as (
    select distinct lms_user_id
    from prod.enterprise.ent_base_enterprise_user
)
select de.user_id
     , up.first_name
     , up.last_name
     , up.email
     , c.country_name
     , dc.course_key
     , dc.course_title
     , is_verified_track
     , first_enrollment_date::date                                          as first_enrollment_date
     , coalesce(de.first_downloadable_certificate_date, g.passed_timestamp) as completion_date
from prod.core.dim_enrollments                           de
     left join prod.core.dim_courseruns                  cr
               on de.courserun_key = cr.courserun_key
     left join prod.core.dim_courses                     dc
               on dc.course_id = cr.course_id
     left join enterprise_learners                       eu
               on eu.lms_user_id = de.user_id
     left join prod.core_pii.corepii_user_profile        up
               on up.user_id = de.user_id
     left join prod.core.dim_users                       du
               on du.user_id = de.user_id
     left join prod.core.dim_country                     c
               on c.country_code = du.country_code_blended
     left join prod.lms_pii.grades_persistentcoursegrade g
               on g.user_id = de.user_id
                   and g.course_id = cr.courserun_key
where dc.course_key in
      (
       'HKUSTx+COMP10.1x', 'HKUSTx+COMP10.2x', 'IBM+CAD220EN', 'IBM+CAD0321EN', 'UC3Mx+IT.1.1x '
          )
  and eu.lms_user_id is null -- not enterprise learner
  and up.is_subscribed
  and not du.is_staff
  and not du.is_superuser
order by g.user_id


select *
from list_1;

//PART 2: USERS ENROLLED IN COURSES "SIMILAR" TO THE COURSES IN THE PATHWAY, B2B subs catalog only
--the first part of this is taken from the code used in BISUPPORT_2667

drop table list_2
create transient table list_2 as
with emsi_course_skills_map as (
    select distinct
           tcs.course_key
         , ts.name                                             as skill_name
         , ts.description                                      as skill_description
         , ts.id                                               as skill_id
         , tcs.confidence
         , row_number()
                   over (partition by course_key
                       order by confidence desc, skill_id asc) as skill_number
    from prod.discovery.taxonomy_courseskills    tcs
         left join prod.discovery.taxonomy_skill ts
                   on ts.id = tcs.skill_id
    where not tcs.is_blacklisted
      and (
            ts.name like '%Java%'
            -- or ts.name like '%Web Service%'
            or ts.name like '%API%'
            or ts.name like '%Network Security%'
            or ts.name like '%Cyber Security%'
            or ts.name like '%DevOps%'
            or ts.name like '%Data Store%'
            or ts.name like '%Persistence%'
            or ts.name like '%Springboot%'
            or ts.name like '%Application Deployment%'
        )
      and tcs.confidence >= 1
    order by course_key
           , skill_number
)
   , relevant_courses       as (
    select distinct
           a.course_key
         , a.course_number_id as course_id
    from prod.core.fact_course_availability_rollup_daily   a
         join emsi_course_skills_map                       s
              on s.course_key = a.course_key
         join prod.enterprise.map_catalog_query_to_content c
              on c.course_key = a.course_key
                  --where (a.is_active = 1 or a.is_upcoming = 1)
                  -- and a.event_date
                  --  between '2022-01-01' and '2022-12-01'
                  and c.catalog_query_id = 1923
)
   , selected_courses       as (
    select rc.course_key
         , rc.course_id
         , arrayagg(emsi1.skill_name) within group (order by emsi1.skill_number) as skills_array
    from relevant_courses                 rc
         left join emsi_course_skills_map emsi1
                   on emsi1.course_key = rc.course_key
    group by 1
           , 2
)
   , enterprise_learners
                            as (
        select distinct lms_user_id
        from prod.enterprise.ent_base_enterprise_user
    )
//SAME QUERY ABOVE, with modifications
   , list_2                 as (
    select de.user_id
         , up.first_name
         , up.last_name
         , up.email
         , c.country_name
         , dc.course_key
         , dc.course_title
         , sc.skills_array
         , is_verified_track
         , first_enrollment_date::date                                          as first_enrollment_date
         , coalesce(de.first_downloadable_certificate_date, g.passed_timestamp) as completion_date
    from prod.core.dim_enrollments                           de

         left join prod.core.dim_courseruns                  cr
                   on de.courserun_key = cr.courserun_key
         join      selected_courses                          sc
                   on sc.course_key = cr.course_key
         left join prod.core.dim_courses                     dc
                   on dc.course_id = cr.course_id
         left join enterprise_learners                       eu
                   on eu.lms_user_id = de.user_id
         left join prod.core_pii.corepii_user_profile        up
                   on up.user_id = de.user_id
         left join prod.core.dim_users                       du
                   on du.user_id = de.user_id
         left join prod.core.dim_country                     c
                   on c.country_code = du.country_code_blended
         left join prod.lms_pii.grades_persistentcoursegrade g
                   on g.user_id = de.user_id
                       and g.course_id = cr.courserun_key
    where eu.lms_user_id is null -- not enterprise learner
      and up.is_subscribed
      and dc.course_key <> 'HarvardX+CS50x'
      and de.first_enrollment_date::date > '2021-06-01'
      and not du.is_staff
      and not du.is_superuser
      and de.user_id not in
          (
              select distinct user_id
              from list_1
          )
    order by g.user_id
)
select *
from list_2

select *
from list_2;



//PART 3: USERS ENROLLED IN COURSES "SIMILAR" TO THE COURSES IN THE PATHWAY
--the first part of this is taken from the code used in BISUPPORT_2667

with emsi_course_skills_map as (
    select distinct
           tcs.course_key
         , ts.name                                             as skill_name
         , ts.description                                      as skill_description
         , ts.id                                               as skill_id
         , tcs.confidence
         , row_number()
                   over (partition by course_key
                       order by confidence desc, skill_id asc) as skill_number
    from prod.discovery.taxonomy_courseskills    tcs
         left join prod.discovery.taxonomy_skill ts
                   on ts.id = tcs.skill_id
    where not tcs.is_blacklisted
      and (
            ts.name like '%Java%'
            -- or ts.name like '%Web Service%'
            or ts.name like '%API%'
            or ts.name like '%Network Security%'
            or ts.name like '%Cyber Security%'
            or ts.name like '%DevOps%'
            or ts.name like '%Data Store%'
            or ts.name like '%Persistence%'
            or ts.name like '%Springboot%'
            or ts.name like '%Application Deployment%'
        )
      and tcs.confidence >= 1
    order by course_key
           , skill_number
)
   , relevant_courses       as (
    select distinct
           a.course_key
         , a.course_number_id as course_id
    from prod.core.fact_course_availability_rollup_daily   a
         join emsi_course_skills_map                       s
              on s.course_key = a.course_key
         join prod.enterprise.map_catalog_query_to_content c
              on c.course_key = a.course_key
    -- where (a.is_active = 1 or a.is_upcoming = 1)
    -- and a.event_date
    --  between '2022-01-01' and '2022-12-01'
    --    and c.catalog_query_id = 1923
)
   , selected_courses       as (
    select rc.course_key
         , rc.course_id
         , arrayagg(emsi1.skill_name) within group (order by emsi1.skill_number) as skills_array
    from relevant_courses                 rc
         left join emsi_course_skills_map emsi1
                   on emsi1.course_key = rc.course_key
    group by 1
           , 2
)
   , enterprise_learners
                            as (
        select distinct lms_user_id
        from prod.enterprise.ent_base_enterprise_user
    )
//SAME QUERY ABOVE, with modifications
   , list_3                 as (
    select de.user_id
         , up.first_name
         , up.last_name
         , up.email
         , c.country_name
         , dc.course_key
         , dc.course_title
         , sc.skills_array
         , is_verified_track
         , first_enrollment_date::date
         , coalesce(de.first_downloadable_certificate_date, g.passed_timestamp) as completion_date
    from prod.core.dim_enrollments                           de

         left join prod.core.dim_courseruns                  cr
                   on de.courserun_key = cr.courserun_key
         join      selected_courses                          sc
                   on sc.course_key = cr.course_key
         left join prod.core.dim_courses                     dc
                   on dc.course_id = cr.course_id
         left join enterprise_learners                       eu
                   on eu.lms_user_id = de.user_id
         left join prod.core_pii.corepii_user_profile        up
                   on up.user_id = de.user_id
         left join prod.core.dim_users                       du
                   on du.user_id = de.user_id
         left join prod.core.dim_country                     c
                   on c.country_code = du.country_code_blended
         left join prod.lms_pii.grades_persistentcoursegrade g
                   on g.user_id = de.user_id
                       and g.course_id = cr.courserun_key
    where dc.course_key in
          (
              select distinct course_key
              from relevant_courses
          )
      and eu.lms_user_id is null -- not enterprise learner
      and up.is_subscribed
      and dc.course_key <> 'HarvardX+CS50x'
      and de.first_enrollment_date > '2021-06-01'
      and not du.is_staff
      and not du.is_superuser
      and de.user_id not in
          (
              select distinct user_id
              from list_1
              union
              select distinct user_id
              from list_2
          )
    order by g.user_id
)
select *
from list_3;

