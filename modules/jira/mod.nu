# JIRA Rest API v3 Module for Nushell
# Provides commands for querying JIRA issues by key or JQL

def products [] {
  [
    {value: '"CLIPS"' description: 'Generate a list of CLIPS changes'}
    {value: '"State Interfaces"' description: 'Generate a list of State Interfaces changes'}
    {value: '"ConnectCIC"' description: 'Generate a list of ConnectCIC changes'}
  ]
}

const issue_fields = [
  fixVersions
  resolution
  versions
  status
  components
  created
  description
  summary
  customfield_10204 #Interface Field
  customfield_10600 #Product
  customfield_10601 #Product Version
] | str join ","

const search_fields = [
  key
  created
  fixVersions
  versions
  components
  status
  customfield_10204 #Interface Field
  customfield_10600 #Product
  customfield_10601 #Product Version
] | str join ","

export-env {
  $env.JIRA_BASE_URL = ($env.JIRA_BASE_URL? | default "")
  $env.JIRA_USER = ($env.JIRA_USER? | default "")
  $env.JIRA_TOKEN = ($env.JIRA_TOKEN? | default "")
}

# Helper function to check if JIRA configuration is set
def check-config [] {
  if ($env.JIRA_BASE_URL | is-empty) {
    error make {
      msg: "JIRA_BASE_URL not set"
      label: {
        text: "Set JIRA_BASE_URL environment variable"
        span: (metadata $env.JIRA_BASE_URL).span
      }
    }
  }
  if ($env.JIRA_USER | is-empty) {
    error make {
      msg: "JIRA_USER not set"
      label: {
        text: "Set JIRA_USER environment variable"
        span: (metadata $env.JIRA_USER).span
      }
    }
  }
  if ($env.JIRA_TOKEN | is-empty) {
    error make {
      msg: "JIRA_TOKEN not set"
      label: {
        text: "Set JIRA_TOKEN environment variable"
        span: (metadata $env.JIRA_TOKEN).span
      }
    }
  }
}

# Helper function to create basic auth header
def make-auth-header [] {
  let auth_string = $"($env.JIRA_USER):($env.JIRA_TOKEN)"
  let encoded = ($auth_string | encode base64)
  $"Basic ($encoded)"
}

# Returns JIRA issues as a structured table
# Input:
#   any
# Output:
#   table
def jira-construct-table []: any -> table {
  $in | par-each {|issues|
    {
      "Key": $issues.key
      "Created": ($issues.fields?.created? | default "1970-01-01T00:00:00Z" | into datetime | format date "%Y-%m-%d %H:%M")
      "Fix Versions": ($issues.fields?.fixVersions.0?.name? | default "None")
      "Affects Version": ($issues.fields?.versions.0?.name? | default "None")
      "Components": ($issues.fields?.components?.0?.name? | default "None")
      "Interface": ($issues.fields?.customfield_10204? | default "None")
      "Status": $issues.fields?.status?.name?
      "Product": ($issues.fields?.customfield_10600?.value? | default "None")
      "Product Version": ($issues.fields?.customfield_10601? | default "None")
    }
  }
}

# Helper function to make JIRA API requests
def jira-request [
  endpoint: string
  --method: string = "GET"
  --body: record = {}
] {
  check-config

  let url = $"($env.JIRA_BASE_URL)/rest/api/3/($endpoint)"
  let auth = (make-auth-header)

  # List of columns to drop from out table that JIRAs REST API returns
  let excludes = [self]

  if ($method == "GET") {
    http get --headers {
      Authorization: $auth
      Accept: "application/json"
    } $url
  } else if ($method == "POST") {
    let headers = {Authorization: $auth Accept: "application/json" "Content-Type": "application/json"}
    http post --headers $headers --content-type application/json $url $body
    | get issues
    | reject ...$excludes
    | jira-construct-table
  }
}

