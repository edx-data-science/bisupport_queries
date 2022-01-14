select level_type,course_title,course_key,course_date
from prod.core.dim_courses
where  lower(course_title) like '%chemistry%'
    or lower(course_title) like '%climate change%'
    or lower(course_title) like '%biochemistry%'
    or lower(course_title) like '%materials science%'
    or lower(course_title) like '%environmental science%'
    or lower(course_title) like '%physical chemistry%'
    or lower(course_title) like '%energy%'
    or lower(course_title) like '%electronics%'
    or lower(course_title) like '%thermodynamics%'