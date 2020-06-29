SELECT result.userid         "Id",
       result.firstname      "First Name",
       result.lastname       "Last Name",
       result.email          "Email",
       result.company        "Company",
       result.employeenumber "Employee Number",
       result.course         "Course",
       result.original       "Original Completion Date",
       result.recent         "Most Recent Completion Date",
       CASE
           WHEN result.status = 1 THEN 'Completed'
           WHEN result.status = 2 THEN '<span class="text-warning"><strong>Coming due</strong></span>'
           WHEN result.status = 3 THEN '<span class="text-danger"><strong>Out of compliance</strong></span>'
           END               "Status",
       result.expiration     "Expiration Date",
       result.sso     "SSO",
       result.lob     "LOB",
       result.region     "Region"
FROM (
         SELECT u.id                                                                    "userid",
                u.firstname                                                             "firstname",
                u.lastname                                                              "lastname",
                u.email                                                                 "email",
                (SELECT d.data
                 FROM prefix_user_info_field AS f
                          JOIN prefix_user_info_data AS d ON f.id = d.fieldid
                 WHERE f.shortname = 'company'
                   AND d.userid = u.id)                                                 "company",
                (SELECT d.data
                 FROM prefix_user_info_field AS f
                          JOIN prefix_user_info_data AS d ON f.id = d.fieldid
                 WHERE f.shortname = 'employeenumber'
                   AND d.userid = u.id)                                                 "employeenumber",
                CONCAT('<a href="/course/view.php?id=', c.id, '">', c.fullname, '</a>') "course",
                (SELECT to_char(to_timestamp(MIN(comp.timecompleted)), 'YYYY-MM-DD')
                 FROM (SELECT *, '0' AS archived
                       FROM prefix_course_completions AS cc
                       UNION
                       SELECT *, '1' AS archived
                       FROM prefix_local_recompletion_cc AS lc) comp
                 WHERE comp.timecompleted > 0
                   AND comp.userid = u.id
                   AND comp.course IN (SELECT DISTINCT coursesraw.courseid
                                       FROM (SELECT cone.courseoneid as "courseid"
                                             FROM prefix_local_recompletion_equiv cone
                                             WHERE cone.coursetwoid = c.id
                                             UNION
                                             SELECT ctwo.coursetwoid as "courseid"
                                             FROM prefix_local_recompletion_equiv ctwo
                                             WHERE ctwo.courseoneid = c.id
                                             UNION
                                             SELECT c.id as "courseid") "coursesraw"))  "original",
                (SELECT to_char(to_timestamp(MAX(comp.timecompleted)), 'YYYY-MM-DD')
                 FROM (SELECT *, '0' AS archived
                       FROM prefix_course_completions AS cc
                       UNION
                       SELECT *, '1' AS archived
                       FROM prefix_local_recompletion_cc AS lc) comp
                 WHERE comp.timecompleted > 0
                   AND comp.userid = u.id
                   AND comp.course IN (SELECT DISTINCT coursesraw.courseid
                                       FROM (SELECT cone.courseoneid as "courseid"
                                             FROM prefix_local_recompletion_equiv cone
                                             WHERE cone.coursetwoid = c.id
                                             UNION
                                             SELECT ctwo.coursetwoid as "courseid"
                                             FROM prefix_local_recompletion_equiv ctwo
                                             WHERE ctwo.courseoneid = c.id
                                             UNION
                                             SELECT c.id as "courseid") "coursesraw"))  "recent",
                CASE
                    WHEN corecomp.id IS NULL AND maxlrcc.id IS NULL THEN 3
                     WHEN cfgenable.value = '1' AND cfgrecompletiondur.value IS NOT NULL THEN
                     (SELECT CASE
                                WHEN maxlrcc.id IS NOT NULL THEN
                                (SELECT CASE
                                            WHEN maxlrcc.timecompleted + cfgrecompletiondur.value::bigint < extract(epoch from now()) THEN 3
                                            WHEN maxlrcc.timecompleted + cfgrecompletiondur.value::bigint -
                                                                                               (SELECT cfg.value::bigint
                                                                                                FROM prefix_local_recompletion_config AS cfg
                                                                                                WHERE cfg.course = c.id
                                                                                                  AND cfg.name = 'notificationstart') < extract(epoch from now()) THEN 2
                                            ELSE 1
                                            END)
                                ELSE (SELECT CASE
                                            WHEN corecomp.timecompleted + cfgrecompletiondur.value::bigint < extract(epoch from now()) THEN 3
                                            WHEN corecomp.timecompleted + cfgrecompletiondur.value::bigint -
                                                                                               (SELECT cfg.value::bigint
                                                                                                FROM prefix_local_recompletion_config AS cfg
                                                                                                WHERE cfg.course = c.id
                                                                                                  AND cfg.name = 'notificationstart') < extract(epoch from now()) THEN 2
                                            ELSE 1
                                            END)
                                END)
                     ELSE 1
                    END                                                                 "status",
                CASE
					WHEN corecomp.id IS NULL AND maxlrcc.id IS NULL THEN NULL
					WHEN cfgenable.value = '1' AND cfgrecompletiondur.value IS NOT NULL THEN
					(
						SELECT
						CASE
							WHEN maxlrcc.id IS NOT NULL AND (corecomp.id IS NULL OR (maxlrcc.timecompleted > corecomp.timecompleted)) THEN to_char(to_timestamp(maxlrcc.timecompleted + cfgrecompletiondur.value::bigint), 'YYYY-MM-DD')
							ELSE to_char(to_timestamp(corecomp.timecompleted + cfgrecompletiondur.value::bigint), 'YYYY-MM-DD')
						END
					)
					ELSE NULL
  					END     "expiration",
                u.idnumber  "sso",
                (SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'lobname' AND d.userid = u.id)  "lob",
                (SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'region' AND d.userid = u.id)  "region"
         FROM prefix_user_enrolments AS ue
                  JOIN prefix_enrol AS e ON ue.enrolid = e.id
                  JOIN prefix_course AS c ON c.id = e.courseid
  				  JOIN prefix_customfield_data course_tied_to_compliance ON course_tied_to_compliance.instanceid = c.id AND course_tied_to_compliance.fieldid = (SELECT cf.id FROM prefix_customfield_field cf WHERE cf.shortname = 'course_tied_to_compliance')
                  JOIN prefix_course_categories cc ON c.category = cc.id
                  JOIN prefix_user AS u ON u.id = ue.userid
                  LEFT JOIN prefix_course_completions corecomp ON corecomp.id = (SELECT maxcorecomp.id
                                                                                 FROM prefix_course_completions maxcorecomp
                                                                                 WHERE maxcorecomp.timecompleted IS NOT NULL
                                                                                   AND maxcorecomp.timecompleted > 0
                                                                                   AND maxcorecomp.userid = u.id
                                                                                   AND maxcorecomp.course IN
                                                                                       (SELECT DISTINCT coursesraw.courseid
                                                                                        FROM (SELECT cone.courseoneid as "courseid"
                                                                                              FROM prefix_local_recompletion_equiv cone
                                                                                              WHERE cone.coursetwoid = c.id
                                                                                              UNION
                                                                                              SELECT ctwo.coursetwoid as "courseid"
                                                                                              FROM prefix_local_recompletion_equiv ctwo
                                                                                              WHERE ctwo.courseoneid = c.id
                                                                                              UNION
                                                                                              SELECT c.id as "courseid") "coursesraw")
                                                                                 ORDER BY maxcorecomp.timecompleted DESC
                                                                                 LIMIT 1)
                  LEFT JOIN prefix_local_recompletion_config cfgenable
                            ON cfgenable.course = c.id AND cfgenable.name = 'enable'
                  LEFT JOIN prefix_local_recompletion_config cfgrecompletiondur
                            ON cfgrecompletiondur.course = c.id AND cfgrecompletiondur.name = 'recompletionduration'
                LEFT JOIN prefix_local_recompletion_cc maxlrcc ON maxlrcc.timecompleted > corecomp.timecompleted AND maxlrcc.userid = u.id AND maxlrcc.course IN
                                                                                            (SELECT DISTINCT coursesraw.courseid
                                                                                             FROM (SELECT cone.courseoneid as "courseid"
                                                                                                   FROM prefix_local_recompletion_equiv cone
                                                                                                   WHERE cone.coursetwoid = c.id
                                                                                                   UNION
                                                                                                   SELECT ctwo.coursetwoid as "courseid"
                                                                                                   FROM prefix_local_recompletion_equiv ctwo
                                                                                                   WHERE ctwo.courseoneid = c.id
                                                                                                   UNION
                                                                                                   SELECT c.id as "courseid") "coursesraw")
         WHERE e.enrol = 'cohort' AND e.status = 0 AND ue.status = 0
           AND c.enablecompletion = 1
           AND c.visible = 1
  		   AND u.id = %%USERID%%
           AND course_tied_to_compliance.intvalue = 1

%%FILTER_SUBCATEGORIES:cc.path%%
%%FILTER_COURSES:c.id%%
%%FILTER_SEARCHTEXT_fullname:CONCAT(u.firstname, ' ', u.lastname):~ci%%
%%FILTER_SQL_company:(SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'company' AND d.userid = u.id):~%%
%%FILTER_SQL_lob:(SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'lobname' AND d.userid = u.id):~%%
%%FILTER_SEARCHTEXT_craftnumber:(SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'craftnumber' AND d.userid = u.id):~ci%%
%%FILTER_SQL_cohortid:(SELECT chr.id FROM prefix_cohort AS chr JOIN prefix_cohort_members AS mem ON chr.id = mem.cohortid WHERE chr.visible = 1 AND mem.userid = u.id):in%%
%%FILTER_SQL_region:(SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'region' AND d.userid = u.id):rin%%
%%FILTER_SQL_sqltrecords:u.suspended:=%%
         ORDER BY u.lastname ASC
     ) AS result
WHERE 1 = 1
%%FILTER_SQL_status:result.status:=%%

