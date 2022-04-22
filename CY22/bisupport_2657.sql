--quarterly email surveys for program completers

select bpc.user_id
     , first_name
     , last_name
     , email
     , program_type
     , program_title
     , program_status
     , first_program_certificate_date as certificate_earned
from bi_program_certificate             as bpc
     join core.dim_program              as dp
          on bpc.program_id = dp.program_id
     join core_pii.corepii_user_profile as cp
          on bpc.user_id = cp.user_id
where first_program_certificate_date between '2021-02-01' and '2021-04-01' --date range will be specified by requester
  and program_type = 'Professional Certificate' --change for each list based on product line

   