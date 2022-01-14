-- https://openedx.atlassian.net/browse/BISUPPORT-2495
-- Request a list of all registered learners who reside in Michigan.
-- code copied from
-- https://github.com/edx/warehouse-transforms/blob/master/projects/automated/raw_to_source/models/downstream_sources/user_ip_country/user_last_location_country.sql

with user_latest_ip_address as (
    select * from "PROD"."EVENT_SOURCES"."user_latest_ip_address"
),
geoip_ipv4_blocks as (
    select * from "PROD"."CORE_SOURCES"."GEOIP_IPV4_BLOCKS"
),
geoip_city_locations as (
    select * from "PROD"."CORE_SOURCES"."GEOIP_CITY_LOCATIONS" where country_name = 'United States' and subdivision_1_iso_code = 'MI'
),
geoip_ipv6_blocks as (
    select * from "PROD"."CORE_SOURCES"."GEOIP_IPV6_BLOCKS"
),
latest_user_ip_address as (
    select
        user_id,
        ip_address,
        parse_ip(ip_address, 'INET', 1):ipv4::number(38,0) as ipv4,
        try_to_number(
            parse_ip(ip_address, 'INET', 1):hex_ipv6::string,
            'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        )::number(38,0) as ipv6,
        parse_ip(ip_address, 'INET', 1):family::number(38,0) as family
    from
        user_latest_ip_address
    where
        ipv4 is not null
        or ipv6 is not null
    qualify row_number() over (partition by user_id order by event_datetime desc) = 1
),
country_by_ipv4_address as (
    select
        user_ip.user_id,
        city.city_name,
        subdivision_1_iso_code as state,
        city.country_name
    from
        latest_user_ip_address as user_ip
    inner join
        geoip_ipv4_blocks as blocks
    on
        user_ip.family = blocks.PARSED_IP:family::number(38,0)
        and user_ip.ipv4 between blocks.ipv4_range_start and blocks.ipv4_range_end
    inner join
        geoip_city_locations as city
    on
        city.geoname_id = blocks.geoname_id
    where
        user_ip.ipv4 is not null
        --and user_last_location_country != ''
),
country_by_ipv6_address as (
    select
        user_ip.user_id,
        city.city_name,
        subdivision_1_iso_code as state,
        city.country_name
    from
        latest_user_ip_address as user_ip
    inner join
        geoip_ipv6_blocks as blocks
    on
        user_ip.family = blocks.PARSED_IP:family::number(38,0)
        and user_ip.ipv6 between
            try_to_number(blocks.hex_ipv6_range_start, 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')::number(38,0)
            and
            try_to_number(blocks.hex_ipv6_range_end, 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')::number(38,0)
    inner join
        geoip_city_locations as city
    on
        city.geoname_id = blocks.geoname_id
    where
        user_ip.ipv6 is not null
        --and user_last_location_country != ''
),
X as (
    select *
    from country_by_ipv4_address
    union all
    select *
    from country_by_ipv6_address
)
select X.*, pro.email
from X
inner join prod.core_pii.corepii_user_profile pro
on X.user_id = pro.user_id;