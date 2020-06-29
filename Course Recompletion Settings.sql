SELECT
CONCAT('<a href="/local/recompletion/recompletion.php?id=',c.id,'">',c.fullname,'</a>') AS "Course",
CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'enable') = '1' THEN 'Yes'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'enable') = '0' THEN 'No'
	ELSE NULL
END AS "Enabled",

(SELECT rc1.value::integer / 86400 FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'recompletionduration') AS "Recompletion period",
(SELECT rc1.value::integer / 86400 FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'notificationstart') AS "Notification start",
(SELECT rc1.value::integer / 86400 FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'frequency') AS "Frequency",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'deletegradedata') = '1' THEN 'Yes'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'deletegradedata') = '0' THEN 'No'
	ELSE NULL
END AS "Delete_all grades",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'archivecompletiondata') = '1' THEN 'Yes'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'archivecompletiondata') = '0' THEN 'No'
	ELSE NULL
END AS "Archive completion",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'quizdata') = '2' THEN 'Give student extra attempts'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'quizdata') = '1' THEN 'Delete_existing attempts'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'quizdata') = '0' THEN 'Do nothing'
	ELSE NULL
END AS "Quiz attempts",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'archivequizdata') = '1' THEN 'Yes'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'archivequizdata') = '0' THEN 'No'
	ELSE NULL
END AS "Archive quiz attempts",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'scormdata') = '1' THEN 'Delete_existing attempts'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'scormdata') = '0' THEN 'Do nothing'
	ELSE NULL
END AS "SCORM attempts",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'archivescormdata') = '1' THEN 'Yes'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'archivescormdata') = '0' THEN 'No'
	ELSE NULL
END AS "Archive SCORM attempts ",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'recompletionemailenable') = '1' THEN 'Yes'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'recompletionemailenable') = '0' THEN 'No'
	ELSE NULL
END AS "Send recompletion message",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'assigndata') = '1' THEN 'Delete_existing attempts'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'assigndata') = '0' THEN 'Do nothing'
	ELSE NULL
END AS "Assign attempts",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'customcertdata') = '1' THEN 'Delete_existing attempts'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'customcertdata') = '0' THEN 'Do nothing'
	ELSE NULL
END AS "Custom certificate",

CASE
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'archivecustomcertdata') = '1' THEN 'Yes'
	WHEN (SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'archivecustomcertdata') = '0' THEN 'No'
	ELSE NULL
END AS "Archive certificate",

(SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'recompletionemailsubject') AS recompletionemailsubject,
(SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'recompletionemailbody') AS recompletionemailbody,
(SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'recompletionremindersubject') AS recompletionremindersubject,
(SELECT rc1.value FROM prefix_local_recompletion_config AS rc1 WHERE rc1.course = c.id AND rc1.name = 'recompletionreminderbody') AS recompletionreminderbody
FROM prefix_local_recompletion_config AS rc
RIGHT OUTER JOIN prefix_course AS c ON rc.course = c.id
JOIN prefix_course_categories cc ON c.category = cc.id
WHERE 1=1
%%FILTER_SUBCATEGORIES:cc.path%%
%%FILTER_COURSES:c.id%%
GROUP BY
c.id