select distinct au.email
    , au.first_name
    , au.last_name
    , enroll.user_id
    , enroll.current_mode
    , enroll.is_active
    , enroll.first_verified_date
    , enroll.first_unenrollment_date
    , enroll.courserun_key
    , pcr.program_title
    , iff(fb.is_redeemed is null, false, true) is_redeemed
from prod.core.program_courserun pcr
join prod.core.dim_enrollments enroll
     on pcr.courserun_id = enroll.courserun_id
left join prod.core.fact_booking fb
     on fb.enrollment_id = enroll.enrollment_id
join prod.lms_pii.auth_user as au
     on au.id = enroll.user_id
where lower(pcr.program_title) like 'international law'
    and pcr.program_type = 'MicroMasters'
    and pcr.partner_key = 'LouvainX'
    and not enroll.is_privileged_or_internal_user
    and enroll.current_mode = 'verified'
    and enroll.is_active
    and fb.is_redeemed is null
order by enroll.first_verified_date
    
