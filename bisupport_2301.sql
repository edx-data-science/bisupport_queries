with enrollments as (
  select user_id, dc.courserun_key, dcs.course_key, dcs.course_title
      from "PROD"."CORE"."DIM_ENROLLMENTS" de
      join "PROD"."CORE"."DIM_COURSERUNS" dc
      on de.courserun_key = dc.courserun_key
      join "PROD"."CORE"."DIM_COURSES" dcs
      on dc.course_id=dcs.course_id
      where is_active
      and dc.partner_key='IBM'
      and dcs.course_key  in (
        'IBM+DA0101EN','IBM+DB0201EN','IBM+ML0101EN','IBM+DS0720EN','IBM+DV0101EN','IBM+AI0101EN','IBM+DA0130','IBM+DS0101EN','IBM+DS0105EN',
        'IBM+DS0103EN','IBM+CAD101EN','IBM+DV0130','IBM+Cybfun.1.0','IBM+DL0110EN','IBM+DA0321','IBM+PY0101SP','IBM+CAD220EN','IBM+DL0120EN',
        'IBM+DL0320EN','IBM+CB0103EN','IBM+CB0103EN','IBM+DB0201SP','IBM+AI102EN','IBM+DS0720SP','IBM+CC0201EN','IBM+DL0122EN','IBM+ML0210EN',
        'IBM+DS0101SP','IBM+CAD201EN','IBM+Cybfun.3.0','IBM+DA0101SP','IBM+AI0101SP','IBM+CAD0321EN','IBM+Cybfun.4.0','IBM+DV0101SP',
        'IBM+CB0106EN','IBM+CB0106EN','IBM+DB0100EN','IBM+DS0105SP','IBM+Cybfun.2.0','IBM+CV0101EN','IBM+DS0103SP','IBM+CB0103SP','IBM+DB0211EN',
        'IBM+CAD250EN','IBM+AI0102SP','IBM+DB0101EN','IBM+PY0222EN','IBM+DB0303EN','IBM+PY0220EN','IBM+CV0101SP','IBM+CB0106SP','IBM+CC0103EN',
        'IBM+PY0221EN','IBM+CC0150EN','IBM+CB0105EN','IBM+DB0151EN','IBM+EZZ1EG','IBM+EZZ2EG','IBM+EZZ3EG'
)
      and not is_privileged_or_internal_user
  order by 1
)
, completers as (
select 
     distinct de.user_id, course_key, course_title
from enrollments de
left join
  "PROD"."LMS_PII"."CERTIFICATES_GENERATEDCERTIFICATE" as cert 
on cert.course_id = de.courserun_key and de.user_id=cert.user_id
where status in ('downloadable', 'generating')
  and date(MODIFIED_DATE) >=  dateadd('month', -12, current_date())
order by user_id
)

select 
    courses.user_id,
    users.email,
    listagg(courses.course_key, ',') as course_key_list,
    listagg(courses.course_title, ',') as course_title_list
from completers courses
join prod.lms_pii.auth_user users
on courses.user_id = users.id
group by courses.user_id, users.email
order by user_id



