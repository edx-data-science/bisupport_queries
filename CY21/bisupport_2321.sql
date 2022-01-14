--fix weeks to complete to comply with fbe
with weeks_to_complete as (
select *
      , case when weeks_to_complete < 4 then 4
             when weeks_to_complete > 18 then 18
             else weeks_to_complete
        end as new_weeks_to_complete
from prod.core.dim_courseruns
--where weeks_to_complete is not null
), rank_courseruns as (
select *, row_number() over (partition by course_id order by change_date, changed_by_id) as rank_course_id
from PROD.LMS.COURSE_DURATION_LIMITS_COURSEDURATIONLIMITCONFIG
where course_id is not null
), add_end_dates as (
select *, lag(enabled_as_of,-1) over (partition by course_id order by rank_course_id) as new_end_date
        , lead(course_id) over (partition by course_id order by rank_course_id) is null as is_last_row
from rank_courseruns
), nulls_to_current_date as (
select * , iff(new_end_date is null, current_date(), new_end_date) as enable_end_date
         , iff(enabled_as_of is null,'2020-12-31',enabled_as_of) as enable_start_date
from add_end_dates ad
--most of the last rows were all changed prior to 2021, so all enrollments in Q12021 should only
--be impacted by latest changes and everything that happened prior does not matter
--the few that were changed during 2021 were first entries, so the code below should accounts for them properly
--course-v1:UTAustinX+UT.P4C.14.01x+2T2020, course-v1:UTAustinX+UT.PHP.16.01x+2T2020, course-v1:UTAustinX+UT.ALA+2T2020
where not enabled and is_last_row
)
, audit_learners as (
--find learners who enrolled as audit first quarter 2021
select de.*, wc.course_key, wc.partner_key, wc.weeks_to_complete, dateadd(week,wc.new_weeks_to_complete,greatest(de.first_enrollment_date,wc.start_datetime)) as audit_access_end_date
from prod.core.dim_enrollments de
left join weeks_to_complete wc
on de.courserun_key = wc.courserun_key
--pull only those learners who were first audit and then either verified later or never verified
where (de.first_enrollment_date != de.first_verified_date or first_verified_date is null)
and first_enrollment_date between '2021-01-01' and '2021-03-31'
--all the learners have to have had their access expire
and audit_access_end_date < '2021-06-01'
), combine_audit_fbe_courserun as (
--this will tie all the non fbe course runs to enrollments
select al.*
from audit_learners al
join nulls_to_current_date nd
on lower(nd.course_id)=lower(al.courserun_key)
and al.audit_access_end_date between enable_start_date and enable_end_date
),
--------------------------------------------------------------------------
rank_courses as (
select *, row_number() over (partition by org_course order by change_date, changed_by_id) as rank_course
from PROD.LMS.COURSE_DURATION_LIMITS_COURSEDURATIONLIMITCONFIG
where course_id is null and org_course is not null
), add_end_dates_courses as (
select *, lag(enabled_as_of,-1) over (partition by org_course order by rank_course) as new_end_date
        , lead(org_course) over (partition by org_course order by rank_course) is null as is_last_row
from rank_courses
), nulls_to_current_date_courses as (
select * , iff(new_end_date is null, current_date(), new_end_date) as enable_end_date
         , iff(enabled_as_of is null,'2020-12-31',enabled_as_of) as enable_start_date
from add_end_dates_courses
where not enabled and is_last_row
), combine_audit_fbe_course as (
--this will tie all the fbe course runs to enrollments
select al.*
from audit_learners al
join nulls_to_current_date_courses nd
on lower(nd.org_course)=lower(al.course_key)
and al.audit_access_end_date between enable_start_date and enable_end_date
),
-------------------------------------------------------
rank_orgs as (
select *, row_number() over (partition by org order by change_date, changed_by_id) as rank_orgs
from PROD.LMS.COURSE_DURATION_LIMITS_COURSEDURATIONLIMITCONFIG
where course_id is null and org_course is null and org is not null
), add_end_dates_orgs as (
select *, lag(enabled_as_of,-1) over (partition by org order by rank_orgs) as new_end_date
        , lead(org) over (partition by org order by rank_orgs) is null as is_last_row
from rank_orgs
), nulls_to_current_date_orgs as (
select * , iff(new_end_date is null, current_date(), new_end_date) as enable_end_date
         , iff(enabled_as_of is null,'2020-12-31',enabled_as_of) as enable_start_date
from add_end_dates_orgs
--all rows changed prior to 2021, so this filter works accordingly
where not enabled and is_last_row
), combine_audit_fbe_org as (
--this will tie all the fbe course runs to enrollments
select al.*
from audit_learners al
join nulls_to_current_date_orgs nd
on lower(nd.org)=lower(al.partner_key)
and al.audit_access_end_date between enable_start_date and enable_end_date
)
-----------
select count(distinct enrollment_id)
from audit_learners al
where not exists (select * from combine_audit_fbe_org a where al.enrollment_id=a.enrollment_id)
and not exists (select * from combine_audit_fbe_course b where al.enrollment_id=b.enrollment_id)
and not exists (select * from combine_audit_fbe_courserun c where al.enrollment_id=c.enrollment_id)
and first_verified_date is not null and first_verified_date > audit_access_end_date
