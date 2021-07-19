SELECT
    result.userid  "Id",
    result.firstname  "First Name",
    result.lastname  "Last Name",
    result.email  "Email",
    result.company  "Company",
    result.employeenumber  "Employee Number",
    result.enrollment "Course Assignment Method",
    result.course "Course",
	CASE
		WHEN result.tiedtocompliance = 1 THEN 'Yes'
		ELSE 'No'
	END "Tied to Compliance",
    result.original  "Original Completion Date",
    result.recent  "Most Recent Completion Date",
    CASE
        WHEN result.status = 1 THEN 'Completed'
        WHEN result.status = 2 THEN '<span class="text-warning"><strong>Coming due</strong></span>'
        WHEN result.status = 3 THEN '<span class="text-danger"><strong>Out of compliance</strong></span>'
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
	result.airtimerole "Role"
FROM
    (
    SELECT
    u.id  "userid",
    u.firstname  "firstname",
    u.lastname  "lastname",
    u.email  "email",
    course_tied_to_compliance.intvalue as "tiedtocompliance",
    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f
    JOIN
    prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'company' AND d.userid = u.id
    )  "company",
    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f
    JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'employeenumber' AND d.userid = u.id
    )  "employeenumber",
    (
        SELECT string_agg(e.enrol, ', ')
        FROM prefix_user_enrolments AS ue JOIN prefix_enrol AS e ON ue.enrolid = e.id
        WHERE ue.userid = u.id and e.courseid = c.id
        ) AS "enrollment",
    CONCAT('<a href="/course/view.php?id=', c.id, '">', c.fullname, '</a>') "course",
    to_char(to_timestamp(cached.originalcomp), 'YYYY-MM-DD') "original",
    to_char(to_timestamp(cached.latestcomp), 'YYYY-MM-DD') "recent",
    CASE
    WHEN cached.latestcomp IS NULL THEN
    (
    SELECT
    CASE
    WHEN cfggrace.value::bigint > 0 AND
    ((SELECT MAX(GREATEST(ue2.timecreated, ue2.timestart, ue2.timemodified))
    FROM prefix_user_enrolments ue2 JOIN prefix_enrol e2 ON e2.id = ue2.enrolid
    WHERE e2.courseid = c.id AND ue2.userid = u.id) + cfggrace.value::bigint > extract(epoch from now())) THEN 2
    ELSE 3
    END
    )
    WHEN cfgenable.value = '1' AND cfgrecompletiondur.value IS NOT NULL THEN
    (
    SELECT
    CASE
    WHEN cached.latestcomp + cached.latestduration < extract(epoch from now()) THEN 3
    WHEN cached.latestcomp + cached.latestduration -
    cached.latestnotify < extract(epoch from now()) THEN 2
    ELSE 1
    END
    )
    WHEN cached.latestcomp IS NOT NULL THEN 1
    END "status",
    CASE
    WHEN cfgenable.value = '1' AND cached.latestduration = 31449600 THEN 'Annual'
    WHEN cfgenable.value = '1' AND cached.latestduration = 62899200 THEN 'Biennial'
    WHEN cfgenable.value = '1' AND cached.latestduration = 94348800 THEN 'Triennial'
    END "duration",
    CASE
    WHEN cached.latestcomp IS NULL THEN
    (
    SELECT
    CASE
    WHEN cfggrace.value::bigint > 0
    THEN to_char(to_timestamp(
    (SELECT MAX(GREATEST(ue2.timecreated, ue2.timestart, ue2.timemodified))
    FROM prefix_user_enrolments ue2
    JOIN prefix_enrol e2 ON e2.id = ue2.enrolid
    WHERE e2.courseid = c.id AND ue2.userid = u.id) + cfggrace.value::bigint), 'YYYY-MM-DD')
    ELSE NULL
    END
    )
    WHEN cfgenable.value = '1' AND cfgrecompletiondur.value IS NOT NULL THEN
    to_char(to_timestamp(cached.latestcomp + cached.latestduration), 'YYYY-MM-DD')
    ELSE NULL
    END "expiration",
    u.idnumber  "sso",
    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'lobname' AND d.userid = u.id
    )  "lob",
    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'region' AND d.userid = u.id
    )  "region",
    (
    SELECT
    CONCAT(manuser.firstname, ' ', manuser.lastname)
    FROM
    prefix_user manuser WHERE mandata.data <> '' AND manuser.id = mandata.data::bigint
    ) "manager",
    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f
    JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'mandiv' AND d.userid = u.id
    ) "mandiv",

    cohort.name "cohort",

    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f
    JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'job_status' AND d.userid = u.id
    ) "jobstatus",
    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f
    JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'airtimerole' AND d.userid = u.id
    ) "airtimerole",
    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f
    JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'active_sup' AND d.userid = u.id
    ) "activesup",
    (
    SELECT
    d.data
    FROM
    prefix_user_info_field AS f
    JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE
    f.shortname = 'original_hire_date' AND d.userid = u.id
    ) "hiredate"
    FROM
    prefix_user_enrolments AS ue
    JOIN prefix_enrol AS e ON ue.enrolid = e.id
    JOIN prefix_course AS c ON c.id = e.courseid
    JOIN prefix_course_categories cc ON c.category = cc.id
    JOIN prefix_user AS u ON u.id = ue.userid
    JOIN prefix_cohort cohort ON cohort.id = e.customint1
    LEFT JOIN prefix_customfield_data course_tied_to_compliance ON course_tied_to_compliance.instanceid = c.id AND course_tied_to_compliance.fieldid = (SELECT cf.id FROM prefix_customfield_field cf WHERE cf.shortname = 'course_tied_to_compliance')
    LEFT JOIN prefix_local_recompletion_cc_cached cached ON cached.userid = u.id AND cached.courseid = c.id
    LEFT JOIN prefix_local_recompletion_config cfgenable ON cfgenable.course = c.id AND cfgenable.name = 'enable'
    LEFT JOIN prefix_local_recompletion_config cfgrecompletiondur ON cfgrecompletiondur.course = c.id AND cfgrecompletiondur.name = 'recompletionduration'
    LEFT JOIN prefix_local_recompletion_config cfggrace ON cfggrace.course = c.id AND cfggrace.name = 'graceperiod'
    LEFT JOIN prefix_user_info_field AS manfield ON manfield.shortname = 'managerid'
    LEFT JOIN prefix_user_info_data AS mandata ON mandata.fieldid = manfield.id AND mandata.userid = u.id
    WHERE
        e.enrol = 'cohort' AND e.status = 0 AND ue.status = 0
        AND c.enablecompletion = 1
        AND c.visible = 1

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
        ORDER BY u.lastname ASC

        ) AS result
    WHERE 1 = 1

        %%FILTER_SQL_status:result.status:=%%