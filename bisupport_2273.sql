-- This work is for the ticket here: https://openedx.atlassian.net/browse/BISUPPORT-2273

-- Alright, my workflow for this task was terrible, but it was very fast/easy
-- So, basically, Poornima wanted some data appended to a tableau report she downloaded
-- on the # of mobile enrollments associated with courseruns of interest.
-- I took the report and uploaded it into snowflake and then joined it to the relevant
-- tables of interest; then outputed again as a csv and then pasted it into her existing sheet

-- 1. I created a table to upload data into in snowflake
create or replace table user_data.thelbig.bisupport_2273 (
    courserun_key varchar(200),
    enrollments number not null
) 

-- 2. I then used the snowflake upload wizard to get the csv in (I just did the courserun_key and enrollments columns)

-- 3. Then, I joined up to mobile enrollment data of interest using the intermediate table of our active users data structure

with mobile_app_enrollments as (
    select
        courserun_key,
        count(distinct user_id) app_enrollment_count
    from
        prod.event_sources._intermediate_event_activity
    where
        is_app_enrollment
        and activity_day >= dateadd('month', -3, to_date('2021-05-12'))
        and activity_day < to_date('2021-05-12')
    group by
        courserun_key
)
select
    bi.*,
    coalesce(mobile_app_enrollments.app_enrollment_count, 0) app_enrollment_count_3months,
    dim_courseruns.pacing_type
from
    user_data.thelbig.bisupport_2273 as bi
    left join mobile_app_enrollments
        on bi.courserun_key = mobile_app_enrollments.courserun_key
    left join prod.core.dim_courseruns
        on bi.courserun_key = dim_courseruns.courserun_key

-- 4. Finally I outputted this as a csv, sorted by enrollments and slapped it back into her sheet.