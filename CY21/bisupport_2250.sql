--Can we get an updated list of students that have completed courses/the SCM program?
--
--The report will allow us to see the size of the ASU SCM funnel.
--
--We need additional data about MIT SCM MicroMasters program. The courses in the program are:
--Supply Chain Technology and Systems
--Supply Chain Dynamics
--Supply Chain Design
--Supply Chain Fundamentals
--Supply Chain Analytics
--Supply Chain Comprehensive Exam
--
--Can we also have another column for those categories that is the number of learners who have a cumulative 80% in the program?
--
--Anybody who is eligible for the Capstone in March that has received a B or better in each course (we can include any historic completers on file, as well)
--
with prog_completers as (
    select user_id, floor(pct_complete_of_program) as program
    from prod.business_intelligence.bi_program_completion bip
         inner join prod.core.dim_program                 dp
                    on bip.program_id = dp.program_id
    where bip.program_type = 'MicroMasters'
      and bip.program_id = 59
),

letter_grades as (
    select user_id
   , "'MITx+CTL.SC3x'" as   "LetterGrade_MITx+CTL.SC3x"
   , "'MITx+CTL.SC2x'" as   "LetterGrade_MITx+CTL.SC2x"
   , "'MITx+CTL.SC0x'" as   "LetterGrade_MITx+CTL.SC0x"
   , "'MITx+CTL.SC4x'" as   "LetterGrade_MITx+CTL.SC4x"
   , "'MITx+CTL.CFx'" as    "LetterGrade_MITx+CTL.CFx"
   , "'MITx+CTL.SC1x_1'" as "LetterGrade_MITx+CTL.SC1x_1"
    from
   ( select bc.user_id
   , dc.course_key
   , bc.letter_grade
   , pc.program_id
    from
    prod.business_intelligence.bi_course_completion bc
    inner join prod.core.program_courserun_all pc on bc.courserun_id = pc.courserun_id
    inner join prod.core.dim_courseruns dc on pc.courserun_id = dc.courserun_id
    )
    pivot (max(letter_grade) for course_key in ('MITx+CTL.SC3x'
   , 'MITx+CTL.SC2x'
   , 'MITx+CTL.SC0x'
   , 'MITx+CTL.SC4x'
   , 'MITx+CTL.CFx'
   , 'MITx+CTL.SC1x_1'))
    where program_id = 59
    ) ,
  percent_grades as (
select user_id
     ,"'MITx+CTL.SC3x'" as "PercentGrade_MITx+CTL.SC3x"
     ,"'MITx+CTL.SC2x'" as "PercentGrade_MITx+CTL.SC2x"
     ,"'MITx+CTL.SC0x'" as "PercentGrade_MITx+CTL.SC0x"
     ,"'MITx+CTL.SC4x'" as "PercentGrade_MITx+CTL.SC4x"
     ,"'MITx+CTL.CFx'"  as "PercentGrade_MITx+CTL.CFx"
     ,"'MITx+CTL.SC1x_1'" as "PercentGrade_MITx+CTL.SC1x_1"
from
    (select  pcg.user_id,dc.course_key,pcg.percent_grade,pc.program_id
    from prod.lms.GRADES_PERSISTENTCOURSEGRADE pcg
        inner join prod.core.dim_courseruns dc on pcg.course_id = dc.courserun_key
        inner join prod.core.program_courserun_all pc on dc.courserun_id = pc.courserun_id
    )
    pivot (max(percent_grade) for course_key in ('MITx+CTL.SC3x','MITx+CTL.SC2x','MITx+CTL.SC0x','MITx+CTL.SC4x','MITx+CTL.CFx','MITx+CTL.SC1x_1'))
where program_id = 59),

