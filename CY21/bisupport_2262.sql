--ticket: https://openedx.atlassian.net/browse/BISUPPORT-2262
--bundled purchasaes
--calculate the number of program purchases by quarter
select count(distinct payment_ref_id) as order_count, fb.program_id, date_trunc('quarter', order_date) as date_quarter
from prod.core.fact_booking_order_rollup fb
where not is_fully_refunded
and program_id in ('150', '405')
group by 2,3
order by date_quarter

--program certificates
--calculate the number of program certificates by quarter  
select count(*) as program_certificates, pc.program_id,date_trunc('quarter', last_program_certificate_date) as date_quarter, program_title, program_status, program_type
from prod.business_intelligence.bi_program_certificate pc
left join prod.core.dim_program dp
on pc.program_id=dp.program_id
where pc.program_id in (150,405)
group by 2,3,4,5,6
order by date_quarter
