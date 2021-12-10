select au.email
     , cr.course_key
     , cr.courserun_key
	 , min(engage.first_engagement_date) as first_engagement_date
	 , max(engage.last_engagement_date) as last_engagement_date
	 , sum(engage.eng_day_cnt_total) as engagement_days_count_total
from prod.core.dim_courseruns as cr
join prod.core.fact_enrollment_engagement as engage
     on engage.courserun_key = cr.courserun_key
join prod.lms_pii.auth_user as au
     on au.id = engage.user_id
where cr.partner_key = 'AWS'
  and engage.engagement_anchor_date >= dateadd(year, -1, current_timestamp())
  and engage.eng_day_cnt_total != 0
group by au.email
       , cr.course_key
       , cr.courserun_key
order by email