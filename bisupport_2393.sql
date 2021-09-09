--In FY2021, we tried a tactic consisting in optimising partners portfolios by generating strategic alliances / collaborations between key spanish speaking partners.
--How? we looked at their content offerings and suggested the creation of stackable PCs, when that made sense (re: learner outcomes, program structure) by bundling course 1 from partner a and course 2 from partner 2.
--Why? we have limited resources in Spanish and this allows us to increase learner base and reach in the region while augmenting partner engagement (we facilitate alliances and networking).
--Those courses were existing but recently launched as PCs. I would like to find the best way to measure impact / success (ie did it really move the needle and if so, then why not repeat...)
--Here they are - I think we need to look at performance from WHEN they relaunched as PCs but would also welcome your input on best way to assess this.
--Here they are:
--Gestión de proyectos y metodología ágil - launched as PC on 22nd April 21
--https://www.edx.org/professional-certificate/upvalenciax-javerianax-gestion-de-proyectos-y-metodologia-agil?index=product&queryID=a19fd93a87cdc01247f679c308616cd9&position=1
--Habilidades esenciales de Liderazgo - launched as PC on 9th February 21 (this one is tricky as some courses are also part of MMs)
--https://www.edx.org/professional-certificate/upvalenciax-tecdemonterreyx-habilidades-esenciales-de-liderazgo?index=product&queryID=caf115b84ea1c579b14cc8e14d1f67b8&position=1
--Herramientas de presentación: Power Point, Photoshop e Illustrator - launched as PC on 20th January 21
--https://www.edx.org/professional-certificate/javerianax-upvx-herramientas-de-presentacion-powerpoint-photoshop-e-illustrator?index=product&queryID=2fdfa883902a65763bb93b4d5d69064f&position=1
--Fitness corporativo: nutrición y bienestar laboral -  launched as PC on 25th March 21
--https://www.edx.org/professional-certificate/anahuacx-upvalenciax-fitness-corporativo?index=product&queryID=5abd3cb10e79d16a1ef71c3b4fcccf0a&position=1


select course_key,course_title
from prod.core.dim_courses dc
--where course_id in (11866,12322,10431,900)
where --dc.course_title like '%Fitness corporativo%' -- 11866
    --or dc.course_title like '%herramientas de%' -- 12322
    -- dc.course_title like '%habilidades esenciales%' -- 10431
    -- dc.course_title like '%Gestión de proyectos%' -- 900
    dc.course_title like '%Gestión de proyectos%'

select distinct course_key
from prod.business_intelligence.bi_all_course_window_status
where course_key
    in ('UPValenciaX+pwrbi201x','IDBx+IDB6x','MichiganX+SN401x.es','AnahuacX+UAMY.CP7.2x')

select top 100 *
from prod.core.dim_users

with user                  as (select * from /* {{ cref('*/core_int_auth_user/*') }} */ )
   , profile               as (select * from /* {{ cref('*/core_int_auth_user_profile/*') }} */ )
   , languages             as (select * from /* {{ cref('*/core_int_user_languages/*') }} */ )
   , preferences           as (select * from /* {{ cref('*/core_int_user_preferences/*') }} */ )
   , last_location_country as (select * from /* {{ csource('*/prod.core_event_sources.user_last_location_country/*') }} */ )
   , lms_auth_registration as (select * from /* {{ csource('*/prod.lms.auth_registration/*') }} */ )
;
select *
    --   sum(case when is_superuser then 1 else 0 end)
    -- ,sum(case when is_active then 1 else 0 end)
    -- ,sum(case when is_staff then 1 else 0 end)
from prod.lms.auth_group
limit 100;


select distinct program_id
from prod.core.program_courserun_all pca
    left join prod.core.dim_courseruns dc on pca.courserun_id = dc.courserun_id
where course_key IN ('UPValenciaX+pwrbi201x','IDBx+IDB6x','MichiganX+SN401x.es','AnahuacX+UAMY.CP7.2x')

