select distinct au.email, fb.user_id, au.username, co.course_key, co.course_title, fb.booking_date, pc.program_title, pc.program_type
from prod.core.fact_booking fb
    inner join prod.core.dim_courses co on fb.course_key=co.course_key
    inner join prod.lms_pii.auth_user au on fb.user_id=au.id
    inner join prod.core.dim_program pc on pc.program_id = fb.program_id
where fb.order_product_class = 'course-entitlement'
    and not is_redeemed
    and fb.program_id = 55
order by 1,2,3,4,5,6