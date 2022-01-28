with pre_covid as (
    select sum(coalesce(verified_count, 0)) as pre_covid_verified
         , sum(enrollment_count)            as pre_covid_enrolled
         , dim_courses.course_key           as pre_covid_course_key
         , dim_courses.partner_key          as pre_covid_partner
         , course_title                     as pre_covid_course

    from tableau_fact_b2c_funnel

             join dim_courseruns
                  on tableau_fact_b2c_funnel.courserun_id = dim_courseruns.courserun_id
             join dim_courses on dim_courseruns.course_key = dim_courses.course_key
    where dim_courses.partner_key like 'IBM%'
      and metric_date between '2019-08-01' and '2019-10-31' --three-month pre-covid window
      and dim_courses.course_key not in
          ('IBM+BD0225EN', 'IBM+BD0231EN', 'IBM+CD0116EN', 'IBM+CD0351EN', 'IBM+DA0151EN', 'IBM+DB0111EN',
           'IBM+DB0151EN', 'IBM+DB0231EN', 'IBM+DB0250EN', 'IBM+DB260EN', 'IBM+DB321EN', 'IBM+DV0151EN', 'IBM+ESME36G',
           'IBM+ESX9EG', 'IBM+EZ52EG', 'IBM+EZP05EG', 'IBM+IBMICECPP01', 'IBM+IBMICECPP02', 'IBM+IBMICECPP03',
           'IBM+IBMPSRE1',
           'IBM+IBMPSRE2', 'IBM+IBMPSRE3', 'IBM+LX0117EN', 'IBM+PYTEST', 'IBM+QZE32DG', 'IBM+QZE33DG', 'IBM+RP0101EN',
           'IBM+RP0203EN',
           'IBM+RP0321EN', 'IBM+ST0151EN', 'IBM+Test_101', 'IBM+CB0105EN',
           'IBM+DL0122EN')                                  --removed courses without credly badges
    group by pre_covid_course_key, pre_covid_partner, pre_covid_course
)

   , post_credly_fall as (
    select sum(coalesce(verified_count, 0)) as post_credly_fall_verified
         , sum(enrollment_count)            as post_credly_fall_enrolled
         , dim_courses.course_key           as post_credly_fall_course_key
         , dim_courses.partner_key          as post_credly_fall_partner
         , course_title                     as post_credly_fall_course

    from tableau_fact_b2c_funnel

             join dim_courseruns
                  on tableau_fact_b2c_funnel.courserun_id = dim_courseruns.courserun_id
             join dim_courses on dim_courseruns.course_key = dim_courses.course_key
    where dim_courses.partner_key like 'IBM%'
      and metric_date between '2021-08-01' and '2021-10-31' --three-month pre-covid window
      and dim_courses.course_key not in
          ('IBM+BD0225EN', 'IBM+BD0231EN', 'IBM+CD0116EN', 'IBM+CD0351EN', 'IBM+DA0151EN', 'IBM+DB0111EN',
           'IBM+DB0151EN', 'IBM+DB0231EN', 'IBM+DB0250EN', 'IBM+DB260EN', 'IBM+DB321EN', 'IBM+DV0151EN', 'IBM+ESME36G',
           'IBM+ESX9EG', 'IBM+EZ52EG', 'IBM+EZP05EG', 'IBM+IBMICECPP01', 'IBM+IBMICECPP02', 'IBM+IBMICECPP03',
           'IBM+IBMPSRE1',
           'IBM+IBMPSRE2', 'IBM+IBMPSRE3', 'IBM+LX0117EN', 'IBM+PYTEST', 'IBM+QZE32DG', 'IBM+QZE33DG', 'IBM+RP0101EN',
           'IBM+RP0203EN',
           'IBM+RP0321EN', 'IBM+ST0151EN', 'IBM+Test_101', 'IBM+CB0105EN',
           'IBM+DL0122EN')                                  --removed courses without credly badges
    group by post_credly_fall_course_key, post_credly_fall_partner, post_credly_fall_course
)
   , post_credly_all as (
    select sum(coalesce(verified_count, 0)) as post_credly_all_verified
         , sum(enrollment_count)            as post_credly_all_enrolled
         , dim_courses.course_key           as post_credly_all_course_key
         , dim_courses.partner_key          as post_credly_all_partner
         , course_title                     as post_credly_all_course

    from tableau_fact_b2c_funnel

             join dim_courseruns
                  on tableau_fact_b2c_funnel.courserun_id = dim_courseruns.courserun_id
             join dim_courses on dim_courseruns.course_key = dim_courses.course_key
    where dim_courses.partner_key like 'IBM%'
      and metric_date between '2021-06-17' and '2022-01-25' --three-month pre-covid window
      and dim_courses.course_key not in
          ('IBM+BD0225EN', 'IBM+BD0231EN', 'IBM+CD0116EN', 'IBM+CD0351EN', 'IBM+DA0151EN', 'IBM+DB0111EN',
           'IBM+DB0151EN', 'IBM+DB0231EN', 'IBM+DB0250EN', 'IBM+DB260EN', 'IBM+DB321EN', 'IBM+DV0151EN', 'IBM+ESME36G',
           'IBM+ESX9EG', 'IBM+EZ52EG', 'IBM+EZP05EG', 'IBM+IBMICECPP01', 'IBM+IBMICECPP02', 'IBM+IBMICECPP03',
           'IBM+IBMPSRE1',
           'IBM+IBMPSRE2', 'IBM+IBMPSRE3', 'IBM+LX0117EN', 'IBM+PYTEST', 'IBM+QZE32DG', 'IBM+QZE33DG', 'IBM+RP0101EN',
           'IBM+RP0203EN',
           'IBM+RP0321EN', 'IBM+ST0151EN', 'IBM+Test_101', 'IBM+CB0105EN',
           'IBM+DL0122EN')                                  --removed courses without credly badges

    group by post_credly_all_course_key, post_credly_all_partner, post_credly_all_course
)


select pre_covid_course                                      as course,
       pre_covid_verified,
       pre_covid_enrolled,
       pre_covid_verified / pre_covid_enrolled               as pre_covid_vtr,
       post_credly_fall_verified,
       post_credly_fall_enrolled,
       post_credly_fall_verified / post_credly_fall_enrolled as post_credly_fall_vtr,
       post_credly_all_verified,
       post_credly_all_enrolled,
       post_credly_all_verified / post_credly_all_enrolled   as post_credly_all_vtr


from pre_covid
         join post_credly_fall
              on pre_covid_course_key = post_credly_fall_course_key
         join post_credly_all
              on post_credly_fall_course_key = post_credly_all_course_key
