/*  JIRA:  https://openedx.atlassian.net/browse/BISUPPORT-2554
    File:  https://drive.google.com/drive/u/0/folders/1VdyPpBNt-w-IU4g8_j_v6HzLXHhJNF89

LouvainX offers enrollment codes to current students and they would like to get some data in regards to these coupons.
They're mainly interested in the number of redemptions, completions and, in which courses have these codes been redeemed.
Please see the coupon codes below:
*/


--*** SUMMARY TAB ********************************************************************************************************************************
with coupon_orders as (
    select *
    from prod.ecommerce.order_orderdiscount
    where voucher_code in (
                           'RB3TYFZJV2JFRVAL',
                           'DCN6MHJ7HTUD65NR',
                           'CE3E24VBQ7JSNBBZ',
                           'ORZJLCLTLR2QPG3Q',
                           'VW5V4WMJOIM3FCH2',
                           'RFIUPSE6LPRQT663',
                           '6JB4JZWTE7ZII3BJ',
                           '6PAHLTSXCH272C7K',
                           '7KQZ6ZDQG2SYAKGL',
                           'KHRWSO4JKDTKLMJB',
                           'JBBAV6HQWVCEEMNT',
                           'IULEFTBXV6GJ622M',
                           'A33WGAWSXQBSFRP7',
                           'L7XLC5ZMFCONFZTA',
                           'COPCMNWUGJA3AGNW',
                           'NV2UHOIRTJ3IS2T7',
                           'DM4337C74ESZOIXP',
                           'XMIZ5CBWO5NHITY5',
                           'VATBXH2ENTM3W3R4',
                           'ZNVVTYY6RXMD2Z5Y',
                           'NPOVR3VMS2AJWQBZ',
                           'Z6MWHUPOCSLTUGNT',
                           'BPA6T4HHKRXELWZZ',
                           'D6UM7VIQAYUBKAVK',
                           'OGZBGFERILNRCC6N',
                           '72OK2NLTEFHOHL6M',
                           'GBKJJG6M73SAN7XW',
                           'XVKZ3HDFLIFI2XEF'
        )
)
select distinct
       a.voucher_code
     , c.courserun_key
     , count(c.enrollment_id) as cnt
from coupon_orders                                                 a
     left join prod.ecommerce.order_line                           b
               on a.order_id = b.order_id
     left join prod.core.core_imd_transaction_orderline_enrollment c
               on b.id = c.order_line_id
group by c.courserun_key
       , a.voucher_code
;


--*** DETAIL TAB ****************************************************************************************************
with coupon_orders as (
    select *
    from prod.ecommerce.order_orderdiscount
    where voucher_code in (
                           'RB3TYFZJV2JFRVAL',
                           'DCN6MHJ7HTUD65NR',
                           'CE3E24VBQ7JSNBBZ',
                           'ORZJLCLTLR2QPG3Q',
                           'VW5V4WMJOIM3FCH2',
                           'RFIUPSE6LPRQT663',
                           '6JB4JZWTE7ZII3BJ',
                           '6PAHLTSXCH272C7K',
                           '7KQZ6ZDQG2SYAKGL',
                           'KHRWSO4JKDTKLMJB',
                           'JBBAV6HQWVCEEMNT',
                           'IULEFTBXV6GJ622M',
                           'A33WGAWSXQBSFRP7',
                           'L7XLC5ZMFCONFZTA',
                           'COPCMNWUGJA3AGNW',
                           'NV2UHOIRTJ3IS2T7',
                           'DM4337C74ESZOIXP',
                           'XMIZ5CBWO5NHITY5',
                           'VATBXH2ENTM3W3R4',
                           'ZNVVTYY6RXMD2Z5Y',
                           'NPOVR3VMS2AJWQBZ',
                           'Z6MWHUPOCSLTUGNT',
                           'BPA6T4HHKRXELWZZ',
                           'D6UM7VIQAYUBKAVK',
                           'OGZBGFERILNRCC6N',
                           '72OK2NLTEFHOHL6M',
                           'GBKJJG6M73SAN7XW',
                           'XVKZ3HDFLIFI2XEF'
        )
)
select distinct
       c.user_id
     , d.course_key
     , d.courserun_title
     , a.voucher_code          as coupon_code
     , to_date(e.date_created) as redemption_date
from coupon_orders                                                 a
     left join prod.ecommerce.order_line                           b
               on a.order_id = b.order_id
     left join prod.core.core_imd_transaction_orderline_enrollment c
               on b.id = c.order_line_id
     left join prod.core.dim_courseruns                            d
               on c.courserun_key = d.courserun_key
     left join prod.ecommerce.voucher_voucherapplication           e
               on a.order_id = e.order_id
                   and a.voucher_id = e.voucher_id
--and c.USER_ID=e.user_id  --cc this wont work bc they are different user-ids
;