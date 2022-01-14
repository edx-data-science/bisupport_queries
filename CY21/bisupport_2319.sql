--Total number of enrolments for bangladesh
--745,585
select *
from "prod"."core"."dim_users" du
inner join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
where country_code = 'BD'
and last_location_country_code = 'BD'
and country_code_blended = 'BD'
-------------------------------------------------------
--Total number of enrolments for india
--15,510,402
select * 
from "prod"."core"."dim_users" du
inner join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
where country_code = 'IN'
and last_location_country_code = 'IN'
and country_code_blended = 'IN'
-------------------------------------------------------
--Enrolments by course for bangladesh
select dc.course_id, dc.course_title, dc.primary_subject_name, dc.level_type, dc.partner_key, count(distinct de.enrollment_id) as enrollments
from "prod"."core"."dim_users" du
join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
join "prod"."core"."dim_courseruns" dcr
on de.courserun_id=dcr.courserun_id
join "prod"."core"."dim_courses" dc
on dcr.course_id=dc.course_id
where country_code = 'BD'
and last_location_country_code = 'BD'
and country_code_blended = 'BD'
group by 1,2, 3, 4, 5
order by 6 desc
-------------------------------------------------------
--Enrolments by course for india
select dc.course_id, dc.course_title, dc.primary_subject_name, dc.level_type, dc.partner_key, count(distinct de.enrollment_id) as enrollments
from "prod"."core"."dim_users" du
join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
join "prod"."core"."dim_courseruns" dcr
on de.courserun_id=dcr.courserun_id
join "prod"."core"."dim_courses" dc
on dcr.course_id=dc.course_id
where country_code = 'IN'
and last_location_country_code = 'IN'
and country_code_blended = 'IN'
group by 1,2, 3, 4, 5
order by 6 desc
-------------------------------------------------------
--Enrolments by program for bangladesh
select program_id, program_title, program_status, program_type, count(distinct de.enrollment_id) as enrollments
from "prod"."core"."dim_users" du
join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
join "prod"."core"."dim_program" dp
on de.program_id_at_first_enrollment=dp.program_id
where country_code = 'BD'
and last_location_country_code = 'BD'
and country_code_blended = 'BD'
group by 1,2, 3, 4
order by 5 desc
-------------------------------------------------------
--Enrolments by program for india
select program_id, program_title, program_status, program_type, count(distinct de.enrollment_id) as enrollments
from "prod"."core"."dim_users" du
join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
join "prod"."core"."dim_program" dp
on de.program_id_at_first_enrollment=dp.program_id
where country_code = 'IN'
and last_location_country_code = 'IN'
and country_code_blended = 'IN'
group by 1,2, 3, 4
order by 5 desc
-------------------------------------------------------
--Enrolments by subject area for bangladesh
select primary_subject_name, count(distinct de.enrollment_id) as enrollments
from "prod"."core"."dim_users" du
join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
join "prod"."core"."dim_courseruns" dcr
on de.courserun_id=dcr.courserun_id
where country_code = 'BD'
and last_location_country_code = 'BD'
and country_code_blended = 'BD'
and primary_subject_name is not null
group by 1
order by 2 desc
--------------------------------------------------------
--Enrolments by subject area for india
select primary_subject_name, count(distinct de.enrollment_id) as enrollments
from "prod"."core"."dim_users" du
join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
join "prod"."core"."dim_courseruns" dcr
on de.courserun_id=dcr.courserun_id
where country_code = 'IN'
and last_location_country_code = 'IN'
and country_code_blended = 'IN'
and primary_subject_name is not null
group by 1
order by 2 desc
-------------------------------------------------------
--Enrolments by user Education Level for bangladesh
select education_level, count(distinct enrollment_id) as enrollments 
from "prod"."core"."dim_users" du
inner join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
where country_code = 'BD'
and last_location_country_code = 'BD'
and country_code_blended = 'BD'
group by 1
order by 2 desc
-------------------------------------------------------
--Enrolments by user Education Level for india
select education_level, count(distinct enrollment_id) as enrollments 
from "prod"."core"."dim_users" du
inner join "prod"."core"."dim_enrollments" de
on du.user_id=de.user_id
where country_code = 'IN'
and last_location_country_code = 'IN'
and country_code_blended = 'IN'
group by 1
order by 2 desc
