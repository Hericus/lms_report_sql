SELECT u.id as userid, u.firstname, u.lastname, c.id as courseid, c.fullname, to_char(to_timestamp(MAX(slog.timecreated)), 'YYYY-MM-DD HH:MI') as activitycompletion, MAX(slog.timecreated) as rawtimestamp,
       to_char(to_timestamp((SELECT MAX(cc.timecompleted)
                             FROM (
                                      SELECT course, userid, timecompleted FROM {course_completions}
                                      UNION
                                      SELECT course, userid, timecompleted FROM {local_recompletion_cc}
                                  ) cc
                             WHERE cc.course = c.id AND cc.userid = u.id)), 'YYYY-MM-DD HH:MI') as coursecompletion
FROM {user} u
JOIN {logstore_standard_log} slog ON slog.userid = u.id AND slog.eventname = '\mod_scorm\event\scoreraw_submitted'
    JOIN {course} c ON c.id = slog.courseid
    LEFT JOIN {logstore_standard_log} ulog ON ulog.eventname = '\core\event\course_module_completion_updated' AND ulog.userid = u.id  AND ulog.courseid = slog.courseid AND ulog.timecreated >= slog.timecreated
WHERE ulog.id IS NULL
  AND slog.timecreated > (SELECT MAX(cc.timecompleted)
    FROM (
    SELECT course, userid, timecompleted FROM {course_completions}
    UNION
    SELECT course, userid, timecompleted FROM {local_recompletion_cc}
    ) cc
    WHERE cc.course = slog.courseid AND cc.userid = u.id) + 86400
GROUP BY u.id, c.id
ORDER BY u.id, c.id