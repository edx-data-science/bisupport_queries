select total_discount, offer_id
from prod.enterprise.dim_offer
where salesforce_opportunity_id = '0064W00000tpgwlQAA';
where offer_id = 69091
--total discount = 27,776.490000 out of 27783.00

select order_product_class, order_refunded_quantity, enterprise_customer_uuid, sum(order_discount_amount)
from prod.core.core_imd_transaction_orderline_enrollment
where order_line_offer_id = 69091
group by 1
       , 2
       , 3
--27776.49 ; 2,822 of which is refunds = $24,954.49 ; $278 in unredeemed course entitlements (see below) = 24,676.49 expected in the LPR
select order_product_class, enrollment_id is null, sum(amount_invoice)
from prod.core.core_imd_transaction_orderline_enrollment
where order_line_offer_id = 69091
  and (order_refunded_quantity is null or order_refunded_quantity = 0)
group by 1
       , 2

--enrollments refunded,
select enrollment_id, order_discount_amount, *
from prod.core.core_imd_transaction_orderline_enrollment
where order_line_offer_id = 69091
  and order_refunded_quantity = 1

select sum(course_list_price), sum(amount_learner_paid)
from prod.enterprise.learner_progress_report_internal
where offer_id = 69091
  and is_refunded;

-- and enterprise_customer_uuid = '513617409f944fdaafb92afe009ffe70'
and is_included_in_utilization

select sum(course_list_price), sum(amount_learner_paid)
from prod.enterprise.learner_progress_report_internal
where offer_id = 69091
  -- and enterprise_customer_uuid = '513617409f944fdaafb92afe009ffe70'
  and is_included_in_utilization
--$24,627.49

select *
from prod.enterprise._imd_enterprise_reporting
where is_refunded
  and offer_id = 69091

---10 refunds shown as refunded in citoe- are the all refunded on LPR?
select enrollment_id, is_refunded
from prod.enterprise.learner_progress_report_internal
where enrollment_id in
      (121157886, 117783616, 118103963, 117783301, 117782743, 119648459, 117783840, 121157505, 117782268, 117782967
          )

--why isn't 116839772 shown as refunded?
select *, amount_invoice
from core_imd_transaction_orderline_enrollment
where enrollment_id = 121157886


--find all enrollments in citoe not in the LPR for this offer
select *
from prod.core.core_imd_transaction_orderline_enrollment
where order_line_offer_id = 69091
  and enrollment_id not in
      (select enrollment_id from prod.enterprise.learner_progress_report_internal where learner_progress_report_internal.enrollment_id is not null)


--find diff by enrollment
with citoe as (
    select enrollment_id, sum(amount_invoice) as citoe_amount
    from prod.core.core_imd_transaction_orderline_enrollment
    where order_line_offer_id = 69091
    group by 1
)
   , lpr   as (
    select enrollment_id
         , zeroifnull(sum(course_list_price)) as lpr_amount
    from prod.enterprise.learner_progress_report_internal
    group by 1
)
select *, abs(lpr_amount - citoe_amount) as diff
from citoe
     left join lpr
               on lpr.enrollment_id = citoe.enrollment_id
order by diff desc

---THERE IS ONE ENROLLMENT MARKED REFUNDED IN LPR WITHOUT A REFUND TRANSACTION
select *
from prod.enterprise.learner_progress_report_internal
where enrollment_id =
      120884961

select order_refunded_quantity
from prod.core.core_imd_transaction_orderline_enrollment
where enrollment_id = 120884961


--two enrollments were the learner used the offer to enroll in the course AND purchased the program = $149 * 2
select *
from prod.core.core_imd_transaction_orderline_enrollment
where user_id = 42490670--122008211
order by order_timestamp


with enterprise_enrollments as (
    select eu.user_id as lms_user_id, ece.enterprise_customer_user_id, course_id as course_run_key, ece.created as enrollment_date
    from prod.lms_pii.enterprise_enterprisecourseenrollment       ece
         left join prod.lms_pii.enterprise_enterprisecustomeruser eu
                   on eu.id = ece.enterprise_customer_user_id
)
   , orders                 as (
    select *
    from prod.core.core_imd_transaction_orderline_enrollment
    where order_line_offer_id is not null
      and enterprise_customer_uuid is not null
      and enrollment_id is not null
)
select min(order_timestamp)
from orders
where not exists(
        select *
        from enterprise_enrollments ee
        where orders.user_id = ee.lms_user_id
          and orders.courserun_key = ee.course_run_key
    )


with program as
         (
             select distinct
                    course_id
                  , partner_key
                  , program_title
             from prod.core.core_courserun_active_program_membership
             where sort_revenue_order = 1
         )
select order_product_class
     , enrollment_id
     , dc.course_key
     , ee.consent_granted
     , up.email
     , p.partner_key
     , p.program_title
     , citoe.order_discount_amount as price
from prod.core.core_imd_transaction_orderline_enrollment      citoe
     left join prod.enterprise.ent_base_enterprise_enrollment ee
               on ee.lms_enrollment_id = citoe.enrollment_id
     left join prod.core.dim_courses                          dc
               on dc.course_uuid = citoe.entitlement_course_uuid
     left join prod.core_pii.corepii_user_profile             up
               on up.user_id = ee.lms_user_id
     left join program as                                     p
               on p.course_id = dc.course_id
where order_line_offer_id = 69091
  and (order_refunded_quantity = 0
    or order_refunded_quantity is null)
  and order_product_class = 'course-entitlement';

+-------------------+-------------+--------+-----------------------+---------------+---------------------+
|ORDER_PRODUCT_CLASS|ENROLLMENT_ID|USER_ID |COURSE_KEY             |CONSENT_GRANTED|email                |
+-------------------+-------------+--------+-----------------------+---------------+---------------------+
|course-entitlement |null         |41104963|UPValenciaX+LIDER201.4x|null           |null                 |
|course-entitlement |121206837    |41104963|UPValenciaX+GM201x     |true           |mabarbosa@sura.com.co|
|course-entitlement |null         |41104963|UPValenciaX+GP201x     |null           |null                 |
|course-entitlement |121390291    |42145454|AnahuacX+UAMY.CP6.1x   |true           |sgavirial@sura.com.co|
|course-entitlement |null         |42145454|AnahuacX+UVA.CP5.2x    |null           |null                 |
+-------------------+-------------+--------+-----------------------+---------------+---------------------+


select *
from prod.core.dim_courses
where course_uuid = '1e69064739794f79a172d5b2350d503e'