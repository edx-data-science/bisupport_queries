/*  JIRA:  https://openedx.atlassian.net/browse/BISUPPORT-2499

Please report the number of redemptions, completions and, in which courses have the following UQx codes been redeemed for the monthly UQx coupon report:
TSPU5UWLY5N556SE for Write101x
XMN7DMKPV3VWJU3R for Employ101x
GIUWK4WGPCYBZ6HU for ACE101x
7ZC7BZPAV73ULVIB for World101x

They’ve asked for the coupon reports for the following courses:
Teams101x
Health101x
*/

--*** SUMMARY TAB ********************************************************************************************************************************
with coupon_orders as (
select *
from prod.ecommerce.order_orderdiscount
where voucher_code in (
    'TSPU5UWLY5N556SE',
    'XMN7DMKPV3VWJU3R',
    'GIUWK4WGPCYBZ6HU',
    'ZC7BZPAV73ULVIB'
    )
)
select distinct a.voucher_code
      ,c.COURSERUN_KEY, count(c.ENROLLMENT_ID) as cnt
from coupon_orders a
left join prod.ecommerce.order_line b
on a.order_id=b.order_id
left join prod.core.core_imd_transaction_orderline_enrollment c
 on b.id=c.order_line_id
group by c.COURSERUN_KEY, a.voucher_code
;


--*** DETAIL TAB ****************************************************************************************************
with coupon_orders as (
    select *
    from prod.ecommerce.order_orderdiscount
    where voucher_code in (
        'TSPU5UWLY5N556SE',
        'XMN7DMKPV3VWJU3R',
        'GIUWK4WGPCYBZ6HU',
        'ZC7BZPAV73ULVIB'
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

--*** COUPON USAGE FOR SPECIFIC COURSES *******************************************************************************
select d.COURSE_KEY
    , d.COURSERUN_TITLE
    , a.voucher_code          as coupon_code
    , count(*)
from prod.ecommerce.order_orderdiscount a
         left join prod.ecommerce.order_line b
                   on a.order_id = b.order_id
         left join prod.core.core_imd_transaction_orderline_enrollment c
                   on b.id = c.order_line_id
         left join prod.core.DIM_COURSEruns d
                   on c.COURSERUN_KEY = d.COURSerun_key
         left join prod.ecommerce.voucher_voucherapplication e
                   on a.order_id = e.order_id
                       and a.voucher_id = e.voucher_id
where course_key IN (
    'UQx+Teams101x',
    'UQx+HEALTH101x'
    )
and nullif(coupon_code,'') <> ''
group by d.course_key, d.courserun_title, coupon_code
;
