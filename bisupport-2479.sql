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




-------------------- by month data -------------------

with aws_data as (
select distinct to_varchar(first_enrollment_date, 'YYYY-MM') as enrollment_month
     , cr.courserun_key
     , de.user_id
     , de.first_enrollment_date
     , iff(enrollment_month = to_varchar(engagement.activity_date, 'YYYY-MM'), engagement.activity_date, null) activity_date
from prod.core.dim_courseruns cr
     join prod.core.dim_enrollments de
          on cr.courserun_key = de.courserun_key
     left join prod.business_intelligence.bi_activity_engagement_user_daily as engagement
          on engagement.user_id = de.user_id
             and engagement.courserun_key = de.courserun_key
             and engagement.activity_date >= de.first_enrollment_date
where cr.partner_key = 'AWS'
  and first_enrollment_date >= '2020-11-01'
//order by user_id
qualify row_number() over (partition by cr.courserun_key, de.user_id order by activity_date) = 1
)
select enrollment_month
     , courserun_key
     , count(first_enrollment_date) enrollments
     , count(activity_date) engagements
from aws_data
group by enrollment_month
       , courserun_key