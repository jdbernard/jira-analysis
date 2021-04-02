UPDATE jira_issues SET linked_issues = collected.linked_issues from (
SELECT a.id, array_remove(array_cat(a.linked_issues, array_agg(b.id)) as linked_issues, NULL) FROM
  jira_issues a LEFT OUTER JOIN
  jira_issues b ON b.linked_issues @> ARRAY[a.id]
GROUP BY a.id
) AS collected
WHERE jira_issues.id = collected.id;
