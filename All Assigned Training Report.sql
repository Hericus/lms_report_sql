SELECT
    result.userid  "Id",
    result.firstname  "First Name",
    result.lastname  "Last Name",
    result.email  "Email",
    result.company  "Company",
    result.employeenumber  "Employee Number",
    result.course  "Course",
    result.original  "Original Completion Date",
    result.recent  "Most Recent Completion Date",
    CASE
        WHEN result.status = 1 THEN 'Completed'
        WHEN result.status = 2 THEN '<span class="text-warning"><strong>Coming due</strong></span>'
        WHEN result.status = 3 THEN '<span class="text-danger"><strong>Overdue</strong></span>'
        END  "Status",
    result.duration  "Duration",
    result.expiration  "Expiration Date",
    result.sso  "SSO",
    result.lob  "LOB",
    result.region  "Region"
FROM
    (
        SELECT
            u.id  "userid",
            u.firstname  "firstname",
            u.lastname  "lastname",
            u.email  "email",
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
          AND u.id = %%USERID%%


            %%FILTER_SUBCATEGORIES:cc.path%%
%%FILTER_COURSES:c.id%%
        ORDER BY u.lastname ASC

    ) AS result
WHERE 1 = 1

    %%FILTER_SQL_status:result.status:=%%