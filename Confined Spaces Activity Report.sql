SELECT
u.lastname AS "Lastname",
u.firstname AS "Firstname",
u.email AS "Email",
c.shortname AS "Course",
CASE
   WHEN cc.timecompleted > 0 THEN to_char(to_timestamp(cc.timecompleted), 'YYYY-MM-DD')
   ELSE ''
END AS "Completed",
CASE
    WHEN cm.module = 1 THEN (SELECT a1.name FROM prefix_assign a1            WHERE a1.id = cm.instance)
    WHEN cm.module = 2 THEN (SELECT a2.name FROM prefix_assignment a2        WHERE a2.id = cm.instance)
    WHEN cm.module = 3 THEN (SELECT a3.name FROM prefix_book a3              WHERE a3.id = cm.instance)
    WHEN cm.module = 4 THEN (SELECT a4.name FROM prefix_chat a4              WHERE a4.id = cm.instance)
    WHEN cm.module = 5 THEN (SELECT a5.name FROM prefix_choice a5            WHERE a5.id = cm.instance)
    WHEN cm.module = 6 THEN (SELECT a6.name FROM prefix_data a6              WHERE a6.id = cm.instance)
    WHEN cm.module = 7 THEN (SELECT a7.name FROM prefix_feedback a7          WHERE a7.id = cm.instance)
    WHEN cm.module = 8 THEN (SELECT a8.name FROM prefix_folder a8            WHERE a8.id = cm.instance)
    WHEN cm.module = 9 THEN (SELECT a9.name FROM prefix_forum a9             WHERE a9.id = cm.instance)
    WHEN cm.module = 10 THEN (SELECT a10.name FROM prefix_glossary a10       WHERE a10.id = cm.instance)
    WHEN cm.module = 11 THEN (SELECT a11.name FROM prefix_imscp  a11         WHERE a11.id = cm.instance)
    WHEN cm.module = 12 THEN (SELECT a12.name FROM prefix_label a12          WHERE a12.id = cm.instance)
    WHEN cm.module = 13 THEN (SELECT a13.name FROM prefix_lesson a13         WHERE a13.id = cm.instance)
    WHEN cm.module = 14 THEN (SELECT a14.name FROM prefix_lti a14            WHERE a14.id = cm.instance)
    WHEN cm.module = 15 THEN (SELECT a15.name FROM prefix_page a15           WHERE a15.id = cm.instance)
    WHEN cm.module = 16 THEN (SELECT a16.name FROM prefix_quiz  a16          WHERE a16.id = cm.instance)
    WHEN cm.module = 17 THEN (SELECT a17.name FROM prefix_resource a17       WHERE a17.id = cm.instance)
    WHEN cm.module = 18 THEN (SELECT a18.name FROM prefix_scorm a18          WHERE a18.id = cm.instance)
    WHEN cm.module = 19 THEN (SELECT a19.name FROM prefix_survey a19         WHERE a19.id = cm.instance)
    WHEN cm.module = 20 THEN (SELECT a20.name FROM prefix_url a20            WHERE a20.id = cm.instance)
    WHEN cm.module = 21 THEN (SELECT a21.name FROM prefix_wiki a21           WHERE a21.id = cm.instance)
    WHEN cm.module = 22 THEN (SELECT a22.name FROM prefix_workshop a22       WHERE a22.id = cm.instance)
    WHEN cm.module = 23 THEN (SELECT a23.name FROM prefix_customcert a23     WHERE a23.id = cm.instance)
    WHEN cm.module = 24 THEN (SELECT a24.name FROM prefix_questionnaire a24  WHERE a24.id = cm.instance)
    WHEN cm.module = 25 THEN (SELECT a25.name FROM prefix_reengagement a25   WHERE a25.id = cm.instance)
    WHEN cm.module = 26 THEN (SELECT a26.name FROM prefix_facetoface a26     WHERE a26.id = cm.instance)
    WHEN cm.module = 28 THEN (SELECT a28.name FROM prefix_hvp a28            WHERE a28.id = cm.instance)
END AS "ActvityName",
CASE
   WHEN cmc.completionstate = 0 THEN 'In Progress'
   WHEN cmc.completionstate = 1 THEN 'Completed'
   WHEN cmc.completionstate = 2 THEN 'Completed with Pass'
   WHEN cmc.completionstate = 3 THEN 'Completed with Fail'
   ELSE 'No Activity'
END AS "Progress",
gg.finalgrade AS "Grade",
CASE
   WHEN cmc.timemodified > 0 THEN to_char(to_timestamp(cmc.timemodified), 'YYYY-MM-DD')
   ELSE ''
END AS "When"
FROM
    prefix_enrol e
    JOIN prefix_user_enrolments ue on e.id = ue.enrolid
    JOIN prefix_user u ON ue.userid = u.id
    JOIN prefix_course c on e.courseid = c.id
    JOIN prefix_course_modules cm ON c.id = cm.course
	LEFT OUTER JOIN prefix_course_completions cc ON c.id = cc.course and u.id = cc.userid
    JOIN prefix_modules m ON cm.module = m.id
    LEFT OUTER JOIN prefix_course_modules_completion cmc ON cm.id = cmc.coursemoduleid and u.id = cmc.userid
	LEFT OUTER JOIN prefix_grade_items gi on gi.courseid = cm.course and gi.iteminstance = cm.instance
    LEFT OUTER JOIN prefix_grade_grades gg on gg.itemid = gi.id and u.id = gg.userid
WHERE
    u.id > 2
    AND
    e.courseid IN(6652, 6916, 6606, 6917)
    AND
    cm.module != 23
%%FILTER_SEARCHTEXT_firstname:u.firstname:~%%
%%FILTER_SEARCHTEXT_lastname:u.lastname:~%%
ORDER BY
    u.lastname, u.firstname, c.shortname