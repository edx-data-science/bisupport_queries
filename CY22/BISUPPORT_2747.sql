with customer_uuid   as (
    select enterprise_customer_uuid
    from prod.enterprise.ent_base_enterprise_customer
    where enterprise_customer_name in (
                                       'NSHM Knowledge Campus', 'iLEAD', 'Technische Universität München', 'R.M.D. Engineering College',
                                       'Indian Institute of Technology Bombay', 'Tecnológico de Monterrey', 'Universitat Politècnica de València',
                                       'Universidad Galileo', 'Pontificia Universidad Javeriana', 'Loyola College', 'Ankara University',
                                       'Western Governors University', 'M.Kumarasamy College of Engineering', 'Wageningen University',
                                       'Pontificia Universidad Católica del Peru', 'KIET Group of Institutions',
                                       'Walchand Institute of Technology, Solapur', 'Anáhuac Universidad', 'HALmanagement Academy',
                                       'Institute of Engineering & Management', 'Middle East Technical University',
                                       'Hooghly Engineering & Technology College'
        )
)
   , primary_contact as
    (
        select distinct
               customer.enterprise_customer_name
             , contact_role.contactid as contact_id
             , contact.name           as contact_name
             , contact.email          as contact_email
        from prod.salesforce_prod_pii.opportunitycontactrole           contact_role
             left join prod.enterprise.ent_base_salesforce_opportunity opp
                       on opp.opportunity_id = contact_role.opportunityid
             left join prod.salesforce_prod_pii.contact                contact
                       on contact.id = contact_role.contactid
             left join prod.enterprise.ent_base_enterprise_customer    customer
                       on customer.enterprise_customer_uuid = opp.enterprise_customer_uuid
        where contact_role.isprimary
          and not contact_role.isdeleted
          and opp.enterprise_customer_uuid in (select enterprise_customer_uuid from customer_uuid)
          and opp.is_online_campus_free
    )
   , admin_contact   as (
    select customer.enterprise_customer_name
         , up.first_name || ' ' || up.last_name as contact_name
         , up.email                             as contact_email
         , 'admin'                              as contact_type
    from prod.enterprise.dim_enterprise_admin                   admin
         left join prod.enterprise.ent_base_enterprise_customer customer
                   on customer.enterprise_customer_uuid = admin.enterprise_customer_uuid
         left join prod.core_pii.corepii_user_profile           up
                   on up.user_id = admin.lms_user_id
    where admin.enterprise_customer_uuid in (select enterprise_customer_uuid from customer_uuid)
)
   , contact_union   as (
    select enterprise_customer_name
         , contact_name
         , contact_email
         , contact_type
    from admin_contact
    union
    select enterprise_customer_name
         , contact_name
         , contact_email
         , 'salesforce primary contact'
    from primary_contact
)
select *
from contact_union
order by enterprise_customer_name