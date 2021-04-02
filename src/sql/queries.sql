-- Show bugs moved to 'Resolved' with a full accounting of everyone who has
-- touched the issue, most recent issues first.
SELECT
  i.id,
  i.epic_id,
  i.status,
  i.test_phase,
  -- i.summary,
  i.assignee,
  array_agg(DISTINCT c2.author) AS involved,
  c.created_at AS resolved_at
FROM
  issues i JOIN
  change_logs c ON
    i.issue_type = 'Bug' AND
    i.id = c.issue_id AND
    c.field = 'status' AND
    c.new_value = 'Resolved' JOIN
  change_logs c2 on i.id = c2.issue_id
GROUP BY
  i.id,
  i.epic_id,
  i.status,
  i.test_phase,
  -- i.summary,
  i.assignee,
  resolved_at
ORDER BY resolved_at DESC;

-- Show everyone involved with a specific ticket
SELECT
  i.id,
  i.epic_id,
  i.status,
  i.summary,
  array_agg(DISTINCT c.author) AS involved
FROM
  issues i JOIN
  change_logs c ON i.id = c.issue_id
WHERE i.id in ('UUP-848')
GROUP BY i.id, i.epic_id, i.status;


select status, count(*) from issues where issue_type = 'Bug' group by status;
