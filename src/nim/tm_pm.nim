import csvtools, docopt, fiber_orm, db_postgres, sequtils, sets, strutils

import ./tm_pmpkg/jira_api

type
  Feature* = object
    id*: int
    name*: string
    epic*: int
    stories*: seq[string]
    defects*: seq[string]
    status*: string
    confidence*: int
    target_release*: string

  TmPmDb* = ref object
    conn: DbConn

func connect(connString: string): TmPmDb =
  result = TmPmDb(conn: open("", "", "", connString))

generateProcsForModels(TmPmDb, [ChangeLog, Feature, Issue])

generateLookup(TmPmDb, ChangeLog, @["historyId"])

when isMainModule:

  let doc = """
Usage:
  tm_pm import-csv <import-file>
  tm_pm api-sync <username> <api-key>
"""

  let args = docopt(doc, version = "0.1.0")
  let db = connect("host=localhost port=5500 dbname=tegra118 user=postgres password=password")

  if args["import-csv"]:
    let rows = toSeq(csvRows(path = $args["<import-file>"]))
    let jiraIssues = rows.map(proc (r: seq[string]): Issue =
      Issue(
        issueType: r[0],
        id: r[1],
        summary: r[2],
        priority: r[3],
        status: r[4],
        epicId: r[5],
        testPhase: r[6],
        assignee: r[7],
        linkedIssueIds: r[8..<r.len].filterIt(not it.isEmptyOrWhitespace)
      ))

    for issue in jiraIssues:
      discard db.createIssue(issue);
      # see if the issue already exists
      # try:
      #   let existingRecord = db.getJiraIssue(issue.id);
      # except NotFoundError:
      #   db.createJiraIssue(issue);

  if args["api-sync"]:
    initJiraClient("https://tegra118.atlassian.net", $args["<username>"], $args["<api-key>"])
    let issuesAndChangelogs = searchIssues(
      "project = \"UUP\" and (labels is empty or labels != \"Design&Reqs\") ORDER BY key ASC",
      includeChangelog = true
    )

    var issuesUpdated = 0
    var issuesCreated = 0
    var changelogsCreated = 0

    stdout.write("\nRetrieved " & $issuesAndChangelogs[0].len & " issues. ")
    for issue in issuesAndChangelogs[0]:
      try:
        discard db.getIssue(issue.id)
        discard db.updateIssue(issue)
        issuesUpdated += 1;
      except NotFoundError:
        discard db.createIssue(issue)
        issuesCreated += 1;
    stdout.writeLine("Created " & $issuesCreated & " and updated " & $issuesUpdated)

    stdout.write("Retrieved " & $issuesAndChangelogs[1].len & " change logs. ")
    var newHistoryIds: HashSet[string] = initHashSet[string]()
    for changelog in issuesAndChangelogs[1]:
      try:
        if newHistoryIds.contains(changelog.historyId) or
           db.findChangeLogsByHistoryId(changelog.historyId).len == 0:
          newHistoryIds.incl(changelog.historyId)
          discard db.createChangeLog(changelog)
          changelogsCreated += 1;
      except NotFoundError: discard

    stdout.writeLine("Recorded " & $changelogsCreated & " we didn't already have.\n")