select distinct pca.program_id,course_id,partner_key,pca.program_title
from prod.core.program_courserun_all pca
    inner join prod.core.dim_program dp on pca.program_id = dp.program_id
where --pca.program_id in (651,145,620)
      --dp.program_title like '%Gestión de proyectos y metodología ágil%' --634
      --dp.program_title like '%Habilidades esenciales de Liderazgo%' --610
      --dp.program_title like '%Herramientas de presentación: Power Point, Photoshop e Illustrator%' --603
      dp.program_title like '%Fitness corporativo: nutrición y bienestar laboral%' --620

-- Gestión de proyectos y metodología ágil - launched as PC on 22nd April 21
-- https://www.edx.org/professional-certificate/upvalenciax-javerianax-gestion-de-proyectos-y-metodologia-agil?index=product&queryID=a19fd93a87cdc01247f679c308616cd9&position=1
--
-- Habilidades esenciales de Liderazgo - launched as PC on 9th February 21 (this one is tricky as some courses are also part of MMs)
-- https://www.edx.org/professional-certificate/upvalenciax-tecdemonterreyx-habilidades-esenciales-de-liderazgo?index=product&queryID=caf115b84ea1c579b14cc8e14d1f67b8&position=1
--
-- Herramientas de presentación: Power Point, Photoshop e Illustrator - launched as PC on 20th January 21
-- https://www.edx.org/professional-certificate/javerianax-upvx-herramientas-de-presentacion-powerpoint-photoshop-e-illustrator?index=product&queryID=2fdfa883902a65763bb93b4d5d69064f&position=1
--
-- Fitness corporativo: nutrición y bienestar laboral -  launched as PC on 25th March 21
-- https://www.edx.org/professional-certificate/anahuacx-upvalenciax-fitness-corporativo?index=product&queryID=5abd3cb10e79d16a1ef71c3b4fcccf0a&position=1



select distinct program_id,course_key
from prod.business_intelligence.bi_all_course_window_status
where course_key in ('TecdeMonterreyX+MMCEL.1x','UPValenciaX+LIDER201.3x')
--where program_id in (634,620,603,610)
order by program_id

select *
from prod.core.dim_courses dc
where course_id in (1844,4623)

select distinct dc.course_id,pca.program_id
from prod.core.program_courserun_all pca
    left join prod.core.dim_courseruns dc on pca.course_id =  dc.course_id
where dc.course_id in (1844,4623)

with bundle_spend_per_courserun as
( select courserun_key,sum(case when is_program_from_order then booking_amount else null end) as bundle_buys_per_courserun,fb.program_id
,sum(case when not is_program_from_order then booking_amount else null end) as other_buys_per_courserun
from prod.core.fact_booking fb
group by courserun_key,fb.program_id)

select pca.course_id,pca.courserun_id,pca.partner_key,pca.program_id,pca.program_title,pca.program_type
-- program from order (aka bundle) purchases
,bp.bundle_buys_per_courserun
,other_buys_per_courserun
,row_number() over (partition by dc.courserun_id order by pca.program_id)
-- "other" purchase amounts
from prod.core.program_courserun_all pca
    left join prod.core.dim_courseruns dc on pca.courserun_id = dc.courserun_id
    left join bundle_spend_per_courserun bp on bp.courserun_key = dc.courserun_key and pca.program_id = bp.program_id
where pca.course_id in (
    select distinct course_id
    from prod.core.program_courserun_all
    where program_id in (634, 620, 603, 610)
)
order by pca.program_id,pca.course_id,pca.courserun_id

-- questions:
-- did bookings increase
-- did enrollments increase
-- did cross-polination of users increase

select pca.course_id,pca.courserun_id,pca.partner_key,pca.program_id,pca.program_title,pca.program_type
from prod.core.program_courserun_all pca
    left join prod.core.dim_courseruns dc on pca.courserun_id = dc.courserun_id
