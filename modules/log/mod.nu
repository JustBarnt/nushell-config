def color-completer [] {
  ansi --list
  | get name
}

def diagnostic-compeleter [] {
  [
    {value:  'error', description: "[ERROR]"}
    {value:  'warn',  description: "[ WARN]"}
    {value:  'hint',  description: "[ HINT]"}
    {value:  'info',  description: "[ INFO]"}
  ]
}

# TODO: Update this so that it can accept input of `complete`
export def main [
  message: string
  --color  (-c): string@color-completer = "blue_bold"
  --error  (-e): any
  --prefix (-p): string@diagnostic-compeleter = "info"
]: nothing -> nothing {
  if ($error != null) {
    let $err_msg = match ($error | describe) {
      "string" => $error
      "record" => (if "msg" in $error { $error.msg } else { $error | to json })
      _ => ($error | to text)
    }

    print $"(ansi rr)[FATAL]: ($err_msg)(ansi reset)"
    return
  }

  let $diag = ($prefix | str upcase)
  match $diag {
    "ERROR" => (print $"(ansi rb)[ERROR] ($message)(ansi reset)"),
    "WARN"  => (print $"(ansi yb)[ WARN] ($message)(ansi reset)"),
    "INFO"  => (print $"(ansi cb)[ INFO] ($message)(ansi reset)"),
    "HINT"  => (print $"(ansi gb)[ HINT] ($message)(ansi reset)"),
    _ => (print $"(ansi $color)($message)(ansi reset)"),
  }
}
