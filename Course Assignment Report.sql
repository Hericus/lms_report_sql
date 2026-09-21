SELECT
    result.userid  "Id",
    result.firstname  "First Name",
    result.lastname  "Last Name",
    result.email  "Email",
    result.company  "Company",
    result.employeenumber  "Employee Number",
    result.enrollment "Course Assignment Method",
    result.course "Course",
    result.coursehours "Course Hours",

    CASE
        WHEN result.tiedtocompliance = 1 THEN 'Yes'
        ELSE 'No'
    END "Tied to Compliance",
    
    result.original  "Original Completion Date",
    result.recent  "Most Recent Completion Date",
    
    CASE
        WHEN result.optionalroleid is not NULL THEN 'Optional'
        WHEN result.status = 1 THEN 'Completed'
        WHEN result.status = 2 THEN '<span class="text-warning"><strong>Coming due</strong></span>'
        WHEN result.status = 3 THEN (
            CASE
                WHEN result.tiedtocompliance = 1 THEN '<span class="text-danger"><strong>Out of compliance</strong></span>'
                ELSE '<span class="text-danger"><strong>Past Due</strong></span>'
            END
        )
    END  "Status",

    result.duration  "Duration",
    result.expiration  "Expiration Date",
    result.sso  "SSO",
    result.lob  "LOB",
    result.region  "Region",
    result.manager  "Manager",
    result.mandiv  "Manager Division",
    result.cohort  "Cohort",
    
    CASE
        WHEN result.airtimerole like '%Superintendent%' OR result.airtimerole like '%Clerk%' OR result.airtimerole like '%Site Accountant%' OR result.airtimerole like '%Scheduler%' THEN (
            CASE
                WHEN result.jobstatus = 'Yes' THEN 'Deployed'
                ELSE 'Standby'
            END
        )
        ELSE 'N/A'
    END  "Job Status",
    
    CASE
        WHEN result.activesup = 'Yes' THEN 'Yes'
        ELSE 'No'
    END  "Active Sup",
    
    CASE
        WHEN result.hiredate IS NULL THEN  NULL
        WHEN result.hiredate::double precision = 1 THEN  'User missing'
        WHEN result.hiredate::double precision = -1 THEN  'Date mising'
        ELSE  to_char(to_timestamp(result.hiredate::double precision),'YYYY-MM-DD')
    END "Hire date",

    result.airtimerole "Role",
    
    CASE
        WHEN result.optionalroleid is NULL THEN 'Required'
        ELSE 'Optional'
    END "Course Assignment Level"