where pca.course_id in (
    select distinct pca.course_id
    from prod.core.program_courserun_all pca
        inner join prod.core.dim_courseruns dc on pca.course_id = dc.course_id
    where program_id in (603, 634, 620, 610)
)
order by course_id,program_id

select count(*),count(distinct de.user_id)
from prod.core.dim_enrollments de
    inner join prod.core.dim_users du on de.user_id = du.user_id
where de.courserun_key in
      (select distinct dc.courserun_key
       from prod.core.program_courserun_all     pca
            inner join prod.core.dim_courseruns dc
                       on pca.course_id = dc.course_id
       where program_id in (603, 634, 620, 610)
      )

-- 634 Gestión de proyectos y metodología ágil - launched as PC on 22nd April 21
-- 610 Habilidades esenciales de Liderazgo - launched as PC on 9th February 21 (this one is tricky as some courses are also part of MMs)
-- 603 Herramientas de presentación: Power Point, Photoshop e Illustrator - launched as PC on 20th January 21
-- 620 Fitness corporativo: nutrición y bienestar laboral -  launched as PC on 25th March 21

select *
from prod.core.dim_program
where program_id in (603, 634, 620, 610)

select dp.program_id,dp.program_created_date,dp.program_title
    ,COUNT(case when de.first_enrollment_date <=dp.program_created_date then enrollment_id else null end) as EnrollsPreCombination
    ,COUNT(case when de.first_enrollment_date >=dp.program_created_date then enrollment_id else null end) as EnrollsPostCombination
    ,COUNT(DISTINCT case when de.first_enrollment_date <=dp.program_created_date then user_id else null end) as UsersPreCombination
    ,COUNT(DISTINCT case when de.first_enrollment_date >=dp.program_created_date then user_id else null end) as UsersPostCombination
    ,count(case when de.first_verified_date <=dp.program_created_date then enrollment_id else null end) as VerificationsPreCombination
    ,COUNT(case when de.first_verified_date >=dp.program_created_date then enrollment_id else null end) as VerificationsPostCombination
    ,enrollsprecombination/usersprecombination
    ,enrollspostcombination/userspostcombination
    ,verificationsprecombination/enrollsprecombination
    ,verificationspostcombination/enrollspostcombination
from prod.core.dim_enrollments de
    left join prod.core.program_courserun_all pca on de.courserun_id = pca.courserun_id
    left join prod.core.dim_program dp on pca.program_id = dp.program_id
where de.courserun_key in
      (select distinct dc.courserun_key
       from prod.core.program_courserun_all     pca
            inner join prod.core.dim_courseruns dc
                       on pca.course_id = dc.course_id
       where pca.program_id in (603, 634, 620, 610)
      )
and dp.program_id in (603, 634, 620, 610)
GROUP BY  dp.program_id,dp.program_created_date,dp.program_title

