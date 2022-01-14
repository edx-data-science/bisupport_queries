-- Ticket: https://openedx.atlassian.net/browse/BISUPPORT-2269
-- Files: https://drive.google.com/drive/u/0/folders/1sFtsCMAXEg-ys5wDQKGdoIrmlXudXtfL

-- Braze needs user_ids to send emails. I uploaded the file attached to the ticket
-- to Snowflake via DataGrip. The file has email addresses and used that to find the user_id.

-- 1. Import file via DataGrip

Select count(*) from user_data.djacob."5th batch";
-- 1673

select * From prod.core_pii.corepii_user_profile limit 10;

Select batch.*, prof.user_id
from user_data.djacob."5th batch" batch
left join prod.core_pii.corepii_user_profile prof
on lower(batch.email) = lower(prof.email)
--where prof.email is null
--180 emails that do no exist in CORE

