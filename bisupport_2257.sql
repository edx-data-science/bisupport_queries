-- This work is for this ticket: https://openedx.atlassian.net/browse/BISUPPORT-2257

--- I want to pull a clean set of enrolls to use for this analysis

create or replace table user_data.thelbig.bisupport_2257 as 
with clean_enrollments as (
    select
        ee.user_id,
        ee.courserun_key,
        to_date(de.first_enrollment_date) as enrollment_day,
        de.first_enrollment_date,
        ee.engagement_anchor_date as content_anchor_date,
        ee.courserun_start_date,
        de.first_enrollment_date = ee.engagement_anchor_date as had_access_on_enroll,
        de.first_verified_date,
        ee.late_enrollment_yn,
        rank() over (partition by ee.user_id, enrollment_day order by de.first_enrollment_date) enrollment_day_order,
        dc.primary_subject_name,
        dc.pacing_type,
        lag(primary_subject_name) over (partition by ee.user_id, enrollment_day order by de.first_enrollment_date) prev_primary_subject
    from
        prod.core.fact_enrollment_engagement as ee
        join prod.core.dim_enrollments as de
            on ee.user_id = de.user_id
            and ee.courserun_key = de.courserun_key
        join prod.core.dim_courseruns as dc
            on ee.courserun_key = dc.courserun_key
    where
        not de.is_privileged_or_internal_user -- get rid of privileged or internal users
        and not de.is_enterprise_enrollment -- eliminate b2b enrollments
        and dc.reporting_type not in ('demo', 'test') -- get rid of demo/test courseruns
        and not dc.is_whitelabel -- no whitelabel courseruns
        and not dc.partner_key = 'edX' -- no internal edx courses
        and de.first_enrollment_date >= to_date('2020-01-01')
        and de.first_enrollment_date < to_date('2021-01-01')
        and courserun_type_slug in ('verified-audit', 'credit-verified-audit', 'masters-verified-audit')
)
select * from clean_enrollments

select count(*) from user_data.thelbig.bisupport_2257

-- Alright actual analysis time

-- 1. Shared enrollments

-- Very simple, how many enrolls do people typically have on one day average and median

with user_day_enrollment_counts as (
    select
        enrollment_day,
        user_id,
        min(case when enrollment_day_order = 2 then primary_subject_name else null end) second_subject,
        min(case when enrollment_day_order = 2 then prev_primary_subject else null end) first_subject,
        count(*) enroll_count
    from
        user_data.thelbig.bisupport_2257
    group by
        enrollment_day,
        user_id
)
select
    avg(enroll_count) avg_daily_enroll_count,
    median(enroll_count) avg_daily_enroll_count
from
    user_day_enrollment_counts

-- Let me divide it up into some small categories

with user_day_enrollment_counts as (
    select
        enrollment_day,
        user_id,
        min(case when enrollment_day_order = 2 then primary_subject_name else null end) second_subject,
        min(case when enrollment_day_order = 2 then prev_primary_subject else null end) first_subject,
        count(*) enroll_count
    from
        user_data.thelbig.bisupport_2257
    group by
        enrollment_day,
        user_id
)
select
    case
        when enroll_count = 1
        then '1 Enroll'
        when enroll_count = 2
        then '2 Enrolls'
        when enroll_count = 3
        then '3 Enrolls'
        when enroll_count = 4
        then '4 Enrolls'
        else '5+ Enrolls'
    end enroll_category,
    count(*) user_day_count,
    round(user_day_count / sum(user_day_count) over (), 4) prop_user_days
from
    user_day_enrollment_counts
group by
    1
order by
    1

-- What % of second enrolls are the same subject as a first

with user_day_enrollment_counts as (
    select
        enrollment_day,
        user_id,
        min(case when enrollment_day_order = 2 then primary_subject_name else null end) second_subject,
        min(case when enrollment_day_order = 2 then prev_primary_subject else null end) first_subject,
        count(*) enroll_count
    from
        user_data.thelbig.bisupport_2257
    group by
        enrollment_day,
        user_id
)
select
    second_subject = first_subject as subjects_match,
    count(*) total_second_enrollments,
    round(total_second_enrollments / sum(total_second_enrollments) over (), 4) prop_second_enrolls
