select *
from prod.enterprise.ent_base_enterprise_customer
where enterprise_customer_name like '%Johnson%'

with registered_enterprise_users as
    (
        select *
        from prod.enterprise.ent_base_enterprise_user
        where enterprise_customer_uuid in (
                                           '74fdbea065814748b84fc3a6e823ecc3' -- Johnson & Johnson
            , '9f5d643157f0461fa6c9b0be6c84dc63' -- Johnson & Johnson Technology

            )
    )
   --  select count(*) from registered_enterprise_users ; 124
   , registered_b2c_users        as
    (
        select du.user_id
        from prod.core.dim_users as                       du
             left join prod.core_pii.corepii_user_profile up
                       on du.user_id = up.user_id
        where up.email_domain = 'its.jnj.com'
          and not exists
            (
                select lms_user_id
                from registered_enterprise_users eu
                where eu.lms_user_id = du.user_id
            )
    )
--select count(*) from registered_b2c_users  1668
/*FOR PART 1: use below two lines and adjust group by statement
-- enterprise.enterprise_user_id is not null                                                               as is_enterprise_user
-- , ifnull(ee.is_enterprise_transaction and enterprise.enterprise_user_id is not null, false)               as is_enterprise_transaction
     --, ifnull(first_verified_date is not null, false)*/
select coalesce(sub.name, ts.name)                                                                             as skill
     , count(distinct enroll.user_id)                                                                          as enrolled_users
     , count(distinct enroll.enrollment_id)                                                                    as enrollments
     , count(distinct iff(completion.passed_timestamp is not null, enroll.enrollment_id, null))                as completions
     , count(distinct iff(enroll.first_downloadable_certificate_date is not null, enroll.enrollment_id, null)) as certifications
from dim_enrollments                                           enroll
     left join prod.core.dim_courseruns                        dcr
               on dcr.courserun_key = enroll.courserun_key
     left join prod.discovery.taxonomy_courseskills            cs
               on cs.course_key = dcr.course_key
     left join prod.discovery.taxonomy_skill                   ts
               on cs.skill_id = ts.id
     left join prod.discovery.taxonomy_skillsubcategory        sub
               on sub.id = ts.subcategory_id
     left join prod.enterprise.ent_base_enterprise_enrollment  ee
               on ee.lms_enrollment_id = enroll.enrollment_id
     left join prod.business_intelligence.bi_course_completion completion
               on completion.user_id = enroll.user_id
                   and completion.courserun_key = enroll.courserun_key
     left join registered_enterprise_users                     enterprise
               on enterprise.lms_user_id = enroll.user_id
     left join registered_b2c_users as                         b2c
               on b2c.user_id = enroll.user_id
where (b2c.user_id is not null
    or enterprise.lms_user_id is not null)
  and coalesce(sub.name, ts.name) is not null
group by 1
order by 2 desc

select *
from prod.discovery.taxonomy_skillsubcategory
select *
from prod.discovery.taxonomy_courseskills
select *
from prod.core.fact_course_skill

select *
from prod.discovery.taxonomy_skillcategory
where id = 17