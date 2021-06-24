-- Query for first sheet
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
   , anon_user_by_day as
   (
       select event_date
            , count(distinct anonymous_id) as anonymous_user_count
       from segment_events
       group by event_date
   )

select * from anon_user_by_day;

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
       group by url
       having count(url) > 1000
       order by url_count desc
   )

select * from top_url_visits