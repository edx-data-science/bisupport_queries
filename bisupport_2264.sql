--Could I get list of the Affiliates that were used/charged for the past two quarters for Queens University? They have asked for a detailed report if possible.
--https://openedx.atlassian.net/browse/BISUPPORT-2264 

--CC --> let's add site-name here so we know the affiliate-site for marketing purposes
select *
from finrep_fee_courserun
where lower(event_type)='affiliate_fee'
and courserun_key ilike '%queens%' --cc better to join to partner and filter to queensx 

--***********************************************************************************************************
with awt as (select * from /*{{cref('*/finrep_base_affiliate_window_transactions/*')}}*/ )
   , pfa as (select * from /*{{cref('*/finrep_policy_fee_affiliate/*')}}*/ )
   , deduped_awt as (
    select awt.id
         , awt.order_ref                                       as order_ref
         , coalesce(awt.validation_date, awt.transaction_date) as transaction_date
         , awt.sale_amount                                     as sale_amount
         , awt.commission_amount                               as commission_amount
         , awt.site_name
    from awt
    where awt.commission_status not in ('deleted', 'declined')
      and awt.type <> 'bonus'
      and awt.sale_amount > 0
      and coalesce(awt.validation_date, awt.transaction_date) > '2018-09-30'
    group by awt.id
           , awt.order_ref
           , awt.transaction_date
           , awt.validation_date
           , awt.sale_amount
           , awt.commission_amount
           , awt.site_name
    order by awt.id
)
   , finrep_base_affiliate_transactions_modified as (
    select awt.id                                                            as affiliate_transaction_id
         , awt.order_ref                                                     as order_number
         , awt.transaction_date
         , cast((awt.sale_amount) as decimal(12, 2))                         as sale_amount
         , cast((awt.commission_amount / awt.sale_amount) as decimal(12, 2)) as commission_pct
         , cast((awt.commission_amount) as decimal(12, 2))                   as commission_amount
         , cast((pfa.fee_pct) as decimal(12, 2))                             as service_fee_pct
         , cast((awt.commission_amount * pfa.fee_pct) as decimal(12, 2))     as service_fee_amount
         , awt.site_name                                                     as affiliate_site
    from deduped_awt awt
             join pfa
                  on pfa.vendor_code = 'awin-service-fee'
)
   , intermediate_transaction_orderline_enrollment as (select *
                                                       from /*{{cref('*/finrep_intermediate_transaction_orderline_enrollment/*')}}*/ )
   , temp_per_item_amounts as
    (
        select itoe.uniqueid
             , itoe.transaction_amount_per_item * awt.commission_pct                       as commission_amount_per_item
             , itoe.transaction_amount_per_item * awt.commission_pct *
               awt.service_fee_pct                                                         as service_fee_amount_per_item
             , awt.transaction_date
             , awt.affiliate_site
        from finrep_base_affiliate_transactions_modified awt
                 left join intermediate_transaction_orderline_enrollment itoe
                           on itoe.payment_ref_id = awt.order_number
    )
   , queens_fees as (select itoe.courserun_key
                          , to_date(tpia.transaction_date)                                          as transaction_date
                          , cast(
            (tpia.commission_amount_per_item + tpia.service_fee_amount_per_item) as decimal(12, 2)) as total_affiliate_fee
                          , iff(tpia.affiliate_site is null, 'maybe awin', tpia.affiliate_site)     as affiliate_site
                     from intermediate_transaction_orderline_enrollment itoe
                              join temp_per_item_amounts tpia
                                   on tpia.uniqueid = itoe.uniqueid
                     where itoe.transaction_type in ('sale', 'course-entitlement')
                       and itoe.order_refunded_quantity = 0
                       and itoe.courserun_key is not null
                       and itoe.courserun_key ilike '%queens%'
)
select *
from queens_fees
;