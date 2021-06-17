with user_courseruns as (
    select distinct user_id,courserun_id 
    from "PROD"."BUSINESS_INTELLIGENCE"."BI_COURSE_COMPLETION"
    where courserun_id in (
        7406,8182,8183,8185,8186,8187,8188,8807,9146,9175,9434,13445,13453,13456,13459,13462,13465,13468,13471,
        13477,13478,15113,24200,24234,24235,24236,24237,24238,24503,24547,24548,24550,24551,24552,24553,26537,
        26543,26605,26606,26607,26608,26609,26610,26611,26612,26614,26615,26617,26618,26619,26620,26622,27316,
        27317,27387,27552,27554,27555,27556,27780,27781,27782,28237,28458,28459,28461,29097,29098,29099,29537,
        30660,31693,31778,31781,31783,31785,31818,31819,31820,32594,32688,32742,32776,32926,32928,32929,32930,
        32931,32932,32933,32934,32935,32936,32937,32939,32940,32941,32942,32943,32945,32962,32963,32996,33298,
        33517,34188,34271,34400,34413
    )
    and passed_timestamp is not null
    and date(passed_timestamp) >=  dateadd('month', -12, current_date())
    order by user_id
)

select     
    uc.user_id,
    users.email,
    listagg(dcs.course_key, ',') as course_key_list,
    listagg(dcs.course_title, ',') as course_title_list

from user_courseruns uc
join "PROD"."CORE"."DIM_COURSERUNS" dc
      on uc.courserun_id = dc.courserun_id
join "PROD"."CORE"."DIM_COURSES" dcs
      on dc.course_id=dcs.course_id
join prod.lms_pii.auth_user users
      on uc.user_id = users.id
where  IS_SPANISH_LANGUAGE_CONTENT=0
group by uc.user_id, users.email
order by user_id
