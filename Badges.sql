SELECT u.username, b.name AS badgename,
       CASE
           WHEN b.courseid IS NOT NULL THEN
               (SELECT c.shortname
                FROM prefix_course AS c
                WHERE c.id = b.courseid)
           WHEN b.courseid IS NULL THEN '*'
           END AS Context,
       CASE
           WHEN t.criteriatype = 1 AND t.method = 1 THEN 'Activity Completion (All)'
           WHEN t.criteriatype = 1 AND t.method = 2 THEN 'Activity Completion (Any)'
           WHEN t.criteriatype = 2 AND t.method = 2 THEN 'Manual Award'
           WHEN t.criteriatype = 4 AND t.method = 1 THEN 'Course Completion (All)'
           WHEN t.criteriatype = 4 AND t.method = 2 THEN 'Course Completion (Any)'
               --ELSE CONCAT ('Other: ', t.criteriatype)
    ELSE 'Other: ' || t.criteriatype
END AS Criteriatype,
--DATE_FORMAT( FROM_UNIXTIME( d.dateissued ) , '%Y-%m-%d' ) AS dateissued,
to_char( to_timestamp( d.dateissued ), 'YYYY-MM-DD') AS dateissued,
--CONCAT ('<a target="_new" href="%%WWWROOT%%/badges/badge.php?hash=',d.uniquehash,'">link</a>') AS Details
'<a target="_new" href="%%WWWROOT%%/badges/badge.php?hash=' || d.uniquehash || '">link</a>' AS Details
FROM prefix_badge_issued AS d
    JOIN prefix_badge AS b ON d.badgeid = b.id
    JOIN prefix_user AS u ON d.userid = u.id
    JOIN prefix_badge_criteria AS t ON b.id = t.badgeid
WHERE t.criteriatype <> 0
ORDER BY u.username