# Get a JIRA issue by its key (e.g., PROJECT-123)
#
# Examples:
#   jira get-issue ABC-123
#   jira get-issue ABC-123 --fields summary,status,assignee
export def "jira get-issue" [
  key: string # Issue key (e.g., PROJECT-123)
  --fields: string = $issue_fields # Comma-separated list of fields to return
]: nothing -> record {
  mut endpoint = $"issue/($key)"
  mut params = [] | append $"fields=($fields)"
  $endpoint = $"($endpoint)?($params | str join '&')"

  jira-request $endpoint
}

# Search for JIRA issues using JQL (JIRA Query Language)
#
# Examples:
#   jira search 'project = ABC AND status = "In Progress"'
#   jira search 'assignee = currentUser() AND resolution = Unresolved' --max-results 50
#   jira search 'project = ABC' --fields summary,status --order-by 'created DESC'
#
# Input:
#   nothing
# Output:
#   table
export def "jira search" [
  jql: string # JQL query string
  --fields (-f): string = $search_fields # Comma-separated list of fields to return (default: summary, status, assignee, created)
  --max-results (-m): int = 50 # Maximum number of results to return. -1 for JIRA API limit (5000) (default: 50)
]: nothing -> table {
  mut query = $jql

  mut total = match $max_results {
    -1 => 5000
    _ => $max_results
  }

  mut body = {
    jql: $query
    maxResults: $total
    fields: ($fields | split row ',')
    fieldsByKeys: true
  }

  jira-request "search/jql" --method POST --body $body
}

# Take results from JQL query ->
#   Build a table of all that are Done with affected version either blank or 2.0.25 with the fields of: Summary, Description, Component, Fix Version, Affected Version

# Generates a changelog
#
# Examples:
#   jira search 'project = ABC AND status = "In Progress"' | jira build changelog <product>
#
# Input:
#   table
# Output:
#   table
export def "jira changelog" [
  product: string@products # Product for changelog i.e. CLIPS, State Interfaces, ConnectCIC
]: nothing -> table {
  # Using the product given, call jira search with a pre-defined JQL query only passsing the 'key' field
  # so the results are not limited to only 100 items.
  let jql = match ($product | str downcase) {
    "state interfaces" => 'project = "State Interfaces" AND (status in (Done) AND created >= "2022-03-25") order by created ASC'
    "clips" => 'project = CLIPS AND (status in (Done) AND created >= "2022-03-31") order by key asc'
    "connectcic" => 'project = ConnectCIC AND (status in (Done) AND created >= "2022-03-25") order by key asc'
  }

  #TODO: I want the columns to allow at least 25 characters of padding so product and created are not wrapped
  let results = jira search $jql -f "key" -m -1 | match ($product | str downcase) {
    "state interfaces" => {
      # we use par-each so each loop is running in parallel instead of sequentially
      # when tested with `each` it took an average of 22 seconds for 100 results
      # when tested with `par-each` it took 1 second for 100 results
      $in | par-each {|issue|
        let details = jira get-issue $issue.Key
        {
          "Summary": ($details.fields.summary | default "None")
          "Component": ($details.fields.components.0?.name? | "None")
          "Fix Versions": ($details.fields.fixVersions.0?.name? | default "None")
          "Affected Version": ($details.fields.versions.0?.name? | default "None")
          "Created": ($details.fields.created | into datetime | format date "%Y-%m-%d %H:%M")
        }
      }
    }
    _ => {
      $in | par-each {|issue|
        let details = jira get-issue $issue.Key
        {
          "Summary": ($details.fields.summary | default "None")
          "Components": ($details.fields.components.0?.name? | default "None")
          "Interface": ($details.fields.customfield_10204 | "None")
          "Fix Versions": ($details.fields.fixVersions.0?.name? | default "None")
          "Affected Version": ($details.fields.versions.0?.name? | default "None")
          "Created": ($details.fields.created | into datetime | format date "%Y-%m-%d %H:%M")
        }
      }
    }
  }

  $results
}
