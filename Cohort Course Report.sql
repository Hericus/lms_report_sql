SELECT
    CONCAT('<a target="_blank" href="%%WWWROOT%%/cohort/assign.php?id=',ch.id,'&returnurl=%2Fcohort%2Findex.php%3Fpage%3D0">', ch.name,'</a>') "Cohort",
    co.fullname "Course",
    CASE
        WHEN cfgenable.value = '1' AND cfgrecompletiondur.value = '31449600' THEN 'Annual'
        WHEN cfgenable.value = '1' AND cfgrecompletiondur.value = '62899200' THEN 'Biennial'
        WHEN cfgenable.value = '1' AND cfgrecompletiondur.value = '94348800' THEN 'Triennial'
        END "Duration",
    CASE
        WHEN customfield.value = '1' THEN 'Yes'
        ELSE 'No'
        END "Tied to Compliance",
    course_hours.value as "Course Hours"
FROM
    prefix_enrol AS en
        INNER JOIN prefix_course AS co ON en.courseid = co.id
        INNER JOIN prefix_cohort AS ch ON en.customint1 = ch.id
        LEFT JOIN prefix_course_categories AS cc ON cc.id = co.category
        LEFT JOIN prefix_local_recompletion_config cfgenable
                  ON cfgenable.course = co.id AND cfgenable.name = 'enable'
        LEFT JOIN prefix_local_recompletion_config cfgrecompletiondur
                  ON cfgrecompletiondur.course = co.id AND cfgrecompletiondur.name = 'recompletionduration'
        LEFT JOIN prefix_customfield_data as customfield
                  ON customfield.instanceid = co.id AND customfield.fieldid = 1
        LEFT JOIN prefix_customfield_data course_hours
                  ON course_hours.instanceid = co.id AND course_hours.fieldid = (SELECT cf.id FROM prefix_customfield_field cf WHERE cf.shortname = 'course_length')
WHERE
        en.enrol = 'cohort' AND
        en.status = 0
        %%FILTER_SQL_cohort:ch.id:=%%
%%FILTER_SUBCATEGORIES:cc.path%%
%%FILTER_COURSES:co.id%%