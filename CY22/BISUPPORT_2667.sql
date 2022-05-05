--COURSE SKILL ANALYSIS CODE--

/*Question: What are the best courses to recommend to our customer including Foundational Java, Advanced Java, Java Application Deployment, Springboot Basics,
Web Services and APIS, Data Stores and Persistence, Security and DevOps?*/

/*Strategy:
1) Find courses using a keyword search of EMSI skills.
--LIMITATIONS:
--1) Data quality before 2019 for course completion is challenging to work with.
--2) Some courses did not have pass rate information or had very few verified learners.
Part 1: Build tables to identify courses with desired skills.
Create a list of relevant course_ids using prerequisites column in course_metadata_course where desired terms were present.*/


/*Create a list of relevant course_keys using EMSI skills where desired terms were present. */
with emsi_course_skills_map   as (
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
            or ts.name like '%Web Service%'
            or ts.name like '%API%'
            or ts.name like '%Network Security%'
            or ts.name like '%Cyber Security%'
            or ts.name like '%DevOps%'
            or ts.name like '%Data Store%'
            or ts.name like '%Persistence%'
            or ts.name like '%Springboot%'
            or ts.name like '%Application Deployment%'
        )
      and tcs.confidence > .60
    order by course_key
           , skill_number
)
   -- select * from emsi_course_skills_map where confidence<1;
   ,
    /*narrow to set of courses with at least one active courserun in 2022 AND in the B2B subscription catalog*/
    relevant_courses          as (
        select distinct
               a.course_key
             , a.course_number_id as course_id
        from prod.core.fact_course_availability_rollup_daily   a
             join emsi_course_skills_map                       s
                  on s.course_key = a.course_key
             join prod.enterprise.map_catalog_query_to_content c
                  on c.course_key = a.course_key
        where (a.is_active = 1 or a.is_upcoming = 1)
          and a.event_date
            between '2022-01-01' and '2022-12-01'
          and c.catalog_query_id = 1923 --query_id for B2B subs catalog
    )
   --select count(distinct course_key) from relevant_courses;
/*Add description information to selected courses table*/

   , selected_courses         as (
    select rc.course_key
         , rc.course_id
        /* , md.title
        , md.short_description
         , md.full_description
          , md.prerequisites_raw
          , md.outcome
          , md.syllabus_raw*/
         , arrayagg(emsi1.skill_name) within group (order by emsi1.skill_number) as skills_array
        /* alternate code for displaying skills
        , emsi1.skill_name                                                     as skill_matched_1
         , emsi1.confidence                                                     as confidence_1
         , emsi2.skill_name                                                     as skill_matched_2
         , emsi2.confidence                                                     as confidence_2
         , emsi3.skill_name                                                     as skill_matched_3
         , emsi3.confidence                                                     as confidence_3
         , emsi4.skill_name                                                     as skill_matched_4
         , emsi4.confidence                                                     as confidence_4
         , emsi5.skill_name                                                     as skill_matched_5
         , emsi5.confidence                                                     as confidence_5
         , emsi6.skill_name                                                     as skill_matched_6
         , emsi6.confidence                                                     as confidence_6*/
    from relevant_courses                 rc
         left join emsi_course_skills_map emsi1
                   on emsi1.course_key = rc.course_key
        /* alternate code
        and emsi1.skill_number = 1
    left join emsi_course_skills_map                emsi2
    on emsi2.course_key = rc.course_key
        and emsi2.skill_number = 2
    left join emsi_course_skills_map                emsi3
    on emsi3.course_key = rc.course_key
        and emsi3.skill_number = 3
    left join emsi_course_skills_map                emsi4
    on emsi4.course_key = rc.course_key
        and emsi4.skill_number = 4
    left join emsi_course_skills_map                emsi5
    on emsi5.course_key = rc.course_key
        and emsi5.skill_number = 5
    left join emsi_course_skills_map                emsi6
    on emsi6.course_key = rc.course_key
        and emsi6.skill_number = 6*/
    group by 1
           , 2
)
/* Find relevant enrollments with inner join to selected_courses */
   , enrollments              as
    (
        select cr.course_key
             , cr.course_id
             , count(de.enrollment_id)                                                                       as total_enrollments
             , count(case when g.passed_timestamp is not null then de.enrollment_id end)                     as verified_passes
             , count(case when is_verified_track then de.enrollment_id end)                                  as verified_enrollments
             , count(case when de.first_downloadable_certificate_date is not null then de.enrollment_id end) as certificates_earned
        from prod.core.dim_enrollments                       de
             left join prod.lms.grades_persistentcoursegrade g
                       on g.user_id = de.user_id
                           and g.course_id = de.courserun_key
             left join prod.core.dim_courseruns              cr
                       on de.courserun_key = cr.courserun_key
             join      selected_courses                      sc
                       on sc.course_key = cr.course_key
             ---where first_enrollment_date '2021-12-31'
        group by 1
               , 2
    )
/*Add course_id to prod.core.fact_enrollment_engagement using courserun_key. Get engagement day count and learning time for each user.*/
   , course_engagement        as
    (
        select cr.course_id
             , ee.user_id
             , ee.first_enrollment_date
             , ee.eng_day_cnt_total
             , ee.total_learning_time_seconds
        from prod.core.fact_enrollment_engagement            ee
             left join prod.core.dim_courseruns              cr
                       on ee.courserun_key = cr.courserun_key
             join      selected_courses                      sc
                       on sc.course_id = cr.course_id
                           /*Filter for individuals that earnerd cert joining user_id, course_id from course completion table*/
             join      prod.core.dim_enrollments             de
                       on ee.user_id = de.user_id and ee.courserun_key = de.courserun_key
             left join prod.lms.grades_persistentcoursegrade g
                       on g.user_id = de.user_id
                           and g.course_id = de.courserun_key
        where g.passed_timestamp is not null
    )
/* Calculate summary statistics for each course_id */
   , approx_course_engagement as
    (
        select course_id
             , avg(eng_day_cnt_total)              as avg_days_active
             , stddev(eng_day_cnt_total)           as std_days_active
             , (avg_days_active - std_days_active) as adj_avg_days_active
             , avg(total_learning_time_seconds)    as avg_seconds
             , stddev(total_learning_time_seconds) as std_seconds
             , (avg_seconds - std_seconds)         as adj_avg_seconds
        from course_engagement
        group by course_id
        having adj_avg_seconds is not null
    )
   -- select * from approx_course_engagement;
/* Join tables together to approximate course difficulty, verfied enrollments, pass rate, and other relevant metrics. */
select dc.partner_key
     , dc.course_key
     , dc.course_date::date         as course_creation_date
     , dc.course_title
     , dc.level_type
     , md.short_description
     , cf.skills_array              as matched_skills
     , e.total_enrollments
     , e.verified_enrollments
     , e.verified_passes            as completions
     , ae.avg_days_active           as avg_days_active_to_complete
     , ae.avg_seconds / 60.0 / 60.0 as avg_hours_to_complete
from selected_courses                                cf
     left join prod.discovery.course_metadata_course md
               on cf.course_id = md.id
     left join prod.core.dim_courses                 dc
               on dc.course_id = cf.course_id
     left join enrollments                           e
               on cf.course_id = e.course_id
     left join approx_course_engagement              ae
               on ae.course_id = cf.course_id
order by course_creation_date desc
