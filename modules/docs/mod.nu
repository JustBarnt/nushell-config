# Checkout devdocs automatically and open the doc in word
export def main [] { }

def interfaces [] {
  ls *.htm 
  | find -r \w{2}_
  | each {|f|
      ($f.name | path parse | get stem)
  }
}

export def edit [
interface: string@interfaces, # List of available Developer Documents to lock
message: string # Lock message
] {
  let regexp = `(?<flags>^.{9})\s+(?<wc_rev>\d+)\s+(?<rm_rev>\d+)\s+(?<author>\w+)\s+(?<file>.*)`
  let status_table: table = svn status -v $"($interface).htm" | parse -r $regexp
  let flags: list<string> = $status_table | $in.flags.0

  let lock_status = parse-status-message $flags
  let can_continue: bool = match $lock_status {
    1 => true,
    2 => false,
    3 => false
  }

  if not $can_continue {
    print $"Interface: (ansi bold_blue)$(interface)(ansi reset) is already locked"
  }

  let command_status = svn lock -m $"($message)" $"($interface).htm ($interface)_files" | complete

  if $command_status.exit_code > 0 {
    error make { msg: $"Something went wrong while attempting to lock interface: ($interface)\nError:($command_status.stderror)" }
  }

  `C:\Program Files\Microsoft Office\Office16\WINWORD.EXE` $"($interface).htm"
}

def parse-status-message [flags: list<string>]: any -> int {
  let STATUS = {
    FREE:           1,
    TAKEN:          2,
    ALREADY_LOCKED: 3
  }

  let has_local_lock: bool = $flags | str substring 5..5 == 'K'
  let has_remote_lock: bool = $flags | str substring 2..2 == 'L'

  if $has_remote_lock { return $STATUS.TAKEN }
  if $has_local_lock { return $STATUS.ALREADY_LOCKED }
}
