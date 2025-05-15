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
  let status_table: table = svn status -v $"($interface).htm" | parse -r `(?<flags>^.{9})\s+(?<wc_rev>\d+)\s+(?<rm_rev>\d+)\s+(?<author>\w+)\s+(?<file>.*)`
  let flags: string = $status_table | $in.flags.0

  let lock_status = parse-status-message $flags
  
  print $"File Locked: ($lock_status)"

  match $lock_status {
    1 => {
      svn update
      svn lock -m $"($message)" $"./($interface).htm" $"./($interface)_files/**"

      `C:\Program Files\Microsoft Office\Office16\WINWORD.EXE` $"($interface).htm"
    },
    _ => {
      print $"Interface: (ansi bold_blue)($interface)(ansi reset) is already locked"
    },
  }
}

export def save [
interface: string@interfaces, 
message: string
] {
  svn commit -m $"($message)" $"./($interface).htm" $"./($interface)_files/**"
}

def parse-status-message [flags: string]: any -> int {
  let STATUS = {
    FREE:           1,
    TAKEN:          2,
    ALREADY_LOCKED: 3
  }

  let has_local_lock: bool = $flags | str contains "K"
  let has_remote_lock: bool = $flags | str contains "L"

  if $has_remote_lock { return $STATUS.TAKEN }
  if $has_local_lock { return $STATUS.ALREADY_LOCKED }
  return $STATUS.FREE
}
