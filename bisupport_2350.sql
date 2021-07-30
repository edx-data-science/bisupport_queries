--BISUPPORT-2350
--count of people who during this time frame were unable to checkout
--403 users
with users_impacted as (
select distinct user_id from prod.segment_events.segment_events_with_metadata a
where event_name = 'edx.bi.ecommerce.payment_mfe.order_summary_rendered'
and timestamp >= '2021-07-28 18:35:00.00 +0000' and timestamp <= '2021-07-28 20:11:00.00 +0000'
and not exists (select user_id from prod.segment_events.segment_events_with_metadata b
where a.user_id = b.user_id and event_name = 'Order Completed'
and timestamp >= '2021-07-28 18:35:00.00 +0000' and timestamp <= '2021-07-28 20:11:00.00 +0000')
)
--count of people who were unable to checkout during downtime and have still not checked out
--354 users
select ui.user_id,cpu.email, iff(lms_user_id is not null, true, false) as is_enterprise_user
from users_impacted ui
left join prod.core_pii.corepii_user_profile cpu
on ui.user_id=cpu.user_id
left join (select distinct lms_user_id from prod.ENTERPRISE.ENT_BASE_ENTERPRISE_USER where is_linked = 1) eb
on ui.user_id = eb.lms_user_id
where not exists (select distinct user_id from prod.segment_events.segment_events_with_metadata se where ui.user_id = se.user_id and event_name = 'Order Completed'
                 and timestamp > '2021-07-28 20:11:00.00 +0000')
