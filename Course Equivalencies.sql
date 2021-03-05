SELECT c1.id AS courseid, c1.fullname AS course, c2.id AS equivalentcourseid, c2.fullname AS equivalentcourse
FROM (SELECT DISTINCT courseoneid AS courseid
      FROM {local_recompletion_equiv}
      UNION
      SELECT DISTINCT coursetwoid AS courseid
      FROM {local_recompletion_equiv}) courses
         JOIN {course} c1 ON c1.id = courses.courseid AND c1.visible = 1
    JOIN {course_categories} cc ON c1.category = cc.id
    JOIN {local_recompletion_equiv} equiv ON equiv.courseoneid = c1.id OR equiv.coursetwoid = c1.id
    JOIN {course} c2 ON (c1.id <> equiv.courseoneid AND c2.id = equiv.courseoneid) OR (c1.id <> equiv.coursetwoid AND c2.id = equiv.coursetwoid)
WHERE 1=1
    %%FILTER_SUBCATEGORIES:cc.path%%
    %%FILTER_COURSES:courses.courseid%%
ORDER BY c1.fullname ASC