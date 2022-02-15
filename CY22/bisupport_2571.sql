--request from stanford online for report of currently available courses with start/end dates, public url, and edx studio url
--code can be used for similar requests from other partners
--public url = https://www.edx.org/[[url_slug]]
--edx studio url = https://studio.edx.org/course/[[courserun_key]]

select course_title
     , start_datetime
     , end_datetime
     , url_slug      as public_url
     , courserun_key as edx_studio_url
from dim_courseruns
     join core_imd_course_metadata
          on dim_courseruns.course_id = core_imd_course_metadata.course_id
              and dim_courseruns.course_key = core_imd_course_metadata.course_key
where partner_key like '%Stanford%'
  and is_suspected_test_draft_courserun = 'FALSE'

