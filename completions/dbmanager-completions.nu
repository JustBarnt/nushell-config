def "nu-complete dbmanager subcommands" [] {
  {
    options: {case_sensitive: true sort: false positional: false completion_algorithim: prefix}
    completions: (
      ^dbmanager help
      | collect
      | parse -r '\s{2}(?P<value>(?:--\w+)|(?:(?:\w+-\w+)(?:-\w+)?))\s{4,}(?P<description>\w.*(?:(?:\n\s{24}\w.*)+)?)'
      | str trim
      | update description {|row|
        $row.description
        | str replace -ar '\n\s{24}' ' '
        | str substring 0..56 #Complete is limited to 76 characters?
      }
    )
  }
}

export extern "dbmanager" [
  command?: string@"nu-complete dbmanager subcommands"
]
