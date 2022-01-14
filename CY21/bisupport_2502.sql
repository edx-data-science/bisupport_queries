with a as (
    select date_trunc('month', transaction_date)            as month
         , bos_category
         , coalesce(netsuite_vertical, salesforce_vertical) as vertical
         , case when coalesce(raw_o.leadsource, l.source) in
                     ('Other', 'E-Mail Marketing', 'Organic Search', 'Direct Traffic', 'Webinar', 'Paid Search', 'Drift Chat', 'Paid Social Media',
                      'Web Referral', 'Organic Social Media', 'Web Referral')
                    then 'Marketing-Lead'
                when coalesce(raw_o.leadsource, l.source) is not null then 'sales-lead'
                else null end                               as source
         , sum(booking_amount)                              as booking_amount
         , count(b.salesforce_opportunity_id)               as count_won_opps
    from prod.enterprise._tableau_fact_enterprise_bookings_detail  b
         left join prod.enterprise.ent_base_salesforce_opportunity o
                   on b.salesforce_opportunity_id = o.opportunity_id
         left join prod.salesforce_prod_pii.opportunity            raw_o
                   on raw_o.id = o.opportunity_id
         left join prod.enterprise.ent_base_salesforce_lead        l
                   on l.converted_opportunity_id = o.opportunity_id
    where transaction_date >= '2020-1-01'
      and bos_category not in ('EXCLUDED', 'FLAG AS UNUSUAL')

    group by 1
           , 2
           , 3
           , 4
    order by 1
)
select *
from a