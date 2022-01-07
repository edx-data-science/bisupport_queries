-- We are exploring a notification opportunity to upsell the program to users who are enrolled in courses and have completed the course but are not yet enrolled in the program itself.
-- We are considering two opportunity buckets.
-- 1. all past such course completions (time window past one quarter)
-- 2. all such course completions in any one week.
--
-- For these two buckets, we need data to validate our opportunity reach hypothesis. Please provide data for these two requests.
--
-- 1. Identify all user course enrollments in the past one quarter (i.e. last quarter of 2021) along with their is_active status and 'opt-in' status (opt-in status is a new status and is available in user properties) where the user meets all these criteria;
--
-- not an enterprise user.
-- user is enrolled in a course where the course is part of a program and the user is not enrolled in the program itself.
-- the program (which the course is part of) is active.
-- user has completed the course.
--
-- 2. Same as request 1 but for any 1-week duration (would be better if we do not consider holiday season weeks).
--
-- We might also need to extract this data frequently in the future, so it would be nice to get the query shared too as part of this request.

with marketing_opt_in as (
select user_id,name,value
from prod.lms.student_userattribute
where name = 'marketing_emails_opt_in'
    and value
    )

select * from (
                  select week_start_date as week_course_passed, count(distinct bic.user_id), 'Weekly Results' as Time_Slice
                  from prod.business_intelligence.bi_course_completion bic
                       inner join prod.core.program_courserun          pc
                                  on bic.courserun_id = pc.courserun_id
                       inner join prod.core.dim_enrollments            de
                                  on de.user_id = bic.user_id
                       inner join prod.core.dim_date                   dd
                                  on date(bic.passed_timestamp) = dd.date_column
                       inner join marketing_opt_in                     moi
                                  on bic.user_id = moi.user_id
                  where passed_timestamp is not null
                    and not de.is_enterprise_enrollment
                  group by week_start_date

                  union all

                  select quarter_start_date as quarter_course_passed, count(distinct bic.user_id), 'Quarterly Results'
                  from prod.business_intelligence.bi_course_completion bic
                       inner join prod.core.program_courserun          pc
                                  on bic.courserun_id = pc.courserun_id
                       inner join prod.core.dim_enrollments            de
                                  on de.user_id = bic.user_id
                       inner join prod.core.dim_date                   dd
                                  on date(bic.passed_timestamp) = dd.date_column
                       inner join marketing_opt_in                     moi
                                  on bic.user_id = moi.user_id
                  where passed_timestamp is not null
                    and not de.is_enterprise_enrollment
                  group by quarter_start_date
              )
order by time_slice