FROM
(
    SELECT
        u.id  "userid",
        u.firstname  "firstname",
        u.lastname  "lastname",
        u.email  "email",
        course_tied_to_compliance.intvalue as "tiedtocompliance",
        uf.company as "company",
        uf.employeenumber as "employeenumber",
        enr.enrollment AS "enrollment",
        CONCAT('<a href="/course/view.php?id=', c.id, '">', c.fullname, '</a>') "course",
        to_char(to_timestamp(cached.originalcomp), 'YYYY-MM-DD') "original",
        to_char(to_timestamp(cached.latestcomp), 'YYYY-MM-DD') "recent",

        CASE
            WHEN cached.latestcomp IS NULL THEN
            (
                SELECT
                CASE
                    WHEN cfggrace.value::bigint > 0 AND
                    (
                        enr.lastenrolled + cfggrace.value::bigint > extract( epoch from now() )
                    ) THEN 2
                    ELSE 3
                END
            )
            WHEN cfgenable.value = 'period' AND cfgrecompletiondur.value IS NOT NULL THEN
            (
                SELECT
                CASE
                    WHEN cached.latestcomp + cached.latestduration < extract(epoch from now()) THEN 3
                    WHEN cached.latestcomp + cached.latestduration - cached.latestnotify < extract(epoch from now()) THEN 2
                    ELSE 1
                END
            )
            WHEN cached.latestcomp IS NOT NULL THEN 1
        END "status",

        CASE
            WHEN cfgenable.value = 'period' AND (cached.latestduration = 31449600 OR cached.latestduration = 31622400) THEN 'Annual'
            WHEN cfgenable.value = 'period' AND (cached.latestduration = 62899200 OR cached.latestduration = 63158400) THEN 'Biennial'
            WHEN cfgenable.value = 'period' AND (cached.latestduration = 94348800 OR cached.latestduration = 94694400) THEN 'Triennial'
        END "duration",

        CASE
            WHEN cached.latestcomp IS NULL THEN
            (
                SELECT
                CASE
                    WHEN cfggrace.value::bigint > 0
                    THEN to_char( to_timestamp(enr.lastenrolled + cfggrace.value::bigint), 'YYYY-MM-DD' )
                    ELSE NULL
                END
            )
            WHEN cfgenable.value = 'period' AND cfgrecompletiondur.value IS NOT NULL THEN to_char(to_timestamp(cached.latestcomp + cached.latestduration), 'YYYY-MM-DD')
            ELSE NULL
        END "expiration",

        u.idnumber  "sso",
        uf.lob as "lob",
        uf.region  "region",
        CONCAT(manuser.firstname, ' ', manuser.lastname) as "manager",
        uf.mandiv as "mandiv",
        cohort.name "cohort",
        uf.jobstatus as "jobstatus",
        uf.airtimerole "airtimerole",
        uf.activesup as "activesup",
        uf.hiredate as "hiredate",
        course_hours.value as "coursehours",
        raopt.id as "optionalroleid"

    FROM
        prefix_user_enrolments AS ue
        JOIN prefix_enrol AS e ON ue.enrolid = e.id
        JOIN prefix_course AS c ON c.id = e.courseid
        JOIN prefix_course_categories cc ON c.category = cc.id
        JOIN prefix_user AS u ON u.id = ue.userid
        LEFT JOIN prefix_cohort cohort ON cohort.id = e.customint1
        LEFT JOIN prefix_customfield_data course_tied_to_compliance ON course_tied_to_compliance.instanceid = c.id AND course_tied_to_compliance.fieldid = (SELECT cf.id FROM prefix_customfield_field cf WHERE cf.shortname = 'course_tied_to_compliance')
        LEFT JOIN prefix_local_recompletion_cc_cached cached ON cached.userid = u.id AND cached.courseid = c.id
        LEFT JOIN prefix_local_recompletion_config cfgenable ON cfgenable.course = c.id AND cfgenable.name = 'recompletiontype'
        LEFT JOIN prefix_local_recompletion_config cfgrecompletiondur ON cfgrecompletiondur.course = c.id AND cfgrecompletiondur.name = 'recompletionduration'
        LEFT JOIN prefix_local_recompletion_config cfggrace ON cfggrace.course = c.id AND cfggrace.name = 'graceperiod'
        LEFT JOIN (
            SELECT d.userid,
                max(d.data) FILTER (WHERE f.shortname = 'company')            AS company,
                max(d.data) FILTER (WHERE f.shortname = 'employeenumber')     AS employeenumber,
                max(d.data) FILTER (WHERE f.shortname = 'lobname')            AS lob,
                max(d.data) FILTER (WHERE f.shortname = 'region')             AS region,
                max(d.data) FILTER (WHERE f.shortname = 'mandiv')             AS mandiv,
                max(d.data) FILTER (WHERE f.shortname = 'job_status')         AS jobstatus,
                max(d.data) FILTER (WHERE f.shortname = 'airtimerole')        AS airtimerole,
                max(d.data) FILTER (WHERE f.shortname = 'active_sup')         AS activesup,
                max(d.data) FILTER (WHERE f.shortname = 'managerid')          AS managerid,
                max(d.data) FILTER (WHERE f.shortname = 'original_hire_date') AS hiredate
            FROM prefix_user_info_data d
            JOIN prefix_user_info_field f ON f.id = d.fieldid
            WHERE f.shortname IN ('company','employeenumber','lobname','region','mandiv',
                                  'job_status','airtimerole','active_sup','managerid',
                                  'original_hire_date')
            GROUP BY d.userid
        ) uf ON uf.userid = u.id
        LEFT JOIN prefix_user manuser ON manuser.id = NULLIF(uf.managerid, '')::bigint
        LEFT JOIN prefix_customfield_data AS course_hours ON course_hours.instanceid = c.id AND course_hours.fieldid = (SELECT cf.id FROM prefix_customfield_field cf WHERE cf.shortname = 'course_length')
        LEFT JOIN (
            SELECT ue2.userid, e2.courseid,
               string_agg(DISTINCT e2.enrol, ', ')                             AS enrollment,
               max(GREATEST(ue2.timecreated, ue2.timestart, ue2.timemodified)) AS lastenrolled
            FROM prefix_user_enrolments ue2
            JOIN prefix_enrol e2 ON e2.id = ue2.enrolid
            GROUP BY ue2.userid, e2.courseid
        ) enr ON enr.userid = u.id AND enr.courseid = c.id
        LEFT JOIN prefix_context ctx50 ON ctx50.contextlevel = 50 AND ctx50.instanceid = c.id
        LEFT JOIN prefix_role_assignments raopt ON raopt.contextid = ctx50.id AND raopt.userid = u.id AND raopt.roleid = (SELECT id FROM prefix_role WHERE shortname = 'studentoptional')

    WHERE
        e.status = 0 AND ue.status = 0
        AND c.enablecompletion = 1
        AND c.visible = 1
        
        AND u.email not like '%@hericus.com'
        and uf.airtimerole  not like '%LEAVE_OF_ABSENCE%'

        %%FILTER_SUBCATEGORIES:cc.path%%
        %%FILTER_COURSES:c.id%%
        %%FILTER_SEARCHTEXT_fullname:CONCAT(u.firstname, ' ', u.lastname):~ci%%
        %%FILTER_SQL_company:(SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'company' AND d.userid = u.id):~%%
        %%FILTER_SQL_lob:(SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'lobname' AND d.userid = u.id):~%%
        %%FILTER_SEARCHTEXT_craftnumber:(SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'craftnumber' AND d.userid = u.id):~ci%%
        %%FILTER_SQL_cohortid:e.customint1:rin%%
        %%FILTER_SQL_region:(SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'region' AND d.userid = u.id):rin%%
        %%FILTER_SQL_sqltrecords:u.suspended:=%%
        %%FILTER_SQL_manager:mandata.data:=%%
) AS result

WHERE 1 = 1

    %%FILTER_SQL_status:result.status:=%%
ORDER BY lastname asc, firstname asc, employeenumber asc