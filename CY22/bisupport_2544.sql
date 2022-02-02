-- Hi There,
-- Delft is asking WHY 3 courses are missing (raised concern for Q1-FY22 Report)
-- and if we can make sure they are back on the Q2 reports: DelftX+BMI.2x+3T2019;DelftX+BMI.3x+3T2019, DelftX+BMI.4x+3T2019.
-- Important to note that Feedback was for Q1-FY22 report but I have reviewed
-- reports Q2-FY21, Q3-FY21, Q4-FY21 and Q1-FY22 which are all missing the mentioned courses. Please review.
-- Finance has asked for me to open this ticket for your support please.

create or replace temporary table targetcr as
    (
        select v.*
             , cr.courserun_id
        from (values ('course-v1:DelftX+BMI.2x+3T2019')
                   , ('course-v1:DelftX+BMI.3x+3T2019')
                   , ('course-v1:DelftX+BMI.4x+3T2019')) as v (courserun_key)
             join prod.core.dim_courseruns                  cr
                  on cr.courserun_key = v.courserun_key
    )
;

select *
from targetcr

-- Q: are these even mentioned in the dimension?
-- A: yes

select organization_key, courserun_key, end_datetime, *
from prod.financial_reporting.finrep_royalty_order_dimension
where courserun_key in (select courserun_key from targetcr)

-- +--------------------------------+--------------------------------------+
-- | COURSERUN_KEY                  | END_DATETIME                         |
-- +--------------------------------+--------------------------------------+
-- | course-v1:DelftX+BMI.2x+3T2019 | 2021-01-05 12:00:00.000000000 +00:00 |
-- | course-v1:DelftX+BMI.3x+3T2019 | 2021-01-05 12:00:00.000000000 +00:00 |
-- | course-v1:DelftX+BMI.4x+3T2019 | 2021-01-05 12:00:00.000000000 +00:00 |
-- +--------------------------------+--------------------------------------+

