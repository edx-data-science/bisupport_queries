/*select count(distinct case when fau.is_active_app_registration then fau.user_id else null end) as app_registration_user_count
     , count(distinct case when fau.is_active_app_search    then fau.user_id else null end) as app_search_user_count
     , count(distinct case when not fau.is_active_app_login and fau.is_active_app_search then fau.user_id else null end) as app_search_without_login_user_count
     , count(distinct case when fau.is_active_app_login     then fau.user_id else null end) as app_login_user_count
    ,count(distinct fau.user_id) as total_active_user_count
from prod.core_event_sources.fact_active_user_day fau
    inner join prod.core.fact_user_modality fum on fau.user_id = fum.user_id and fau.activity_day = fum.first_active_app_day
where fau.is_active_app
  and fum.is_active_app
  and fau.activity_day>='2021-07-01'

 */

-- What % of users in our app who install go through each of these 3 channels on app load:
-- 1. Search catalog (without signing in)
-- 2. Sign in
-- 3. Register
--
-- Looking at these 3 actions specifically only after first time app load (post install).

with events        as (
    select mobile_event_dotted_name, anonymous_id, user_id
    from segment_events.segment_events_with_metadata
    where mobile_event_tracking_name is not null
      and timestamp >= '2021-07-01'
      and mobile_event_dotted_name in ('edx.bi.app.discovery.courses_search', 'edx.bi.app.user.login', 'edx.bi.app.user.register.success')
)
   , user_id_flags as (
    select suss.session_mobile_os
         , suss.session_user_id
         , suss.anon_id
         , case when e.mobile_event_dotted_name = 'edx.bi.app.discovery.courses_search' then session_user_id
                else null end as searched
         , case when e.mobile_event_dotted_name = 'edx.bi.app.user.login' then session_user_id
                else null end as login
         , case when e.mobile_event_dotted_name = 'edx.bi.app.user.register.success' then session_user_id
                else null end as registered
         , case when session_user_id is null and mobile_event_dotted_name = 'edx.bi.app.discovery.courses_search' then anon_id
                else null end as searched_without_login
    from prod.core_event_sources.segment_user_session_summary suss
         left join events                                     e
                   on suss.anon_id = e.anonymous_id
    where suss.session_mobile_os in ('Android', 'iOS')
      and suss.session_start_time >= '2021-07-01'
      -- and session_user_id is null
        qualify 1 = row_number() over (partition by coalesce(cast(e.user_id as varchar), suss.anon_id) order by suss.session_start_time)
)
select session_mobile_os
    ,count(distinct session_user_id) as unique_user_count
    ,count(distinct session_user_id||anon_id) as unique_user_or_session_count
    ,count(distinct searched) as users_searching
    ,count(distinct login) as users_logged_in
    ,count(distinct registered) as users_registered
    ,count(distinct searched_without_login) as users_searching_without_login
from user_id_flags
group by session_mobile_os
/*
{
  "anonymousId": "E2FC7815-C2B5-4A26-879E-C563DD5FAE65",
  "channel": "server",
  "context": {
    "app": {
      "build": "2.23.0",
      "name": "edX",
      "namespace": "org.edx.mobile",
      "version": "2.23"
    },
    "device": {
      "adTrackingEnabled": true,
      "advertisingId": "1123F640-159B-488F-8F07-01139E0CE5F8",
      "id": "23C6297A-58BA-4AFB-AA17-4698E6C239DE",
      "manufacturer": "Apple",
      "model": "iPhone12,1",
      "type": "ios"
    },
    "ip": "41.66.209.96",
    "library": {
      "name": "analytics-ios",
      "version": "3.6.10"
    },
    "locale": "en-GH",
    "network": {
      "carrier": "Tigo",
      "cellular": false,
      "wifi": true
    },
    "os": {
      "name": "iOS",
      "version": "13.2.3"
    },
    "screen": {
      "height": 812,
      "width": 375
    },
    "timezone": "Africa/Accra",
    "traits": {
      "email": "nanakofisomuahboateng@gmail.com",
      "username": "Kofi_Boateng1fba"
    }
  },
  "event": "My Courses",
  "integrations": {
    "Firebase": false,
    "Google Analytics": false
  },
  "messageId": "1168ADD5-A9C3-49A4-A25C-6931A32A489E",
  "originalTimestamp": "2020-11-13T17:05:19.512Z",
  "projectId": "8x5bA9W4pN",
  "properties": {
    "category": "screen",
    "context": {
      "app_name": "edx.mobileapp.iOS"
    },
    "data": {
      "context": {
        "app_name": "edx.mobileapp.iOS"
      }
    },
    "device-orientation": "portrait",
    "label": "My Courses",
    "name": "edx.bi.app.navigation.screen",
    "user_id": 34806809
  },
  "receivedAt": "2020-11-13T17:05:53.785Z",
  "sentAt": "2020-11-13T17:05:49.510Z",
  "timestamp": "2020-11-13T17:05:23.787Z",
  "type": "track",
  "userId": "34806809",
  "version": 2,
  "writeKey": "yFfGhJUHDbqtQddnYnqsmoa1Kb9lGFcg"
}

*/