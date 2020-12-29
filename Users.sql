Select
  u.id,
  u.auth,
  u.confirmed,
  u.deleted,
  u.suspended,
  u.username,
  u.idnumber,
  u.firstname,
  u.lastname,
  u.email,
  u.emailstop,
  u.phone1,
  u.phone2,
  u.institution,
  u.department,
  u.address,
  u.city,
  u.country,
  u.lang,
  u.calendartype,
  u.theme,
  u.timezone,
  u.firstaccess,
  u.lastaccess,
  u.lastlogin,
  u.currentlogin,
  u.lastip,
  u.secret,
  u.url,
  u.description,
  u.descriptionformat,
  u.mailformat,
  u.maildigest,
  u.maildisplay,
  u.autosubscribe,
  u.trackforums,
  u.timecreated,
  u.timemodified,
  u.trustbitmask,
  u.imagealt,
  u.lastnamephonetic,
  u.firstnamephonetic,
  u.middlename,
  u.alternatename,

  (
    SELECT string_agg(c.name, ', ')
    FROM prefix_cohort_members AS cm JOIN prefix_cohort AS c ON cm.cohortid = c.id
    WHERE cm.userid = u.id
  ) AS "Cohorts"

from prefix_user u
WHERE 1=1
%%FILTER_SQL_sqltrecords:u.suspended:=%%