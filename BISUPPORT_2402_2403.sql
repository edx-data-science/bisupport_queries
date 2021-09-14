-- BISUPP-2402 -- https://openedx.atlassian.net/browse/BISUPPORT-2402
-- BISUPP-2403 -- https://openedx.atlassian.net/browse/BISUPPORT-2403
-- Output is here - https://drive.google.com/drive/u/0/folders/1T_ZXxw6mfTCV5F1b2IL1Z0sH0lULuY9E
--
-- Could you please pull a list of learners including email addresses and user IDs for any learner who completed a MicroMasters program or Professional Certificate
-- within the time frame below:
--
-- 1. February 2020 - August 2020
-- 2. February 2021 - July 2021
--
-- Could you please remove any non-English language programs and create a separate list for MM completers and PC completers?

with dim_enrollments as (select * from prod.core.dim_enrollments)
   , dim_courseruns as (select * from prod.core.dim_courseruns)
   , program_courserun as (select * from prod.core.program_courserun where program_type in ('Professional Certificate', 'MicroMasters') )
   , course_completion as (select * from prod.business_intelligence.bi_course_completion)
   , distinct_program_course as
       (
       select distinct program_type
            , program_title
            , program_id
            , course_id
            , partner_key as org
       from program_courserun
   )
   , courses_in_program as
       (
       select program_type
            , program_title
            , program_id
            , count(distinct course_id) as cnt_courses_in_program
       from program_courserun
       group by program_type
              , program_title
              , program_id
   )
   , program_completion_stg as
       (
       select uc.user_id
            , pc.program_type
            , pc.program_title
            , pc.program_id
            , pc.org
            , case when max(cc.passed_timestamp) is not null and max(cc.letter_grade) != '' then 1 else 0 end as has_passed
            , max(cc.passed_timestamp) as last_pass_time
       from dim_enrollments uc
             join dim_courseruns cm
                  on uc.courserun_id = cm.courserun_id
             join distinct_program_course pc
                 on cm.course_id = pc.course_id
            left join course_completion cc
                 on uc.user_id = cc.user_id
                    and uc.courserun_key = cc.courserun_key
       group by uc.user_id
              , cm.course_id
              , pc.program_type
              , pc.program_title
              , pc.program_id
              , pc.org
   )
   , completed_programs as
       (
       select pcs.user_id
            , pcs.program_type
            , pcs.program_title
            , pcs.org
            , sum(pcs.has_passed) = cp.cnt_courses_in_program as program_completion
            , max(pcs.last_pass_time)::date as program_completion_time
       from program_completion_stg pcs
            join courses_in_program cp
                 on pcs.program_id = cp.program_id
       group by pcs.user_id
              , pcs.program_type
              , pcs.program_title
              , pcs.program_id
              , cp.cnt_courses_in_program
              , pcs.org
)
select --distinct program_title, org
    cp.user_id
    , au.email
    , cp.program_type
    , cp.program_title
    , cp.org
    --, cp.program_completion
    --, cp.program_completion_time
from completed_programs cp
join prod.lms_pii.auth_user au
     on cp.user_id = au.id
where program_completion
    and (org not in ('AnahuacX', 'UNCordobaX', 'logycaX', 'JaverianaX', 'URosarioX')
    and program_title not in ('Innovación y emprendimiento',
            'Ciencia de Datos',
            'Empresas familiares: emprendimiento y liderazgo para trascender',
            'Análisis de datos para la toma de decisiones empresariales',
            'Fundamentals of Project Management',
            'Fundamentos de Microsoft Office para la empresa',
            'Análisis y Visualización de Datos con Excel',
            'Introducción a la programación en C',
            'Fundamentos de Inteligencia Artificial',
            'Sustentabilidad energética y la smart grid',
            'Habilidades profesionales: negociación y liderazgo',
            'Liderazgo y trabajo en equipo en grupos de mejora continua',
            'Habilidades cuantitativas esenciales en finanzas, negocios y ciencia de datos',
            'Excel para los negocios',
            'Gestión Pública para el Desarrollo',
            'Electrónica básica',
            'Introducción a la programación en Java',
            'Fundamentos TIC para profesionales de negocios',
            'Gérer son personnel de façon efficace',
            'e-Learning: crea actividades y contenidos para la enseñanza virtual',
            'Arquitectura sostenible: Evaluación interdisciplinar',
            'Automóviles eléctricos',
            'Ciencia de datos con Python',
            'Data Visualization: Analisi dei dati con Tableau',
            'Herramientas TIC para la educación',
            'IBM: Ciencia de datos',
            'IBM: Fundamentos de ciencia de datos',
            'Inteligencia artificial aplicada',
            'Inteligencia de negocios',
            'Marketing digital y redes sociales',
            'Métodos de enseñanza y educación efectiva',
            'Transformación digital como estrategia de negocios e innovación',
            'Desarrollo y gestión de proyectos informáticos'
                             )
    )
and program_type = 'MicroMasters' -- 'Professional Certificate'
and program_completion_time between '2021-02-01' and '2021-07-31' --'2020-02-01' and '2020-08-31'
order by program_title
