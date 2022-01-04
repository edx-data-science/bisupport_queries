select count(distinct case when fau.is_active_app_registration then fau.user_id else null end) as app_registration_user_count
     , count(distinct case when fau.is_active_app_search    then fau.user_id else null end) as app_search_user_count
     , count(distinct case when not fau.is_active_app_login and fau.is_active_app_search then fau.user_id else null end) as app_search_without_login_user_count
     , count(distinct case when fau.is_active_app_login     then fau.user_id else null end) as app_login_user_count
    ,count(distinct fau.user_id) as total_active_user_count
from prod.core_event_sources.fact_active_user_day fau
    inner join prod.core.fact_user_modality fum on fau.user_id = fum.user_id and fau.activity_day = fum.first_active_app_day
where fau.is_active_app
  and fum.is_active_app
  and fau.activity_day>='2021-07-01'