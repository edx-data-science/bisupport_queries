select sum(order_discount_amount)::decimal(18, 2)                   as total_financial_assistance
     , count(distinct order_lms_user_id)                            as learner_count
     , (total_financial_assistance / learner_count)::decimal(18, 2) as average_per_learner
     , count(distinct order_id)                                     as order_count
     , (total_financial_assistance / order_count)::decimal(18, 2)   as average_per_order
from prod.core.core_imd_transaction_orderline as cito
     left join prod.core.dim_country          as dc
               on dc.country_code = cito.address_country_code
where voucher_product_category_slug = 'financial-assistance'
  and zeroifnull(order_refunded_amount) = 0
  and dc.sub_region = 'Latin America and the Caribbean'



select dc.country_name
from prod.core.dim_country dc
where sub_region = 'Latin America and the Caribbean'
order by 1
