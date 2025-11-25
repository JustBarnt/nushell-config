# JIRA Rest API v3 Module for Nushell
# Provides commands for querying JIRA issues by key or JQL

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
  $in | each {|issues|
    {
      key: $issues.key
      assignee: ($issues.fields.assignee?.displayName? | default "Unassigned")
      created: ($issues.fields.created | into datetime | format date "%Y-%m-%d %H:%M" )
      fixVersions: ($issues.fields.fixVersions.0?.name? | default "None")
      affectedVersions: ($issues.fields.versions.0?.name? | default "None")
      components: ($issues.fields.components.0?.name? | default "None")
      status: $issues.fields.status.name
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
  let excludes = [expand self]

  if ($method == "GET") {
    http get --headers {
      Authorization: $auth
      Accept: "application/json"
    } $url
  } else if ($method == "POST") {
    let headers = { Authorization: $auth Accept: "application/json" "Content-Type": "application/json" }
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
  --fields: string # Comma-separated list of fields to return (default: all)
  --expand: string # Comma-separated list of parameters to expand (e.g., changelog, renderedFields)
] {
  mut endpoint = $"issue/($key)"
  mut params = []

  if ($fields != null) {
    $params = ($params | append $"fields=($fields)")
  }

  if ($expand != null) {
    $params = ($params | append $"expand=($expand)")
  }

  if (($params | length) > 0) {
    $endpoint = $"($endpoint)?($params | str join '&')"
  }

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
  jql: string              # JQL query string
  --fields: string = "key" # Comma-separated list of fields to return (default: summary, status, assignee, created)
  --max-results: int = 50  # Maximum number of results to return (default: 50)
]: nothing -> table {
  mut query = $jql

  mut body = {
    jql: $query
    maxResults: $max_results
    fields: ($fields | split row ',')
    fieldsByKeys: true
    expand: "name"
  }

  jira-request "search/jql" --method POST --body $body
}

# Get a simplified view of a JIRA issue
#
# Returns only key fields in a flat structure
export def "jira get-issue-simple" [
  key: string # Issue key (e.g., PROJECT-123)
] {
  let issue = (jira get-issue $key --fields "summary,status,assignee,reporter,priority,created,updated,description")

  {
    key: $issue.key
    summary: $issue.fields.summary
    status: $issue.fields.status.name
    assignee: ($issue.fields.assignee?.displayName? | default "Unassigned")
    reporter: $issue.fields.reporter.displayName
    priority: ($issue.fields.priority?.name? | default "None")
    created: $issue.fields.created
    updated: $issue.fields.updated
    description: ($issue.fields.description? | default "")
  }
}
