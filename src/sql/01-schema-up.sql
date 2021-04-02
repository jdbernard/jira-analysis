CREATE TABLE issues (
  id varchar primary key,
  issue_type varchar not null,
  summary varchar not null,
  epicId varchar,
  assignee varchar,
  test_phase varchar,
  status varchar not null,
  priority varchar not null,
  linked_issue_ids varchar[]
);

CREATE TABLE features (
  id serial primary key,
  name varchar not null,
  epicId varchar not null default '',
  stories varchar[] not null default '{}',
  defects varchar[] not null default '{}',
  status varchar default 'todo',
  confidence int not null default 0,
  target_release varchar not null default '',
  notes varchar not null default ''
);

CREATE TABLE change_logs (
  id serial primary key,
  history_id varchar,
  issue_id varchar not null references issues(id),
  author varchar,
  created_at timestamp with time zone,
  field varchar not null,
  old_value varchar,
  new_value varchar
);
