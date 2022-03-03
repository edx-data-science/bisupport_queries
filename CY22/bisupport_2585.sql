--bundle purchases by partner

select booking_date
     , partner_key
     , program_title
     , program_type
     , count(booking_id) as num_bundle_purchases
from fact_booking
     join program_courserun
          on fact_booking.program_id = program_courserun.program_id
where is_program_from_order = 'TRUE'
group by booking_date
       , partner_key
       , program_title
       , program_type
order by booking_date desc

