--https://openedx.atlassian.net/browse/BISUPPORT-2263
--We ran into an issue with the etext fee for one of the courses for IU. In the latest Q3 Revenue Share report and now looking at Q2, it looks like there were larger etext fees than were negotiated before my time. 
--According to the contract I have attached here, the fee should be $4 per learner. It looks to be more for both courses in this report and Q2. 
--The courses are: ('course-v1:IUx+IUMX-620+3T2020','course-v1:IUx+IUMX-621+1T2021')

use schema prod.financial_reporting;
					
select "course id"
       ,"cumulative paid enrollments"
       ,"cumulative # of refunds"
       ,"etextbook fees"
       ,("etextbook fees"-500)/"cumulative paid enrollments" as calculate_fee_per_enrollment --etextbook fees should be =<$4 , they are!
from finrep_royalty_order_report
where lower("course id")in ('course-v1:iux+iumx-620+3t2020'
                           ,'course-v1:iux+iumx-621+1t2021')

--***source data***********************************************************************
select  courserun_key, event_type, count(*), sum(amount)
from finrep_fee_courserun
where lower(courserun_key) in ('course-v1:iux+iumx-620+3t2020', 'course-v1:iux+iumx-621+1t2021')
  and event_type ilike  '%etextbook%'
group by courserun_key, EVENT_TYPE
;

select *
from prod.financial_reporting.finrep_policy_etextbook_fee;