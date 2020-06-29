SELECT
  uif.name AS "User Field",
  CASE
    WHEN lpc.matchtype = 'exact' THEN 'equals'
    ELSE lpc.matchtype
  END AS "Match Type",
  lpc.matchvalue AS "Value",
  CASE
    WHEN lpc.andnextrule = 1 THEN 'AND'
    ELSE '='
  END AS " ",
  CASE
    WHEN lpc.andnextrule = 0 THEN c.name
    ELSE ''
  END AS "Cohort",
  CASE
   WHEN lpc.andnextrule = 0 AND c.timecreated > 0 THEN to_char(to_timestamp(c.timecreated), 'YYYY-MM-DD')
   ELSE ''
  END AS "Release Date"
FROM
  prefix_local_profilecohort lpc
  join prefix_user_info_field uif on uif.id = lpc.fieldid
  join prefix_cohort c on c.id = lpc.value::BIGINT
WHERE
1 = 1
%%FILTER_SQL_cohort:c.id:=%%
ORDER BY
  c.name,
  lpc.sortorder