--calculate differences at the program level pre and post program created date
with bookings_raw as (
select sum(booking_amount),dp.program_id,dp.program_created_date
    ,SUM(case when x.booking_date <=dp.program_created_date then booking_amount else null end) as BookingsPreCombination
    ,SUM(case when x.booking_date >=dp.program_created_date then booking_amount else null end) as BookingsPostCombination

       from (select fb.course_key
                    , booking_date
                    , booking_amount
               from prod.core.fact_booking                    fb
                    left join prod.core.dim_courseruns        dc
                              on fb.courserun_key = dc.courserun_key
                    left join prod.core.program_courserun_all pca
                              on dc.courserun_id = pca.courserun_id
                    left join prod.core.dim_program           dp
                              on pca.program_id = dp.program_id
               where fb.course_key in
                     (select distinct dc.course_key
                      from prod.core.program_courserun_all     pca
                           inner join prod.core.dim_courseruns dc
                                      on pca.course_id = dc.course_id
                      where program_id in (603, 634, 620, 610)
                     )
              ) x
    left join prod.core.dim_courses dc on x.course_key = dc.course_key
    left join prod.core.program_courserun_all pca on pca.course_id = dc.course_id --and pca.program_id in (603, 634, 620, 610)
    left join prod.core.dim_program dp on pca.program_id = dp.program_id
    where pca.program_id in (603, 634, 620, 610)
    group by dp.program_id,dp.program_created_date
),

  enrolls_raw as (
select dp.program_id,dp.program_created_date,dp.program_title
    ,COUNT(case when de.first_enrollment_date <=dp.program_created_date then enrollment_id else null end) as EnrollsPreCombination
    ,COUNT(case when de.first_enrollment_date >=dp.program_created_date then enrollment_id else null end) as EnrollsPostCombination
    ,COUNT(DISTINCT case when de.first_enrollment_date <=dp.program_created_date then user_id else null end) as UsersPreCombination
    ,COUNT(DISTINCT case when de.first_enrollment_date >=dp.program_created_date then user_id else null end) as UsersPostCombination
    ,count(case when de.first_verified_date <=dp.program_created_date then enrollment_id else null end) as VerificationsPreCombination
    ,COUNT(case when de.first_verified_date >=dp.program_created_date then enrollment_id else null end) as VerificationsPostCombination
    ,enrollsprecombination/usersprecombination
    ,enrollspostcombination/userspostcombination
    ,verificationsprecombination/enrollsprecombination
    ,verificationspostcombination/enrollspostcombination
from prod.core.dim_enrollments de
    left join prod.core.dim_courseruns dc on de.courserun_key = dc.courserun_key
    left join prod.core.program_courserun_all pca on de.courserun_id = pca.courserun_id
    left join prod.core.dim_program dp on pca.program_id = dp.program_id
where dc.course_key in
      (select distinct dc.course_key
       from prod.core.program_courserun_all     pca
            inner join prod.core.dim_courseruns dc
                       on pca.course_id = dc.course_id
       where pca.program_id in (603, 634, 620, 610)
      )
and dp.program_id in (603, 634, 620, 610)
GROUP BY  dp.program_id,dp.program_created_date,dp.program_title)

select er.program_title
    ,round(br.bookingsprecombination/enrollsprecombination,2) as BookingsPerEnrollPre
    ,round(br.bookingspostcombination/enrollspostcombination,2) as BookingsPerEnrollPost
from enrolls_raw er
    left join bookings_raw br on er.program_id = br.program_id
order by er.program_id

select dp.program_id,dp.program_created_date,dp.program_title
    ,COUNT(case when de.first_enrollment_date <=dp.program_created_date then enrollment_id else null end) as EnrollsPreCombination
    ,COUNT(case when de.first_enrollment_date >=dp.program_created_date then enrollment_id else null end) as EnrollsPostCombination
    ,COUNT(DISTINCT case when de.first_enrollment_date <=dp.program_created_date then user_id else null end) as UsersPreCombination
    ,COUNT(DISTINCT case when de.first_enrollment_date >=dp.program_created_date then user_id else null end) as UsersPostCombination
    ,count(case when de.first_verified_date <=dp.program_created_date then enrollment_id else null end) as VerificationsPreCombination
    ,COUNT(case when de.first_verified_date >=dp.program_created_date then enrollment_id else null end) as VerificationsPostCombination
    ,enrollsprecombination/usersprecombination
    ,enrollspostcombination/userspostcombination
    ,verificationsprecombination/enrollsprecombination
    ,verificationspostcombination/enrollspostcombination
from prod.core.dim_enrollments de
    left join prod.core.program_courserun_all pca on de.courserun_id = pca.courserun_id
    left join prod.core.dim_program dp on pca.program_id = dp.program_id
where de.courserun_key in
      (select distinct dc.courserun_key
       from prod.core.program_courserun_all     pca
            inner join prod.core.dim_courseruns dc
                       on pca.course_id = dc.course_id
       where pca.program_id in (603, 634, 620, 610)
      )
