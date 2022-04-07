-- customer accounts with learners in ACCA courses


with ent_enroll   as (select * from prod.enterprise.ent_base_enterprise_enrollment)
   , ent_customer as (select * from prod.enterprise.ent_base_enterprise_customer)
   , courserun    as (select * from prod.core.dim_courseruns)
   , sales_raw    as (select * from prod.enterprise.ent_base_salesforce_opportunity)
   , sales        as
    (
        select enterprise_customer_uuid
             , listagg(distinct opportunity_owner_name, ', ') as owners
        from sales_raw
        group by enterprise_customer_uuid
    )
select count(*) enrollment_count
     , enterprise_customer_name
     , sales.owners
from ent_enroll
     left join ent_customer
               on ent_enroll.enterprise_customer_uuid = ent_customer.enterprise_customer_uuid
     left join courserun
               on ent_enroll.lms_courserun_key = courserun.courserun_key
     left join sales
               on ent_enroll.enterprise_customer_uuid = sales.enterprise_customer_uuid
where ent_enroll.amount_customer_paid <> 0
  and courserun.partner_key = 'ACCA'
group by enterprise_customer_name, sales.owners
order by 1 desc, 2


