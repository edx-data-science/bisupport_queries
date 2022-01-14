/*  JIRA:  https://openedx.atlassian.net/browse/BISUPPORT-2490
    File: https://drive.google.com/drive/u/0/folders/1jQqybOgfridho_c2MUaVq-RW9xhL3Oyd

LouvainX offers enrollment codes to current students and they would like to get some data in regards to these coupons.
They're mainly interested in the number of redemptions, completions and, in which courses have these codes been redeemed.
Please see the coupon codes below:
*/


--*** SUMMARY TAB ********************************************************************************************************************************
with coupon_orders as (
select *
from prod.ecommerce.order_orderdiscount
where voucher_code in (
    '6JB4JZWTE7ZII3BJ',
    'ZNVVTYY6RXMD2Z5Y',
    'OGZBGFERILNRCC6N',
    'A33WGAWSXQBSFRP7',
    'CE3E24VBQ7JSNBBZ',
    'XVKZ3HDFLIFI2XEF',
    'JBBAV6HQWVCEEMNT',
    'RFIUPSE6LPRQT663',
    'Z6MWHUPOCSLTUGNT',
    'BPA6T4HHKRXELWZZ',
    'GBKJJG6M73SAN7XW',
    'RB3TYFZJV2JFRVAL',
    '72OK2NLTEFHOHL6M',
    'VW5V4WMJOIM3FCH2',
    'L7XLC5ZMFCONFZTA',
    'KHRWSO4JKDTKLMJB',
    'DCN6MHJ7HTUD65NR',
    '6PAHLTSXCH272C7K',
    '7KQZ6ZDQG2SYAKGL',
    'ORZJLCLTLR2QPG3Q',
    'VATBXH2ENTM3W3R4',
    'NPOVR3VMS2AJWQBZ',
    'XMIZ5CBWO5NHITY5',
    'NV2UHOIRTJ3IS2T7',
    'DM4337C74ESZOIXP',
    'COPCMNWUGJA3AGNW',
    'D6UM7VIQAYUBKAVK',
    'IULEFTBXV6GJ622M'
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
    '6JB4JZWTE7ZII3BJ',
    'ZNVVTYY6RXMD2Z5Y',
    'OGZBGFERILNRCC6N',
    'A33WGAWSXQBSFRP7',
    'CE3E24VBQ7JSNBBZ',
    'XVKZ3HDFLIFI2XEF',
    'JBBAV6HQWVCEEMNT',
    'RFIUPSE6LPRQT663',
    'Z6MWHUPOCSLTUGNT',
    'BPA6T4HHKRXELWZZ',
    'GBKJJG6M73SAN7XW',
    'RB3TYFZJV2JFRVAL',
    '72OK2NLTEFHOHL6M',
    'VW5V4WMJOIM3FCH2',
    'L7XLC5ZMFCONFZTA',
    'KHRWSO4JKDTKLMJB',
    'DCN6MHJ7HTUD65NR',
    '6PAHLTSXCH272C7K',
    '7KQZ6ZDQG2SYAKGL',
    'ORZJLCLTLR2QPG3Q',
    'VATBXH2ENTM3W3R4',
    'NPOVR3VMS2AJWQBZ',
    'XMIZ5CBWO5NHITY5',
    'NV2UHOIRTJ3IS2T7',
    'DM4337C74ESZOIXP',
    'COPCMNWUGJA3AGNW',
    'D6UM7VIQAYUBKAVK',
    'IULEFTBXV6GJ622M'
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