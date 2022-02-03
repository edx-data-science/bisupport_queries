--

create or replace temporary table us_state_tax_rates
(
    country_code       varchar(2),
    province_code      varchar(2),
    exclusive_tax_rate number(18, 4),
    start_date         date
)
;

insert into us_state_tax_rates (country_code, province_code, exclusive_tax_rate)
values ('US', null, 0.0000)
     , ('US', 'AA', 0.0000)
     , ('US', 'AE', 0.0000)
     , ('US', 'AK', 0.0000)
     , ('US', 'AL', 0.0000)
     , ('US', 'AP', 0.0000)
     , ('US', 'AR', 0.0000)
     , ('US', 'AS', 0.0000)
     , ('US', 'AZ', 0.0840)
     , ('US', 'CA', 0.0000)
     , ('US', 'CO', 0.0365)
     , ('US', 'CT', 0.0635)
     , ('US', 'DC', 0.0600)
     , ('US', 'DE', 0.0000)
     , ('US', 'FL', 0.0000)
     , ('US', 'GA', 0.0000)
     , ('US', 'GU', 0.0000)
     , ('US', 'HI', 0.0444)
     , ('US', 'IA', 0.0694)
     , ('US', 'ID', 0.0000)
     , ('US', 'IE', 0.0000)
     , ('US', 'IL', 0.0525)
     , ('US', 'IN', 0.0000)
     , ('US', 'KS', 0.0000)
     , ('US', 'KY', 0.0000)
     , ('US', 'LA', 0.0000)
     , ('US', 'MA', 0.0625)
     , ('US', 'MD', 0.0600)
     , ('US', 'ME', 0.0000)
     , ('US', 'MI', 0.0000)
     , ('US', 'MN', 0.0000)
     , ('US', 'MO', 0.0000)
     , ('US', 'MP', 0.0000)
     , ('US', 'MS', 0.0707)
     , ('US', 'MT', 0.0000)
     , ('US', 'NC', 0.0000)
     , ('US', 'ND', 0.0000)
     , ('US', 'NE', 0.0000)
     , ('US', 'NH', 0.0000)
     , ('US', 'NJ', 0.0000)
     , ('US', 'NM', 0.0783)
     , ('US', 'NV', 0.0000)
     , ('US', 'NY', 0.0852)
     , ('US', 'OH', 0.0723)
     , ('US', 'OK', 0.0000)
     , ('US', 'ON', 0.0000)
     , ('US', 'OR', 0.0000)
     , ('US', 'PA', 0.0634)
     , ('US', 'PR', 0.0000)
     , ('US', 'RI', 0.0700)
     , ('US', 'SC', 0.0746)
     , ('US', 'SD', 0.0640)
     , ('US', 'TN', 0.0955)
     , ('US', 'TX', 0.0654)
     , ('US', 'UT', 0.0719)
     , ('US', 'VA', 0.0000)
     , ('US', 'VI', 0.0000)
     , ('US', 'VT', 0.0000)
     , ('US', 'WA', 0.0923)
     , ('US', 'WI', 0.0000)
     , ('US', 'WV', 0.0650)
     , ('US', 'WY', 0.0000)
;

