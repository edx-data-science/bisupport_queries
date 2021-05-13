-- We are trying to understand why no MM program learners have applied to the
-- UMD MBA.  Can someone please pull a list of all learners who have received
-- a course or program certificate for the MBA core curriculum program from UMD
-- and any info we have on them (country, age, education level, etc.).
-- Let me know if this is something I can pull myself or can request from someone
-- else. I am not sure what a reasonable due date is, so let me know if this is
-- too quick a turnaround.

select
       distinct du.user_id,du.country_label,du.education_level,du.gender,du.age_group
    --,au.email
from prod.business_intelligence.bi_user_course_certificate biuc
    left join prod.core.dim_courseruns dc on biuc.courserun_key = dc.courserun_key
    left join prod.core.program_courserun_all cc on dc.course_id = cc.course_id
    left join prod.core.dim_program dp on cc.program_id = dp.program_id
    left join prod.core.dim_users du on biuc.user_id = du.user_id
    left join prod.lms_pii.auth_user au on du.user_id = au.id
where 1=1
    and is_certified = 1
    and dp.program_title = 'MBA Core Curriculum' and cc.partner_key = 'UMD'


