select count(distinct program_id)
from prod.core.program_courserun_all

with pca           as (select * from prod.core.program_courserun_all)
   , comp          as (select * from prod.business_intelligence.bi_program_completion)
   , p             as
    (
        select distinct
               program_id
             , program_title
        from pca
    )
   , c             as
    (
        select distinct
               program_id
             , program_title
             , course_id
        from pca
    )
   , course_pairs  as
    (
        select little.program_id                                                      as little_id
             , little.program_title                                                   as little_title
             , little.course_id                                                       as course_id
             , big.program_id                                                         as big_id
             , big.program_title                                                      as big_title
             , count(distinct little.course_id) over (partition by little_id)         as little_course_count
             , count(distinct little.course_id) over (partition by little_id, big_id) as both_course_count
        from c           as little
             left join c as big
                       on little.course_id = big.course_id
                           and little.program_id <> big.program_id
            qualify little_course_count = both_course_count and big_id is not null
    )
   , program_pairs as
    (
        select distinct little_id, little_title, big_id, big_title
        from course_pairs
        order by little_id
               , big_id
    )
   , comp_summ     as
    (
        select program_id
             , sum(program_completion)                                  as completion_count
        from comp
        group by program_id
    )
-- total affected
-- select count(distinct user_id)
--      , sum(program_completion)
-- from program_pairs as pp
--     join comp as pc
--         on pp.big_id = pc.program_id
-- where pc.program_completion = 1

-- summary by little program
select program_pairs.*
     , comp_summ.completion_count      as big_completion_count
from program_pairs
     left join comp_summ
               on comp_summ.program_id = program_pairs.big_id
order by big_title