from
    user_day_enrollment_counts
where
    second_subject is not null
    and first_subject is not null
group by 
    1

-- Ok, so this says 44% match

-- I need to see what the baseline we would expect for picking 2 random enrollments would be; I'll limit to the first 2 enrolls for sanity's sake

with subject_enrollment_counts as (
    select
        primary_subject_name,
        count(*) enroll_count,
        enroll_count / sum(enroll_count) over () as prop_subject
    from
        user_data.thelbig.bisupport_2257
    where
        enrollment_day_order in (1, 2)
    group by
        primary_subject_name
)
select
    round(sum(prop_subject * prop_subject), 4) background_subject_match_rate 
from
    subject_enrollment_counts

-- Oh wow! This is saying if we pick 2 enrollments at random we only expect them to have the same subject ~13% of the time 


-- 2. About page views

-- data limited, will skip for now

-- 3. When do people enroll relative to start?

-- Let's limit to enrollments in courseruns where the start date is after 8 weeks from the start of 2020 and before 8 weeks from the start of 2021
-- Maybe a sanity check to see how many enrolls this is? I can expand the range of enroll data we're looking at if I need to

with enroll_relative_week as (
    select
        user_id,
        courserun_key,
        pacing_type,
        floor(datediff('day', courserun_start_date, first_enrollment_date) / 7.0) relative_enroll_week
    from
        user_data.thelbig.bisupport_2257
    where
        courserun_start_date >= dateadd('week', 8, to_date('2020-01-01'))
        and courserun_start_date < dateadd('week', -8, to_date('2021-01-01'))
)
select
    relative_enroll_week,
    iff(pacing_type = 'instructor_paced', 'Instructor-Paced', 'Self-Paced') as pacing_type,
    count(*) week_enroll_count,
    round(week_enroll_count / sum(week_enroll_count) over (partition by pacing_type), 4) prop_enroll_count
from
    enroll_relative_week
where
    relative_enroll_week between -8 and 8
group by
    relative_enroll_week,
    pacing_type
order by
    2, 1


-- 4. Purchase behavior 

-- Let's look at the same time as enroll, w/in 1 min, 10 mins, 1 hour, 1 day, 7 days, and 28 days

select 
    had_access_on_enroll,
    count(*) total_verifiers,
    round(sum(iff(first_enrollment_date = first_verified_date, 1, 0)) / total_verifiers, 4) as prop_verifiers_on_enroll,
    round(sum(iff(datediff('minute', first_enrollment_date, first_verified_date) <= 1, 1, 0)) / total_verifiers, 4) as prop_verifiers_1min,
    round(sum(iff(datediff('minute', first_enrollment_date, first_verified_date) <= 10, 1, 0)) / total_verifiers, 4) as prop_verifiers_10min, 
    round(sum(iff(datediff('minute', first_enrollment_date, first_verified_date) <= 60, 1, 0)) / total_verifiers, 4) as prop_verifiers_1h,
    round(sum(iff(datediff('hour', first_enrollment_date, first_verified_date) <= 24, 1, 0)) / total_verifiers, 4) as prop_verifiers_1d,
    round(sum(iff(datediff('hour', first_enrollment_date, first_verified_date) <= 24*7, 1, 0)) / total_verifiers, 4) as prop_verifiers_7d,
    round(sum(iff(datediff('hour', first_enrollment_date, first_verified_date) <= 24*28, 1, 0)) / total_verifiers, 4) as prop_verifiers_28d
from
    user_data.thelbig.bisupport_2257
where
    first_verified_date is not null
group by
    1

-------------------------------------------------------------------------

-- Crude About page/Enrollment exploration

