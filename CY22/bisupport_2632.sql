-- from bisupport_2501
-- bisupport_2632
select sum(order_discount_amount)::decimal(18, 2)                                                  as total_financial_assistance
     , count(distinct order_lms_user_id)                                                           as learner_count
     , count(distinct order_id)                                                                    as order_count
     , dc.country_code
     , dc.country_name
     , date_trunc(month, cito.order_timestamp)::date                                               as order_month
     , 'FY' || right(left(date_trunc(year, dateadd(months, 6, order_month))::date::varchar, 4), 2) as old_fiscal_year
from prod.core.core_imd_transaction_orderline as cito
     left join prod.core.dim_country          as dc
               on dc.country_code = cito.address_country_code
where voucher_product_category_slug = 'financial-assistance'
  and zeroifnull(order_refunded_amount) = 0
group by dc.country_code
       , dc.country_name
       , order_month
order by order_month, country_code
