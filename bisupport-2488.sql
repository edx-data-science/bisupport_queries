-- copied form bisupport-2354

/*
UQ offers enrollment codes to current students and they would like to get some data in regards to these coupons. 
They're mainly interested in the number of redemptions, completions and, in which courses have these codes been redeemed. 
Please see the 4 coupon codes below:


*/

/*
--***SUMMARY********************************************************************************************************************************
with coupon_orders as (
select *
from prod.ecommerce.order_orderdiscount
where voucher_code in (
'TSPU5UWLY5N556SE',-- for Write101x
'XMN7DMKPV3VWJU3R',-- for Employ101x
'GIUWK4WGPCYBZ6HU',-- for ACE101x
'7ZC7BZPAV73ULVIB'-- for World101x
                      )
)
select distinct a.voucher_code
      ,c.COURSERUN_KEY, count(c.ENROLLMENT_ID)
from coupon_orders a
left join prod.ecommerce.order_line b
on a.order_id=b.order_id
left join prod.core.core_imd_transaction_orderline_enrollment c
 on b.id=c.order_line_id
group by c.COURSERUN_KEY, a.voucher_code
;

*/

--***DETAIL****************************************************************************************************
with coupon_orders as (
    select *
    from prod.ecommerce.order_orderdiscount
    where voucher_code in
          (
           'TSPU5UWLY5N556SE' -- for Write101x
              , 'XMN7DMKPV3VWJU3R' -- for Employ101x
              , 'GIUWK4WGPCYBZ6HU' -- for ACE101x
              , '7ZC7BZPAV73ULVIB' -- for World101x
              , 'UHWFRLRRI2KV5IPD' -- for Teams101x
              , 'AAKQROAVQMHR2WNQ' -- for Health101x
              , 'SNBKE3USZM5DRQDL' -- for Health101x
              , 'XALSJUAT2XNHADZB' -- for Health101x
              , 'CTIGLRCDVRMBPJKE' -- for Health101x
              , 'BNOW4D2JIAECHLHO' -- for Health101x
              )
)
select distinct
       c.user_id
     , d.course_key
     , d.courserun_title
     , a.voucher_code                              as coupon_code
     , to_date(e.date_created)                     as redemption_date
     , substring(u.email, charindex('@', u.email)) as email_domain
from coupon_orders                                                 a
     join      prod.ecommerce.order_line                           b
               on a.order_id = b.order_id
     join      prod.core.core_imd_transaction_orderline_enrollment c
               on b.id = c.order_line_id
     left join prod.core.dim_courseruns                            d
               on c.courserun_key = d.courserun_key
     left join prod.ecommerce.voucher_voucherapplication           e
               on a.order_id = e.order_id
                   and a.voucher_id = e.voucher_id
     left join prod.lms_pii.auth_user                              u
               on c.user_id = u.id
--and c.USER_ID=e.user_id  --cc this wont work bc they are different user-ids
;

-- starting again from scratch
-- in the ticket they list these courses:

with uqxcr   as (select * from prod.core.dim_courseruns where partner_key = 'UQx')
   , fragkey as (select * from (values ('ACE101x'), ('TEAMS101x'), ('HEALTH101x'), ('WRITE101x'), ('EMPLOY101x'), ('WORLD101x')) as v (frag))
   , cr      as
    (
        select *
        from uqxcr
             join fragkey
                  on uqxcr.course_key ilike '%' || fragkey.frag || '%'
    )
select *
from cr

-- then they seem to want to know what coupons were used to purchase these courses
with uqxcr   as (select * from prod.core.dim_courseruns where partner_key = 'UQx')
   , fragkey as (select * from (values ('ACE101x'), ('TEAMS101x'), ('HEALTH101x'), ('WRITE101x'), ('EMPLOY101x'), ('WORLD101x')) as v (frag))
   , cr      as
    (
        select uqxcr.*
             , dc.course_uuid
        from uqxcr
             join fragkey
                  on uqxcr.course_key ilike '%' || fragkey.frag || '%'
             join prod.core.dim_courses dc
                  on dc.course_key = uqxcr.course_key
    )
   , citoe   as (select * from prod.core.core_imd_transaction_orderline_enrollment)
select cr.course_key
     , order_line_voucher_code
     , vv.name
     , min(citoe.order_timestamp) as ts
     , count(*)
from citoe
     join      cr
               on citoe.courserun_key = cr.courserun_key
                   or citoe.entitlement_course_uuid = cr.course_uuid
     left join prod.ecommerce.voucher_voucher vv
               on vv.id = citoe.order_line_voucher_id
where vv.name ilike '%uq%'
   or vv.name ilike 'C4oC%'
   or order_line_voucher_code in (
                                  'TSPU5UWLY5N556SE',-- for Write101x
                                  'XMN7DMKPV3VWJU3R',-- for Employ101x
                                  'GIUWK4WGPCYBZ6HU',-- for ACE101x
                                  '7ZC7BZPAV73ULVIB'-- for World101x

    )
group by 1
       , 2
       , 3
order by course_key
       , ts desc

-- is it possible some of these have multiple vouchers?
-- that doesn't appear to have happened in recent memory or really very often
select *
from prod.ecommerce.voucher_voucherapplication
    qualify 1 < count(*) over (partition by order_id)
order by date_created desc
