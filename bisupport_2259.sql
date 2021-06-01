-- This is for the work in ticket: https://openedx.atlassian.net/browse/BISUPPORT-2259
-- Basically, Eric just wants the final product of this ticket: https://openedx.atlassian.net/browse/BISUPPORT-2079
-- but expanded for more subjects (medicine, biology & life sciences, food & nutrition, health and safety, and chemistry)

create or replace table user_data.thelbig.bisupport_2259_engagement_base as
with clean_dim_users as (
    select
        user_id,
        coalesce(education_level, 'missing') as education_level,
        coalesce(gender, 'missing') as gender,
        coalesce(country_label, 'missing') as country_selfid,
        case
          when country_selfid IN ('United States of America', 'India', 'Mexico', 'Brazil', 'United Kingdom of Great Britain and Northern Ireland', 'Colombia',
                      'Canada', 'Nigeria', 'Spain', 'Egypt', 'missing')
          then country_selfid
          else 'Other'
        end country_selfid_top10,
        FLOOR(DATEDIFF(year, to_date(to_varchar(year_of_birth), 'YYYY'), account_created_at)) age_at_reg,
        CASE
          WHEN age_at_reg BETWEEN 18 AND 22
          THEN '18 - 22'
          WHEN age_at_reg BETWEEN 23 AND 35
          THEN '23 - 35'
          WHEN age_at_reg BETWEEN 36 AND 50
          THEN '36 - 50'
          WHEN age_at_reg BETWEEN 51 AND 65
          THEN '51 - 65'
          WHEN age_at_reg BETWEEN 66 AND 100
          THEN '66+'
          WHEN age_at_reg is NULL
          THEN 'missing'
          ELSE 'Other'
        END age_category
    from
        prod.core.dim_users
    where
        not is_staff
        and not is_superuser
        and not is_retired
),
second_engagement as (
    select
        user_id,
        courserun_key,
        second_engagement_date
    from
        prod.core.fact_enrollment_engagement
    where
        second_engagement_date is not null
)
select
    cdu.*,
    se.courserun_key,
    coalesce(dc.primary_subject_name, 'missing') as primary_subject_name,
    coalesce(dc.primary_subject_name, 'missing') in ('medicine', 'biology-life-sciences', 'food-nutrition', 'health-safety', 'chemistry') as is_healthcare_engagement
from
    second_engagement as se
    join clean_dim_users as cdu
        on se.user_id = cdu.user_id
    join prod.core.dim_courseruns as dc
        on se.courserun_key = dc.courserun_key
    join prod.core.dim_enrollments as de
        on se.user_id = de.user_id
        and se.courserun_key = de.courserun_key
where
    second_engagement_date >= to_date('2020-01-01')
    and second_engagement_date < to_date('2021-01-01')
    and dc.reporting_type not in ('demo', 'test') -- get rid of demo/test courseruns
    and not dc.is_whitelabel -- no whitelabel ccourseruns
    and lower(dc.partner_key) != 'edx' -- no internal edx courses
    and not de.is_enterprise_enrollment -- eliminate b2b enrollments



-- I'll make an aggregate/pivotable table

create or replace table user_data.thelbig.bisupport_2259_engagement_aggregate as
select
    gender,
    age_category,
    country_selfid_top10,
    education_level,
    count(distinct case when is_healthcare_engagement then user_id else null end) healthcare_learner_demo_count,
    count(distinct user_id) all_learner_demo_count
from
    user_data.thelbig.bisupport_2259_engagement_base
group by 
    1, 2, 3, 4
