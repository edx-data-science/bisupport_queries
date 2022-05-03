--Ranking of the top 50 courses for each of the past 5 years (2018, 2019, 2020, 2021, 2022YTD) for paid and unpaid enrollments
-- so a (potentially largely overlapping) list for paid, and list for unpaid for each year
--They would like separate lists for each of the product lines:
--MM, MicroBach, ProfCert, XSeries, non-program, etc.
--They would like to limit these enrollments to learners in China  - and would like to see the same among all learners in not-China
--For each course identified, pls include the primary subject and course title and enrollment counts.

with enrollment as (
    select year(first_enrollment_date)                      as year
         , program_type
         , program_title
         , courserun_title                                  as course
         , primary_subject_name                             as primary_subject
         , count(enrollment_id) - count(last_verified_date) as unpaid_enrolls
         , count(last_verified_date)                        as paid_enrolls
    from core.dim_enrollments            as de
         join      core.dim_courseruns   as dc
                   on de.courserun_key = dc.courserun_key
         join      dim_users             as du
                   on de.user_id = du.user_id
         left join program_courserun_all as pc
                   on de.courserun_key = pc.courserun_key
    where year in (2018, 2019, 2020, 2021, 2022)
      and country_label != 'China'        --adjust this field for each query: china vs non china
      and program_type = 'MicroBachelors' --adjust this field for each query: product line
    group by year
           , program_type
           , program_title
           , course
           , primary_subject
    order by year desc
)

   , by_year    as (
    select *
         , row_number() over (partition by year order by paid_enrolls desc) as rank --swap out paid enrolls for unpaid when needed
    from enrollment
)

--run query without CTE and order by rank, limit 50 for top 50
--use CTE and additional query for sum total of courses outside top 50
select year
     , sum(unpaid_enrolls) as non_top_50_unpaid_enr
     , sum(paid_enrolls)   as non_top_50_paid_enr
from by_year
where rank > 50
group by year
order by year

