-- Ticket: https://openedx.atlassian.net/browse/BISUPPORT-2294
-- Files: https://drive.google.com/drive/u/0/folders/1NnsVphZvo-c_cYayNVT9izezDMvelOkz

-- Braze needs user_ids to send emails. I uploaded the file attached to the ticket
-- to Snowflake via DataGrip. The file has email addresses and used that to find the user_id.

-- 1. Import file via DataGrip
delete from user_data.djacob."6TH ROUND OF REJECTIONS" where email is null;
-- 161

Select count(*) from user_data.djacob."6TH ROUND OF REJECTIONS";
-- 838

select * From prod.core_pii.corepii_user_profile limit 10;

Select batch.*, prof.user_id
from user_data.djacob."6TH ROUND OF REJECTIONS" batch
left join prod.core_pii.corepii_user_profile prof
on lower(batch.email) = lower(prof.email)
--where prof.email is null
--126 emails that do no exist in CORE
;