and dp.program_id in (603, 634, 620, 610)
GROUP BY  dp.program_id,dp.program_created_date,dp.program_title
-- select program_id,program_created_date from prod.core.dim_program where program_id in (603,634,620,610) order by program_id
with bookings_raw as (
select sum(booking_amount),dp.program_id,x.course_key,dp.program_created_date
    ,SUM(case when x.booking_date <=dp.program_created_date then booking_amount else null end) as BookingsPreCombination
    ,SUM(case when x.booking_date >=dp.program_created_date then booking_amount else null end) as BookingsPostCombination

       from (select fb.course_key
                    , booking_date
                    , booking_amount
               from prod.core.fact_booking                    fb
                    left join prod.core.dim_courseruns        dc
                              on fb.courserun_key = dc.courserun_key
                    left join prod.core.program_courserun_all pca
                              on dc.courserun_id = pca.courserun_id
                    left join prod.core.dim_program           dp
                              on pca.program_id = dp.program_id
               where fb.course_key in
                     (select distinct dc.course_key
                      from prod.core.program_courserun_all     pca
                           inner join prod.core.dim_courseruns dc
                                      on pca.course_id = dc.course_id
                      where program_id in (603, 634, 620, 610)
                     )
              ) x
    left join prod.core.dim_courses dc on x.course_key = dc.course_key
    left join prod.core.program_courserun_all pca on pca.course_id = dc.course_id --and pca.program_id in (603, 634, 620, 610)
    left join prod.core.dim_program dp on pca.program_id = dp.program_id
    where pca.program_id in (603, 634, 620, 610)
    group by dp.program_id,x.course_key,dp.program_created_date
),

  enrolls_raw as (
select dp.program_id
     ,program_created_date,dp.program_title,dc.course_key
    ,COUNT(case when de.first_enrollment_date <=dp.program_created_date then enrollment_id else null end) as EnrollsPreCombination
    ,COUNT(case when de.first_enrollment_date >=dp.program_created_date then enrollment_id else null end) as EnrollsPostCombination
    ,COUNT(DISTINCT case when de.first_enrollment_date <=dp.program_created_date then user_id else null end) as UsersPreCombination
    ,COUNT(DISTINCT case when de.first_enrollment_date >=dp.program_created_date then user_id else null end) as UsersPostCombination
    ,count(case when de.first_verified_date <=dp.program_created_date then enrollment_id else null end) as VerificationsPreCombination
    ,COUNT(case when de.first_verified_date >=dp.program_created_date then enrollment_id else null end) as VerificationsPostCombination
    ,enrollsprecombination/usersprecombination
    ,enrollspostcombination/userspostcombination
    ,verificationsprecombination/enrollsprecombination
    ,verificationspostcombination/enrollspostcombination
from prod.core.dim_enrollments de
    left join prod.core.dim_courseruns dc on de.courserun_key = dc.courserun_key
    left join prod.core.program_courserun_all pca on de.courserun_id = pca.courserun_id
    left join prod.core.dim_program dp on pca.program_id = dp.program_id
where dc.course_key in
      (select distinct dc.course_key
       from prod.core.program_courserun_all     pca
            inner join prod.core.dim_courseruns dc
                       on pca.course_id = dc.course_id
       where pca.program_id in (603, 634, 620, 610)
      )
and dp.program_id in (603, 634, 620, 610)
GROUP BY  dp.program_id,dp.program_created_date,dp.program_title,dc.course_key)

select er.program_title
     ,br.course_key
     ,dc.course_title
  --   ,dc.course_date
    ,round(br.bookingsprecombination/enrollsprecombination,2) as BookingsPerEnrollPre
    ,round(br.bookingspostcombination/enrollspostcombination,2) as BookingsPerEnrollPost
    ,enrollsprecombination
    ,enrollspostcombination
    ,verificationsprecombination
    ,verificationspostcombination
    ,bookingsprecombination
    ,bookingspostcombination
  --  ,enrollsprecombination,enrollspostcombination
from enrolls_raw er
    left join bookings_raw br on er.course_key = br.course_key
    left join prod.core.dim_courses dc on dc.course_key = er.course_key
order by program_title,course_key