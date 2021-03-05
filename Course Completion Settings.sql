SELECT
    CONCAT('<a target="_new" href="%%WWWROOT%%/course/completion.php?id=',c.id,'">',c.fullname,'</a>') AS "Course",
    cc.name AS "Category",
    CASE WHEN c.enablecompletion = 1 THEN 'Yes' else 'No' end  AS "Completion Enabled",

    CASE
        WHEN (SELECT a.method FROM prefix_course_completion_aggr_methd AS a WHERE (a.course = c.id AND a.criteriatype IS NULL)) = 1 THEN 'Any'
        ELSE 'All'
        END AS "Completion Requirements",

    CASE
        WHEN (SELECT COUNT(1) FROM prefix_course_completion_criteria AS crit WHERE crit.course = c.id AND crit.criteriatype = 4) > 0 THEN 'Yes'
        ELSE 'No'
        END AS "Activity Completion",

    CASE
        WHEN (SELECT COUNT(1) FROM prefix_course_completion_criteria AS crit WHERE crit.course = c.id AND crit.criteriatype = 8) > 0 THEN 'Yes'
        ELSE 'No'
        END AS "Other Courses",

    CASE
        WHEN (SELECT COUNT(1) FROM prefix_course_completion_criteria AS crit WHERE crit.course = c.id AND crit.criteriatype = 2) > 0 THEN 'Yes'
        ELSE 'No'
        END AS "Date",
    CASE
        WHEN (SELECT COUNT(1) FROM prefix_course_completion_criteria AS crit WHERE crit.course = c.id AND crit.criteriatype = 5) > 0 THEN 'Yes'
        ELSE 'No'
        END AS "Enrollment Duration",

    CASE
        WHEN (SELECT COUNT(1) FROM prefix_course_completion_criteria AS crit WHERE crit.course = c.id AND crit.criteriatype = 3) > 0 THEN 'Yes'
        ELSE 'No'
        END AS "Unenrollment",

    CASE
        WHEN (SELECT COUNT(1) FROM prefix_course_completion_criteria AS crit WHERE crit.course = c.id AND crit.criteriatype = 6) > 0 THEN 'Yes'
        ELSE 'No'
        END AS "Course Grade",

    CASE
        WHEN (SELECT COUNT(1) FROM prefix_course_completion_criteria AS crit WHERE crit.course = c.id AND crit.criteriatype = 1) > 0 THEN 'Yes'
        ELSE 'No'
        END AS "Manual",

    CASE
        WHEN (SELECT COUNT(1) FROM prefix_course_completion_criteria AS crit WHERE crit.course = c.id AND crit.criteriatype = 7) > 0 THEN 'Yes'
        ELSE 'No'
        END AS "Manual by Other"
FROM
    prefix_course AS c
        JOIN prefix_course_categories AS cc ON c.category = cc.id
WHERE 1=1
    %%FILTER_SUBCATEGORIES:cc.path%%
%%FILTER_COURSES:c.id%%