create or replace temporary table base_tax_rate as
    (
        with country           as (select * from prod.core.dim_country)
           , province          as (select * from prod.core._country_province)
           , rate_raw_blank_us as (select * from prod.core._tax_rate)
           , rate_raw          as
            (
                select *
                from rate_raw_blank_us
                where country_code <> 'US'
                union all
                select country_code
                     , province_code
                     , nullif(exclusive_tax_rate, 0)
                     , null
                from us_state_tax_rates
            )
           , rate_geo          as
            (
                select nullif(trim(rate_raw.country_code), '')  as country_code_raw
                     , nullif(trim(rate_raw.province_code), '') as province_code_raw
                     , rate_raw.tax_rate_exclusive
                     , rate_raw.start_date                      as start_date_raw
                     , country.country_code
                     , province.province_code
                     , country_code_raw is null or
                       country.country_code is null             as has_invalid_country_code
                     , (province_code_raw is not null and
                        province.province_code is null)         as has_invalid_province_code
                from rate_raw
                     left join country
                               on rate_raw.country_code = country.country_code
                     left join province
                               on rate_raw.country_code = province.country_code
                                   and rate_raw.province_code = province.province_code
            )
           , rate_time         as
            (
                select *
                     , lead(start_date_raw)
                            over (partition by country_code, province_code order by start_date_raw) - 1 as end_date_raw
                     , nvl(start_date_raw, '1900-01-01')                                                as start_date
                     , nvl(end_date_raw, '3000-01-01')                                                  as end_date
                from rate_geo
            )
           , rate              as
            (
                select *
                     , 1.0 - (1.0 / (1.0 + tax_rate_exclusive))::decimal(18, 4)  as tax_rate_inclusive
                     , 1 - ((1 + tax_rate_exclusive) * (1 - tax_rate_inclusive)) as tax_rate_inclusive_error_size
                from rate_time
            )
        select *
        from rate
    )
;

create or replace temporary table direct_purchase_tax_report as
    (
        with book_raw  as (select * from /*{{ cref('*/fact_booking/*') }}*/)
           , book_line as (select * from /*{{ cref('*/fact_booking_line_rollup/*') }}*/)
           , vats      as (select * from /*{{ cref('*/finrep_base_tax_rate/*') }}*/)
           , courserun as (select * from /*{{ cref('*/dim_courseruns/*') }}*/)
           , book      as
            (
                select book_raw.*
                     , book_line.order_date
                from book_raw
                     join book_line
                          on book_raw.order_line_hash = book_line.order_line_hash
                where book_raw.order_product_class <> 'donation'
            )
           , joined    as
            (
                select book.booking_id
                     , book.booking_amount_direct
                     , book.booking_date
                     , book.order_line_hash
                     , book.payment_ref_id
                     , case when not courserun.partner_key in ('MITx', 'HarvardX')
                                then 'Other'
                            else courserun.partner_key end                       as partner_key
                     , book.royalty_amount_b2c                                   as royalty_amount
                     , book.address_country_code                                 as country_code
                     , book.address_province_code                                as province_code
                     , nvl(vats_p.tax_rate_inclusive, vats_c.tax_rate_inclusive) as tax_rate
                     , (book.booking_amount_direct * tax_rate)::decimal(18, 2)   as tax_amount_direct
                from book
                     left join vats as vats_p
                               on book.address_country_code = vats_p.country_code
                                   and book.address_province_code = vats_p.province_code
                                   and book.order_date between vats_p.start_date and vats_p.end_date
                     left join vats as vats_c
                               on vats_p.country_code is null -- it didn't match on province
                                   and book.address_country_code = vats_c.country_code
                                   and vats_c.province_code is null
                                   and book.order_date between vats_c.start_date and vats_c.end_date
                     left join courserun
                               on nvl(book.courserun_key, book.sale_attribution_courserun_key) = courserun.courserun_key
                where book.booking_amount_direct <> 0
                  and book.order_date >= '2020-08-01' -- 18 months ago.  excludes refunds on older orders
            )
           , summary   as
            (
                select date_trunc(month, booking_date) as booking_month
                     , country_code
                     , province_code
                     , tax_rate
                     , partner_key
                     , sum(booking_amount_direct)      as booking_amount
                     , count(distinct payment_ref_id)  as order_count
                     , count(distinct order_line_hash) as order_line_count
                     , sum(tax_amount_direct)          as tax_amount
                     , sum(royalty_amount)             as original_partner_royalty_amount
                     , iff(booking_amount <> 0,
                           original_partner_royalty_amount
                               / booking_amount,
                           null)                       as avg_partner_royalty_gross_rate
                from joined
                group by booking_month
                       , country_code
                       , province_code
                       , tax_rate
                       , partner_key
            )
        select summary.*
             , dc.country_name
        from summary
             join prod.core.dim_country dc
                  on dc.country_code = summary.country_code
    )
;

create table bis2561_direct_purchase_tax_report as (select * from direct_purchase_tax_report);

