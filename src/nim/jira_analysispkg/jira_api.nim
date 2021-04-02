import base64, httpclient, json, sequtils, strutils, times, uri

type
  ChangeLog* = object
    id*: string
    historyId*: string
    issueId*: string
    author*: string
    createdAt*: DateTime
    field*: string
    oldValue*: string
    newValue*: string

  Issue* = object
    id*: string
    issueType*: string
    summary*: string
    epicId*: string
    assignee*: string
    status*: string
    priority*: string
    linkedIssueIds*: seq[string]
    testPhase*: string

let client = newHttpClient()
var API_BASE = "";
const FIELDS = "issuetype,summary,customfield_10014,assignee,status,priority,issuelinks,customfield_10218,changelog"

proc parseIssue(json: JsonNode): (Issue, seq[ChangeLog]) =
  let f = json["fields"]
  return (
    Issue(
      id: json["key"].getStr(),
      issueType: f["issuetype"]["name"].getStr(),
      summary: f["summary"].getStr(),
      epicId: f["customfield_10014"].getStr(),
      assignee:
        if f["assignee"].kind == JNull: "Unassigned"
        else: f["assignee"]["displayName"].getStr(),
      status: f["status"]["name"].getStr(),
      priority: f["priority"].getStr(),
      linkedIssueIds: f["issuelinks"].mapIt(
        if it.hasKey("inwardIssue"): it["inwardIssue"]["key"].getStr()
        else: it["outwardIssue"]["key"].getStr()),
      testPhase: f["customfield_10218"].getStr()),
    if json.hasKey("changelog") and json["changelog"]["histories"].getElems().len > 0:
      json["changelog"]["histories"].getElems().map(
        proc (h: JsonNode): seq[ChangeLog] = h["items"].mapIt(
          ChangeLog(
            historyId: h["id"].getStr(),
            issueId: json["key"].getStr(),
            author: h["author"]["displayName"].getStr(),
            createdAt: parse(
              h["created"].getStr()[0..17] & h["created"].getStr()[^6..^3],
              "yyyy-MM-dd'T'HH:mm:sszz"),
            field: it["field"].getStr(),
            oldValue: it["fromString"].getStr(),
            newValue: it["toString"].getStr()
          )
        )
      ).foldl(a & b)
    else: @[]
  )

proc initJiraClient*(apiBasePath: string, username: string, apiToken: string) =
  API_BASE = apiBasePath
  client.headers = newHttpHeaders({
    "Content-Type": "application/json",
    "Authorization": "Basic " & encode(username & ":" & apiToken)
  })

proc searchIssues*(jql: string, includeChangelog: bool = false):
  (seq[Issue], seq[ChangeLog]) =

  result = (@[], @[])

  var query = @[
    ("jql", jql),
    ("fields", FIELDS)
  ]

  if includeChangelog: query.add(("expand", "changelog"))

  var resp = client.get(API_BASE & "/rest/api/3/search?" & encodeQuery(query))

  while true:
    if not resp.status.startsWith("2"):
      raise newException(Exception,
        "Received error from API: " & resp.status &
        "\nHeaders: " & $resp.headers &
        "\nBody: " & $resp.body)

    let body = parseJson(resp.body)
    let nextStartAt = body["startAt"].getInt(0) + body["maxResults"].getInt(0)

    echo "Retrieved records " &
      $body["startAt"].getInt() & " to " &
      $(nextStartAt - 1) & " of " &
      $body["total"].getInt() &
      " (" & $body["issues"].getElems().len & " records received)"

    let issuesAndLogs = body["issues"].getElems().mapIt(parseIssue(it))

    result[0] &= issuesAndLogs.mapIt(it[0])
    result[1] &= issuesAndLogs.mapIt(it[1]).foldl(a & b)

    if nextStartAt > body["total"].getInt(): break

    resp = client.get(
      API_BASE & "/rest/api/3/search?" &
      encodeQuery(query & ("startAt", $nextStartAt)))