course_completion as (
select user_id
     ,"'MITx+CTL.SC3x'" as   "CourseCompletion_MITx+CTL.SC3x"
     ,"'MITx+CTL.SC2x'" as   "CourseCompletion_MITx+CTL.SC2x"
     ,"'MITx+CTL.SC0x'" as   "CourseCompletion_MITx+CTL.SC0x"
     ,"'MITx+CTL.SC4x'" as   "CourseCompletion_MITx+CTL.SC4x"
     ,"'MITx+CTL.CFx'"  as   "CourseCompletion_MITx+CTL.CFx"
     ,"'MITx+CTL.SC1x_1'" as "CourseCompletion_MITx+CTL.SC1x_1"
from
    (select user_id, dc.course_key, is_certified, program_id
     from prod.business_intelligence.bi_user_course_certificate bc
          inner join prod.core.program_courserun_all            pc
                     on bc.courserun_id = pc.courserun_id
          inner join prod.core.dim_courseruns                   dc
                     on bc.courserun_key = dc.courserun_key
     where program_id = 59
       and is_certified = 1
    )
    pivot (max(is_certified) for course_key in ('MITx+CTL.SC3x','MITx+CTL.SC2x','MITx+CTL.SC0x','MITx+CTL.SC4x','MITx+CTL.CFx','MITx+CTL.SC1x_1'))
where program_id = 59),

compiled_data as (
    select coalesce(prog_completers.user_id, letter_grades.user_id, percent_grades.user_id, cc.user_id) as user_id
         , coalesce("coursecompletion_mitx+ctl.sc3x", 0)     as "coursecertification_mitx+ctl.sc3x"
         , coalesce("coursecompletion_mitx+ctl.sc2x", 0)     as "coursecertification_mitx+ctl.sc2x"
         , coalesce("coursecompletion_mitx+ctl.sc0x", 0)     as "coursecertification_mitx+ctl.sc0x"
         , coalesce("coursecompletion_mitx+ctl.sc4x", 0)     as "coursecertification_mitx+ctl.sc4x"
         , coalesce("coursecompletion_mitx+ctl.cfx", 0)      as "coursecertification_mitx+ctl.cfx"
         , coalesce("coursecompletion_mitx+ctl.sc1x_1", 0)   as "coursecertification_mitx+ctl.sc1x_1"
         , coalesce(prog_completers.program,0) as program
         , coalesce("percentgrade_mitx+ctl.sc3x", 0) * 100   as "percentgrade_mitx+ctl.sc3x"
         , coalesce("percentgrade_mitx+ctl.sc2x", 0) * 100   as "percentgrade_mitx+ctl.sc2x"
         , coalesce("percentgrade_mitx+ctl.sc0x", 0) * 100   as "percentgrade_mitx+ctl.sc0x"
         , coalesce("percentgrade_mitx+ctl.sc4x", 0) * 100   as "percentgrade_mitx+ctl.sc4x"
         , coalesce("percentgrade_mitx+ctl.cfx", 0) * 100    as "percentgrade_mitx+ctl.cfx"
         , coalesce("percentgrade_mitx+ctl.sc1x_1", 0) * 100 as "percentgrade_mitx+ctl.sc1x_1"
         , "lettergrade_mitx+ctl.sc3x"
         , "lettergrade_mitx+ctl.sc2x"
         , "lettergrade_mitx+ctl.sc0x"
         , "lettergrade_mitx+ctl.sc4x"
         , "lettergrade_mitx+ctl.cfx"
         , "lettergrade_mitx+ctl.sc1x_1"
    from prog_completers
         full outer join letter_grades
                         on prog_completers.user_id = letter_grades.user_id
         full outer join percent_grades
                         on prog_completers.user_id = percent_grades.user_id
         full outer join course_completion cc
                         on prog_completers.user_id = cc.user_id
)
select au.email,cd.*
,case when
       ("percentgrade_mitx+ctl.sc3x"+"percentgrade_mitx+ctl.sc2x"+"percentgrade_mitx+ctl.sc0x"+"percentgrade_mitx+ctl.sc4x"+"percentgrade_mitx+ctl.cfx"+"percentgrade_mitx+ctl.sc1x_1")/6.0
 >=80 then 1 else 0 end as AverageGradeAbove80Percent
from compiled_data cd
    inner join prod.lms_pii.auth_user au on cd.user_id = au.id
where --"coursecompletion_mitx+ctl.sc3x"+"coursecompletion_mitx+ctl.sc2x"+"coursecompletion_mitx+ctl.sc0x"+"coursecompletion_mitx+ctl.sc4x"+"coursecompletion_mitx+ctl.cfx"+"coursecompletion_mitx+ctl.sc1x_1" >= 1
"percentgrade_mitx+ctl.sc3x"+"percentgrade_mitx+ctl.sc2x"+"percentgrade_mitx+ctl.sc0x"+"percentgrade_mitx+ctl.sc4x"+"percentgrade_mitx+ctl.cfx"+"percentgrade_mitx+ctl.sc1x_1" >= 1