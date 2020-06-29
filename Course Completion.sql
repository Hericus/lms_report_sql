SELECT
  u.firstname "Firstname",
  CONCAT('<a target="_blank" href="%%WWWROOT%%/user/profile.php?id=', u.id, '">', u.lastname,'</a>') "Lastname",
  u.email "Email",
  (
    SELECT d.data
    FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE f.shortname = 'company' AND d.userid = u.id
  ) "Company",
  u.idnumber "ID Number (SSO)",
  (
    SELECT d.data
    FROM prefix_user_info_field AS f JOIN prefix_user_info_data AS d ON f.id = d.fieldid
    WHERE f.shortname = 'employeenumber' AND d.userid = u.id
  ) "Employee Number",
  CONCAT('<a target="_blank" href="%%WWWROOT%%/course/view.php?id=', c.id, '">', c.shortname,'</a>') "Course",
  to_char(to_timestamp(p.timecompleted),'YYYY-MM-DD') "Date completed",
  (
    CASE
    WHEN p.timestarted = 0 THEN  null
    ELSE  to_char(to_timestamp(p.timestarted),'YYYY-MM-DD')
    END
  ) AS "Start date"
FROM
  prefix_course_completions AS p
  JOIN prefix_course AS c ON p.course = c.id
  JOIN prefix_course_categories cc ON c.category = cc.id
  JOIN prefix_user AS u ON p.userid = u.id
WHERE
  c.enablecompletion = 1
  AND p.timecompleted > 0
%%FILTER_SUBCATEGORIES:cc.path%%
%%FILTER_COURSES:p.course%%
%%FILTER_SEARCHTEXT_fullname:CONCAT(u.firstname, ' ', u.lastname):~ci%%
%%FILTER_SQL_cohortid:(SELECT chr.id FROM prefix_cohort AS chr JOIN prefix_cohort_members AS mem ON chr.id = mem.cohortid WHERE chr.visible = 1 AND mem.userid = u.id):in%%
%%FILTER_SQL_sqltrecords:u.suspended:=%%
ORDER BY
  u.username ASC