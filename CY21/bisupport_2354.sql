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
    where voucher_code in (
                           'TSPU5UWLY5N556SE',-- for Write101x
                           'XMN7DMKPV3VWJU3R',-- for Employ101x
                           'GIUWK4WGPCYBZ6HU',-- for ACE101x
                           '7ZC7BZPAV73ULVIB'-- for World101x
        )
)
select distinct c.user_id
              , d.COURSE_KEY
              , d.COURSERUN_TITLE
              , a.voucher_code          as coupon_code
              , to_date(e.date_created) as redemption_date
from coupon_orders a
         left join prod.ecommerce.order_line b
                   on a.order_id = b.order_id
         left join prod.core.core_imd_transaction_orderline_enrollment c
                   on b.id = c.order_line_id
         left join prod.core.DIM_COURSEruns d
                   on c.COURSERUN_KEY = d.COURSerun_key
         left join prod.ecommerce.voucher_voucherapplication e
                   on a.order_id = e.order_id
                       and a.voucher_id = e.voucher_id
--and c.USER_ID=e.user_id  --cc this wont work bc they are different user-ids
;