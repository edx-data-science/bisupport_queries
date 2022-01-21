--pre-covid IBM vtr, chose a three-month window aug-sep to avoid holidays
--result was just under 1% (0.0091)

with pre_covid as (
  select coalesce(verified_count,0) as verified,
       sum(enrollment_count) as enrolled,
       metric_date,
       course_key,
       partner_key

from tableau_fact_b2c_funnel

join dim_courseruns
on tableau_fact_b2c_funnel.courserun_id = dim_courseruns.courserun_id
where partner_key like 'IBM%'
  and metric_date between '2019-08-01' and '2019-10-31'
group by metric_date, course_key, partner_key, verified_count
  )

select sum(verified)/ sum(enrolled) as pre_covid_vtr
from pre_covid

--ran vtr for the same 3-month window post credly launch
--vtr increased to ~1.5% (0.0147)

with post_credly_fall_21 as (
  select coalesce(verified_count,0) as verified,
       sum(enrollment_count) as enrolled,
       metric_date,
       course_key,
       partner_key

from tableau_fact_b2c_funnel

join dim_courseruns
on tableau_fact_b2c_funnel.courserun_id = dim_courseruns.courserun_id
where partner_key like 'IBM%'
  and metric_date between '2021-08-01' and '2021-10-31'
group by metric_date, course_key, partner_key, verified_count
  )

select sum(verified)/sum(enrolled) as post_credly_vtr_fall_21fall
from post_credly_fall_21

--checked against vtr for all months after full credly launch
--vtr slightly higher (0.0152) so there was a marketing bump but slight

with post_credly_all as (
  select coalesce(verified_count,0) as verified,
       sum(enrollment_count) as enrolled,
       metric_date,
       course_key,
       partner_key

from tableau_fact_b2c_funnel

join dim_courseruns
on tableau_fact_b2c_funnel.courserun_id = dim_courseruns.courserun_id
where partner_key like 'IBM%'
  and metric_date between '2021-06-17' and '2022-01-20'
group by metric_date, course_key, partner_key, verified_count
  )

select sum(verified)/sum(enrolled) as post_credly_vtr_all
from post_credly_all

--checked vtr all-time for edx, slightly higher but similar to pre-credly
--just about 1%(0.0095)

with edx_all as (
  select coalesce(verified_count,0) as verified,
       sum(enrollment_count) as enrolled,
       metric_date,
       course_key,
       partner_key

from tableau_fact_b2c_funnel

join dim_courseruns
on tableau_fact_b2c_funnel.courserun_id = dim_courseruns.courserun_id
group by metric_date, course_key, partner_key, verified_count
  )

select sum(verified)/sum(enrolled) as edx_vtr
from edx_all

