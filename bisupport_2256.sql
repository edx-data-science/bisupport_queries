with voucher as (
    select * from /* {{ cref('*/dim_voucher/*') }} */
),
v_assignment as (
    select * from /* {{ cref('*/dim_voucher_assignment/*') }} */
    WHERE voucher_assignment_status<>'REVOKED'
)
,voucher_app as (
    select * from /* {{ csource('*/PROD.ECOMMERCE.VOUCHER_VOUCHERAPPLICATION/*') }} */
)
, voucher_redemption as (
select voucher_app.id as voucher_application_id
     , voucher.voucher_id
     , voucher.voucher_code
     , v_assignment.voucher_assignment_id --can be NULL and not necessarily unique
     , voucher_app.user_id as ecommerce_user_id
     , voucher_app.order_id
     , voucher_app.date_created as voucher_redemption_date
  from voucher_app
  left join voucher
    on voucher.voucher_id= voucher_app.voucher_id
  left join v_assignment --Note: vouchers do NOT have to be assigned to be redeemed
      on v_assignment.voucher_application_id = voucher_app.id
)
SELECT
     cr.course_key as
         COURSE
    ,voucher_code as COUPON_CODE
    ,VOUCHER_APPLICATION_ID
    ,VOUCHER_ID
    ,VOUCHER_CODE
    ,USER_ID
    ,o.ORDER_ID
    ,VOUCHER_REDEMPTION_DATE
    ,o.COURSERUN_KEY
    ,COURSERUN_TITLE
    ,u.USERNAME
FROM voucher_redemption r
join prod.ecommerce_pii.ecommerce_user eu
on eu.id = r.ecommerce_user_id
JOIN prod.LMS_PII.AUTH_USER  u
ON u.id = eu.lms_user_id
join prod.core.core_imd_transaction_orderline_enrollment o
on o.order_id = r.order_id
left join prod.core.dim_courseruns cr
    on cr.courserun_key = o.order_courserun_key
 where  (o.transaction_type is null or o.transaction_type = 'sale')
   and r.voucher_code='6PAHLTSXCH272C7K'