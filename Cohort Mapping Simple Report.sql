with 
endings as (
    select
        sortorder
    from prefix_local_profilecohort
    where
        andnextrule = 0
),  
startpoints_wip as (
    select 1 as sortorder
    union select sortorder+1 from endings where sortorder <> (select max(sortorder) from endings)
),
endpoints_wip as (
    select * from endings
    union select MAX(sortorder) from prefix_local_profilecohort
),
startpoints as (
    select row_number() over (order by sortorder) as rownum, sortorder from startpoints_wip
),
endpoints as (
    select row_number() over (order by sortorder) as rownum, sortorder from endpoints_wip
),
ruleranges as (
    select
        row_number() over (order by startpoints.sortorder) as rulenumber,
        startpoints.sortorder as startpoint,
        endpoints.sortorder as endpoint
    from
        startpoints
        join endpoints on endpoints.rownum = startpoints.rownum
),
rawrules as (
    select
        r.rulenumber as rulenumber,
        lpc.matchvalue as matchvalue,
        lpc.matchtype as matchtype,
        uif.name as onfield
    from
        ruleranges r
        join prefix_local_profilecohort lpc on sortorder >= r.startpoint and sortorder <= r.endpoint
        join prefix_user_info_field uif on uif.id = lpc.fieldid
),
rules as (
    select
        r.rulenumber as rulenumber,
        r.startpoint as startpoint,
        r.endpoint as endpoint,
        (select string_agg(rr.matchvalue, ' AND ') from rawrules as rr where rr.rulenumber = r.rulenumber and onfield = 'AirTime Role' and matchtype in ('contains', 'exact')) as airtimerole,
        (select rr.matchvalue from rawrules as rr where rr.rulenumber = r.rulenumber and onfield = 'Company' and matchtype = 'exact') as company,
        (select rr.matchvalue from rawrules as rr where rr.rulenumber = r.rulenumber and onfield = 'User Country' and matchtype = 'exact') as country,
        (select rr.matchvalue from rawrules as rr where rr.rulenumber = r.rulenumber and onfield = 'Cohort List' and matchtype = 'contains') as cohortlist,
        lpc.value::BIGINT as cohortid
    from
        ruleranges as r
        join prefix_local_profilecohort lpc on lpc.sortorder = r.startpoint
)

SELECT distinct
    rules.airtimerole AS "AirTime Role",
    CONCAT(rules.company, rules.country, rules.cohortlist) as "Filter",
    c.name AS "Add to Cohort",
    course.shortname AS "Enrol in",
    CASE
        WHEN course_tied_to_compliance.intvalue = 1 THEN 'Yes'
        ELSE 'No'
    END "Tied to Compliance",
    (SELECT rc1.value::integer / 86400 FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = course.id AND rc1.name = 'recompletionduration') AS "Recompletion period in days"
FROM
    rules
    join prefix_cohort c on c.id = rules.cohortid
    left join prefix_enrol e on e.enrol='cohort' and e.customint1 = c.id
    left join prefix_course course on course.id = e.courseid
    left JOIN prefix_customfield_data course_tied_to_compliance 
        ON course_tied_to_compliance.instanceid = course.id
        AND course_tied_to_compliance.fieldid = (SELECT cf.id FROM prefix_customfield_field cf WHERE cf.shortname = 'course_tied_to_compliance')
WHERE
    1 = 1
    %%FILTER_SQL_cohort:c.id:=%%
    %%FILTER_SQL_airtimerole:rules.airtimerole:~%%
