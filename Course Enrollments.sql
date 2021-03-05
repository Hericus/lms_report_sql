SELECT
    u.firstname AS Firstname
     , CONCAT('<a target="_blank" href="%%WWWROOT%%/user/profile.php?id=', u.id, '">', u.lastname,'</a>') "Lastname"
     , u.email AS Email
     , (SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'company' AND d.userid = u.id) "Company"
     , u.idnumber "ID Number (SSO)"
     , (SELECT d.data FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid WHERE f.shortname = 'employeenumber' AND d.userid = u.id) "Employee Number"
     , CONCAT('<a target="_blank" href="%%WWWROOT%%/course/view.php?id=', c.id, '">', c.fullname,'</a>') "Course"
     , (SELECT shortname FROM prefix_role WHERE id=en.roleid) AS ROLE
     , (SELECT name FROM prefix_role WHERE id=en.roleid) AS RoleName
     , (CASE  WHEN p.timestarted = 0 OR p.timestarted IS NULL THEN  NULL  ELSE  to_char(to_timestamp(p.timestarted),'YYYY-MM-DD')  END) AS "Start date"
FROM prefix_course AS c
         JOIN prefix_course_categories cc ON c.category = cc.id
         JOIN prefix_enrol AS en ON en.courseid = c.id
         JOIN prefix_user_enrolments AS ue ON ue.enrolid = en.id
         JOIN prefix_user AS u ON ue.userid = u.id
         LEFT JOIN prefix_course_completions AS p ON p.course = p.id AND p.userid = p.id
WHERE p.timecompleted IS NULL
    %%FILTER_COURSES:c.id%%
%%FILTER_SUBCATEGORIES:cc.path%%
%%FILTER_SEARCHTEXT_fullname:CONCAT(u.firstname, ' ', u.lastname):~ci%%
%%FILTER_SQL_cohortid:(SELECT chr.id FROM prefix_cohort AS chr JOIN prefix_cohort_members AS mem ON chr.id = mem.cohortid WHERE chr.visible = 1 AND mem.userid = u.id):in%%
%%FILTER_SQL_sqltrecords:u.suspended:=%%
ORDER BY
    u.lastname ASC