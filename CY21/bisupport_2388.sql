
--1. how many users use the 'share via email' option in one day.
--2. how many courses does a single user 'share via email' in one day.
--3. If data exists, group the count of emails by email addresses with whom the course is shared.
--4. how many users, share the course to their own email address.

select date(load_time) as date,count(distinct user_id) as distinct_users
    ,count(distinct dc.course_key) as distinct_courses
    ,case when user_id is null then 'Anonymous User'
        else 'Known User' END as User_Known_Flag
from prod.segment_events.segment_events_with_metadata se
    left join prod.core.dim_courseruns dc on se.courserun_key = dc.courserun_key
where load_time>='2021-10-01'
    and event_name = 'edx.bi.course.socialshare.email'
    and (url like 'https://www.edx.org/es/course/%'
        or url like 'https://www.edx.org/webview/course/%'
        or url like 'https://www.edx.org/course/%')
group by date,user_known_flag
order by date,user_known_flag

-- determined 3 and 4 were likely impossible
