<<<<<<< Updated upstream
--pre-covid IBM vtr, chose a three-month window aug-sep to avoid holidays
--result was just under 1% (0.0091)
=======
--pre-covid ibm course vtr
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
  and metric_date between '2019-08-01' and '2019-10-31'
group by metric_date, course_key, partner_key, verified_count
  )

select sum(verified)/ sum(enrolled) as pre_covid_vtr
from pre_covid

--ran vtr for the same 3-month window post credly launch
--vtr increased to ~1.5% (0.0147)
=======
  and metric_date between '2019-05-01' and '2019-11-15' --dates adjusted to larger window to ensure enrollment sample size matched credly test sample size
  and course_key not in ('IBM+BD0225EN','IBM+BD0231EN','IBM+CD0116EN','IBM+CD0351EN','IBM+DA0151EN','IBM+DB0111EN',
                        'IBM+DB0151EN','IBM+DB0231EN','IBM+DB0250EN','IBM+DB260EN','IBM+DB321EN','IBM+DV0151EN','IBM+ESME36G',
                        'IBM+ESX9EG','IBM+EZ52EG','IBM+EZP05EG','IBM+IBMICECPP01','IBM+IBMICECPP02','IBM+IBMICECPP03','IBM+IBMPSRE1',
                        'IBM+IBMPSRE2','IBM+IBMPSRE3','IBM+LX0117EN','IBM+PYTEST','IBM+QZE32DG','IBM+QZE33DG','IBM+RP0101EN','IBM+RP0203EN',
                        'IBM+RP0321EN','IBM+ST0151EN','IBM+Test_101')
group by metric_date, course_key, partner_key, verified_count
  )

select
sum(enrolled) as pre_covid_ibm_enrolled,
sum(verified) as pre_covid_ibm_verified,
sum(verified)/ sum(enrolled) as pre_covid_ibm_vtr
from pre_covid

--resulting vtr ~1%

--post-credly ibm vtr avoiding launch marketing bump
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
  and metric_date between '2021-08-01' and '2021-10-31'
group by metric_date, course_key, partner_key, verified_count
  )

select sum(verified)/sum(enrolled) as post_credly_vtr_fall_21fall
from post_credly_fall_21

--checked against vtr for all months after full credly launch
--vtr slightly higher (0.0152) so there was a marketing bump but slight
=======
  and metric_date between '2021-08-01' and '2021-10-31' --three-month window that avoids the potential launch marketing bump
  and course_key not in ('IBM+BD0225EN','IBM+BD0231EN','IBM+CD0116EN','IBM+CD0351EN','IBM+DA0151EN','IBM+DB0111EN',
                        'IBM+DB0151EN','IBM+DB0231EN','IBM+DB0250EN','IBM+DB260EN','IBM+DB321EN','IBM+DV0151EN','IBM+ESME36G',
                        'IBM+ESX9EG','IBM+EZ52EG','IBM+EZP05EG','IBM+IBMICECPP01','IBM+IBMICECPP02','IBM+IBMICECPP03','IBM+IBMPSRE1',
                        'IBM+IBMPSRE2','IBM+IBMPSRE3','IBM+LX0117EN','IBM+PYTEST','IBM+QZE32DG','IBM+QZE33DG','IBM+RP0101EN','IBM+RP0203EN',
                        'IBM+RP0321EN','IBM+ST0151EN','IBM+Test_101')
group by metric_date, course_key, partner_key, verified_count
  )

select
sum(enrolled) as post_credly_enrolled_fall21,
sum(verified) as post_credly_verified_fall21,
sum(verified)/sum(enrolled) as post_credly_vtr_fall21
from post_credly_fall_21

--resulting vtr ~1.4%

--post-credly vtr including launch marketing bump
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
group by metric_date, course_key, partner_key, verified_count
  )

select sum(verified)/sum(enrolled) as post_credly_vtr_all
from post_credly_all

--checked vtr all-time for edx, slightly higher but similar to pre-credly
--just about 1%(0.0095)
=======
  and course_key not in ('IBM+BD0225EN','IBM+BD0231EN','IBM+CD0116EN','IBM+CD0351EN','IBM+DA0151EN','IBM+DB0111EN',
                        'IBM+DB0151EN','IBM+DB0231EN','IBM+DB0250EN','IBM+DB260EN','IBM+DB321EN','IBM+DV0151EN','IBM+ESME36G',
                        'IBM+ESX9EG','IBM+EZ52EG','IBM+EZP05EG','IBM+IBMICECPP01','IBM+IBMICECPP02','IBM+IBMICECPP03','IBM+IBMPSRE1',
                        'IBM+IBMPSRE2','IBM+IBMPSRE3','IBM+LX0117EN','IBM+PYTEST','IBM+QZE32DG','IBM+QZE33DG','IBM+RP0101EN','IBM+RP0203EN',
                        'IBM+RP0321EN','IBM+ST0151EN','IBM+Test_101')
group by metric_date, course_key, partner_key, verified_count
  )

select
sum(enrolled) as post_credly_enrolled_all,
sum(verified) as post_credly_verified_all,
sum(verified)/sum(enrolled) as post_credly_vtr_all
from post_credly_all

--resulting vtr ~1.5%

--edx vtr
>>>>>>> Stashed changes

with edx_all as (
  select coalesce(verified_count,0) as verified,
       sum(enrollment_count) as enrolled,
       metric_date,
       course_key,
       partner_key

from tableau_fact_b2c_funnel

join dim_courseruns
on tableau_fact_b2c_funnel.courserun_id = dim_courseruns.courserun_id
<<<<<<< Updated upstream
group by metric_date, course_key, partner_key, verified_count
  )

select sum(verified)/sum(enrolled) as edx_vtr
from edx_all

=======
 where metric_date between '2021-06-17' and '2022-01-20'
group by metric_date, course_key, partner_key, verified_count
  )

select
sum(enrolled) as edx_enrolled,
sum(verified) as edx_verified,
sum(verified)/sum(enrolled) as edx_vtr
from edx_all

--the edx vtr when run for dates matching the ibm test are 0.013 (aug-oct 2019), 0.0149 (aug-oct 2021), 0.0147 (june 17-jan 20)
--for pre-covid/pre-credly ibm (aug-oct 2019), the vtr is 0.009, for post-credly (aug-oct 2021) vtr is 0.0143,
--for all post-credly (june 17-jan 20) vtr is 0.0148
--conclusion: pre-credly, ibm courses had lower vtr than the general edx catalogue. credly did increase vtr by about 50% (from ~1% to ~1.5%)
>>>>>>> Stashed changes