-- Q: what have their end dates been in the past? (sneakily from revrec stuff, but it shouldn't matter
-- A: nothing too interesting

select *
from prod.financial_reporting.finrep_courserun_historical_dates
where courserun_id in (select courserun_id from targetcr)
order by courserun_id
       , extent_start


select *
from prod.financial_reporting.finrep_courserun_session
where courserun_id in (select courserun_id from targetcr)
order by courserun_id
       , open_timestamp
-- +-----------+--------------+--------------------------------------+-------------+------------+--------------------------------------+-------------------+----------------------+
-- | OPEN_TYPE | COURSERUN_ID | OPEN_TIMESTAMP                       | PACING_TYPE | CLOSE_TYPE | CLOSE_TIMESTAMP                      | CLOSE_PACING_TYPE | COURSERUN_SESSION_ID |
-- +-----------+--------------+--------------------------------------+-------------+------------+--------------------------------------+-------------------+----------------------+
-- | start     |        16940 | 2019-11-01 12:00:00.000000000 +00:00 | self_paced  | end        | 2021-01-05 12:00:00.000000000 +00:00 | self_paced        | -4346977347818185100 |
-- | start     |        16941 | 2019-11-01 12:00:00.000000000 +00:00 | self_paced  | end        | 2021-01-05 12:00:00.000000000 +00:00 | self_paced        | -3285509241593911019 |
-- | start     |        16942 | 2019-11-01 12:00:00.000000000 +00:00 | self_paced  | end        | 2021-01-05 12:00:00.000000000 +00:00 | self_paced        |  1461965737439996619 |
-- +-----------+--------------+--------------------------------------+-------------+------------+--------------------------------------+-------------------+----------------------+


-- Q: when did they show up on reports, according to our archive?
-- A: all the time

select count(*)
     , "COURSE ID"
     , report_archive_timestamp
from prod.financial_reporting_archive.finrep_royalty_order_report_archive
where "COURSE ID" in (select courserun_key from targetcr)
  and report_archive_timestamp > '2020-01-01'
group by "COURSE ID"
       , report_archive_timestamp
order by 3 desc
       , 2
;

-- +----------+--------------------------------+--------------------------------------+
-- | COUNT(*) | COURSE ID                      | REPORT_ARCHIVE_TIMESTAMP             |
-- +----------+--------------------------------+--------------------------------------+
-- |        1 | course-v1:DelftX+BMI.2x+3T2019 | 2021-02-05 18:13:11.255000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.3x+3T2019 | 2021-02-05 18:13:11.255000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.4x+3T2019 | 2021-02-05 18:13:11.255000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.2x+3T2019 | 2021-01-05 20:14:51.128000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.3x+3T2019 | 2021-01-05 20:14:51.128000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.4x+3T2019 | 2021-01-05 20:14:51.128000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.2x+3T2019 | 2020-12-15 16:49:01.831000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.3x+3T2019 | 2020-12-15 16:49:01.831000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.4x+3T2019 | 2020-12-15 16:49:01.831000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.2x+3T2019 | 2020-12-08 01:46:49.617000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.3x+3T2019 | 2020-12-08 01:46:49.617000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.4x+3T2019 | 2020-12-08 01:46:49.617000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.2x+3T2019 | 2020-11-03 20:31:24.055000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.3x+3T2019 | 2020-11-03 20:31:24.055000000 +00:00 |
-- |        1 | course-v1:DelftX+BMI.4x+3T2019 | 2020-11-03 20:31:24.055000000 +00:00 |
-- +----------+--------------------------------+--------------------------------------+

-- but I looked in the xlsx output and they are not there :(


-- Q: and the export view?
-- A: NO! why?!

alter session set QUOTED_IDENTIFIERS_IGNORE_CASE = true;

select count(*)
     , "COURSE ID"
from prod.financial_reporting_archive.finrep_royalty_order_report_archive_export_view
where "COURSE ID" in (select courserun_key from targetcr)
group by "COURSE ID"
order by 2

-- the only difference is that max timestamp thing!
-- oops -- i was misreading 2021 for 2022
-- so it wouldn't show in the current report
-- what made it stop appear in output starting in Feb of 2021?

-- doens't appear here
select *
from prod.financial_reporting.finrep_royalty_order_report
where "COURSE ID" = 'course-v1:DelftX+BMI.2x+3T2019'

-- looking at the dimension
select uniqueuuid
     , appears_in_intermediate_courserun_report
from prod.financial_reporting.finrep_royalty_order_dimension
where courserun_key = 'course-v1:DelftX+BMI.2x+3T2019'

-- +--------------------------------------+------------------------------------------+
-- | UNIQUEUUID                           | APPEARS_IN_INTERMEDIATE_COURSERUN_REPORT |
-- +--------------------------------------+------------------------------------------+
-- | 5732423b-6f78-432c-9162-591ddd33a08c | false                                    |
-- +--------------------------------------+------------------------------------------+

-- what is that again?
-- with courserun_finance_oldmethod        as (select * from /*{{cref('*/_finrep_courserun_finance_oldmethod/*')}}*/ )
--    , intermediate_courserun_after2019q3 as (select * from /*{{cref('*/finrep_intermediate_courserun_after2019q3/*')}}*/ )
-- select cfo.organization_key
--      , cfo.courserun_key
-- from courserun_finance_oldmethod as cfo
-- union
-- select icr.organization_key
--      , icr.courserun_key
-- from intermediate_courserun_after2019q3 as icr

select *
from prod.core._finrep_courserun_finance_oldmethod
where courserun_key = 'course-v1:DelftX+BMI.2x+3T2019'

select *
from prod.financial_reporting.finrep_intermediate_courserun_after2019q3
where courserun_key = 'course-v1:DelftX+BMI.2x+3T2019'

select start_datetime
from prod.financial_reporting.finrep_map_organization_course_courserun
where courserun_key = 'course-v1:DelftX+BMI.2x+3T2019'


select dc.courserun_key
     , extent_start as update_timestamp
     , run_start    as courserun_start_date
     , run_end
from prod.financial_reporting.finrep_courserun_historical_dates crhd
     join prod.core.dim_courseruns                              dc
          on dc.courserun_id = crhd.courserun_id
where crhd.courserun_id in (select courserun_id from targetcr)
order by 1,2
