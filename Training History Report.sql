SELECT
    cc.name "Category",
    CONCAT('<a target="_blank" href="%%WWWROOT%%/course/view.php?id=', c.id, '">', c.shortname,'</a>') "Course",
    (to_char(to_timestamp(comp.timecompleted),'YYYY-MM-DD')) "Date of Completion"
FROM
    (
        SELECT * FROM prefix_course_completions cc WHERE cc.timecompleted > 0
        UNION
        SELECT * FROM prefix_local_recompletion_cc lr
    ) AS comp
        JOIN prefix_user AS u ON comp.userid= u.id
        JOIN prefix_course AS c ON comp.course= c.id
        JOIN prefix_course_categories AS cc ON c.category = cc.id
WHERE
            comp.userid = %%USERID%%
ORDER BY
    c.shortname ASC, comp.timecompleted ASC