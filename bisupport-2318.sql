-- Query for first sheet
with batch_start_time as (select date_trunc('day', dateadd(day, -30, current_timestamp())) as start_time)
   , segment_events   as
    (
        select anonymous_id
             , user_id
             , timestamp
             , date(timestamp)                     as event_date
             , split_part(url, '?', 1)             as url
             , parse_url(referrer, 1):host::string as referrer
        from prod.segment_events.segment_events_with_metadata
        where datediff(sec, timestamp, load_time::timestamp_tz) >= -1800
          and load_time::timestamp_tz >= (select start_time from batch_start_time)
          and timestamp >= (select start_time from batch_start_time)
          and anonymous_id is not null
    )
   , anon_ids_with_user_ids as
    (
        select events.anonymous_id
             , first_value(try_cast(s.session_user_id as integer) ignore nulls)
               over (partition by s.anon_id order by session_date) as user_id
        from (select distinct anonymous_id
              from segment_events) events
        left join prod.core_event_sources.segment_user_session_summary s
                  on events.anonymous_id = s.anon_id
        qualify row_number() over (partition by events.anonymous_id order by session_date) = 1
    )
   , segment_events_with_user_ids as
    (
        select e.*
             , ids.user_id as first_user_id
        from segment_events e
             left join anon_ids_with_user_ids ids
                       on e.anonymous_id = ids.anonymous_id
    )
   , new_users_by_day as
    (
        select event_date
             , count(distinct anonymous_id) as new_anonymous_user_count
        from segment_events_with_user_ids
        where first_user_id is null
        group by event_date
    )
   , signed_out_users_by_day as
    (
        select event_date
             , count(distinct anonymous_id) as signed_out_anonymous_user_count
        from segment_events_with_user_ids
        where first_user_id is not null
        group by event_date
    )
   , anon_user_by_day as
   (
       select event_date
            , count(distinct anonymous_id) as anonymous_user_count
       from segment_events_with_user_ids
       group by event_date
   )
select anon.event_date
     , anon.anonymous_user_count
     , new_anon.new_anonymous_user_count
     , signed_out.signed_out_anonymous_user_count
     , new_anon.new_anonymous_user_count+signed_out.signed_out_anonymous_user_count as aa
     , (new_anon.new_anonymous_user_count+signed_out.signed_out_anonymous_user_count) = anon.anonymous_user_count as ab
from anon_user_by_day as anon
     join new_users_by_day as new_anon
          on anon.event_date = new_anon.event_date
     join signed_out_users_by_day as signed_out
          on anon.event_date = signed_out.event_date
order by anon.event_date;

-- Query for second sheet
with batch_start_time           as (select date_trunc('day', dateadd(day, -30, current_timestamp())) as min_load_time)
   , segment_events             as
   (
       select anonymous_id
            , date(timestamp)                     as event_date
            , split_part(url, '?', 1)             as url
            , parse_url(referrer, 1):host::string as referrer
        from prod.segment_events.segment_events_with_metadata
        where datediff(sec, timestamp, load_time::timestamp_tz) >= -1800
          and load_time::timestamp_tz >= (select min_load_time from batch_start_time)
          and timestamp >= (select min_load_time from batch_start_time)
          and user_id is null
          and anonymous_id is not null
   )
   , top_referrers as
   (
       select referrer
            , count(referrer) as referrer_count
       from segment_events 
       where referrer is not null
         and referrer not like '%edx%'
       group by referrer
       having count(referrer) > 100
       order by referrer_count desc
   )

select * from top_referrers;

-- Query for third sheet
   with batch_start_time           as (select date_trunc('day', dateadd(day, -30, current_timestamp())) as min_load_time)
   , segment_events             as
   (
       select anonymous_id
            , date(timestamp)                     as event_date
            , split_part(url, '?', 1)             as url
            , parse_url(referrer, 1):host::string as referrer
        from prod.segment_events.segment_events_with_metadata
        where datediff(sec, timestamp, load_time::timestamp_tz) >= -1800
          and load_time::timestamp_tz >= (select min_load_time from batch_start_time)
          and timestamp >= (select min_load_time from batch_start_time)
          and user_id is null
          and anonymous_id is not null
   )
   , top_url_visits as
   (
       select url
            , count(url) as url_count
       from segment_events 
       where url is not null
         and url not like '%courses.edx.org/xblock/block-v1%'
       group by url
       having count(url) > 1000
       order by url_count desc
   )

select * from top_url_visits