with course_about_page_views as (
    select
        timestamp,
        user_id,
        parse_url(url_non_null):path clean_url_path
    from
        prod.event_sources._intermediate_event_activity
    where
        activity_day >= to_date('2020-12-31')
        and activity_day < to_date('2021-02-01')
        and is_desktop_os
        and (
            (REGEXP_LIKE(url_non_null, '.*www.edx.org/course/.+') and not REGEXP_LIKE(url_non_null, '.*www.edx.org/course/subject.+'))
        )
),
enrollments as (
    select
        timestamp,
        user_id,
        courserun_key,
        lag(timestamp) over (partition by user_id order by timestamp) previous_enrollment_timestamp
    from
        prod.event_sources._intermediate_event_activity
    where
        activity_day >= to_date('2020-12-31')
        and activity_day < to_date('2021-02-01')
        and is_desktop_os
        and is_web_enrollment
), enrollment_about_views as (
    select
        enrollments.timestamp,
        enrollments.user_id,
        enrollments.courserun_key,
        count(distinct course_about_page_views.clean_url_path) distinct_about_page_views
    from
        enrollments
        left join course_about_page_views
            on enrollments.user_id = course_about_page_views.user_id
            and course_about_page_views.timestamp < enrollments.timestamp
            and course_about_page_views.timestamp > greatest(coalesce(enrollments.previous_enrollment_timestamp, dateadd('hour', -24, enrollments.timestamp)), dateadd('hour', -24, enrollments.timestamp))
    group by
        enrollments.timestamp,
        enrollments.user_id,
        enrollments.courserun_key
)
select
    distinct_about_page_views,
    count(*) view_count,
    round(view_count / sum(view_count) over (), 4) 
from
    enrollment_about_views
group by
    distinct_about_page_views
order by
    2 desc


--------- Let's find examples of 0 view enrolls

with course_about_page_views as (
    select
        timestamp,
        user_id,
        parse_url(url_non_null):path clean_url_path
    from
        prod.event_sources._intermediate_event_activity
    where
        activity_day >= to_date('2020-12-31')
        and activity_day < to_date('2021-02-01')
        and is_desktop_os
        and (
            (REGEXP_LIKE(url_non_null, '.*www.edx.org/course/.+') and not REGEXP_LIKE(url_non_null, '.*www.edx.org/course/subject.+'))
        )
),
enrollments as (
    select
        timestamp,
        user_id,
        courserun_key,
        lag(timestamp) over (partition by user_id order by timestamp) previous_enrollment_timestamp
    from
        prod.event_sources._intermediate_event_activity
    where
        activity_day >= to_date('2020-12-31')
        and activity_day < to_date('2021-02-01')
        and is_desktop_os
        and is_web_enrollment
), enrollment_about_views as (
    select
        enrollments.timestamp,
        enrollments.user_id,
        enrollments.courserun_key,
        count(distinct course_about_page_views.clean_url_path) distinct_about_page_views
    from
        enrollments
        left join course_about_page_views
            on enrollments.user_id = course_about_page_views.user_id
            and course_about_page_views.timestamp < enrollments.timestamp
            and course_about_page_views.timestamp > greatest(coalesce(enrollments.previous_enrollment_timestamp, dateadd('hour', -24, enrollments.timestamp)), dateadd('hour', -24, enrollments.timestamp))
    group by
        enrollments.timestamp,
        enrollments.user_id,
        enrollments.courserun_key
)
select
    *
from
    enrollment_about_views
where
    distinct_about_page_views = 0
limit 100;

-- New Examples of 0: 
-- 39011354, course-v1:HarvardX+MCB80.1x+2T2020, 2021-01-12 13:50:23.
-- 39148212, course-v1:GTx+CS1301xI+1T2021, 2021-01-18 20:00:03
-- 39382069, course-v1:IIMBx+FC250x+2T2020, 2021-01-26 21:19:46

select
    *
from
    prod.event_sources._intermediate_event_activity
where
    user_id = 39011354
    and activity_day = to_date('2021-01-12')
order by timestamp


select 
    * 
from 
    prod.segment_events.segment_events_with_metadata 
where
    user_id = 39011354
    and to_date(timestamp) = to_date('2021-01-12')
order by
    timestamp



