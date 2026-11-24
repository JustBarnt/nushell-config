export def main [] { }

const CLIPS = 'D:\commsys\clips\'

def branches [] {
  let branches = []
  let $clips_branches = ls D:\commsys\clips\clips\branches
  | where type == dir
  | get name
  | path parse
  | get stem

  let $tool_branches = ls D:\commsys\clips\formtools\branches
  | where type == dir
  | get name
  | path parse
  | get stem

  let $tag_branches = ls D:\commsys\clips\clips\tags
  | where type == dir
  | get name
  | path parse -e ''
  | get stem

  $clips_branches | append $tool_branches | append $tag_branches
}

export def start [
  --path (-p): string@branches
  --port (-P): int
  --branch (-b)
  --tools (-t)
  --tag (-T)
] {
  if $tools {
    mut $port = $port | default 8080
    mut $formtools = 'formtools\trunk\clipswebtools'
    cd ($CLIPS | path join $formtools)
    php -S $"127.0.0.1:($port)" -t .
  } else {
    mut $port = $port | default 80
    if $branch {
      cd ($CLIPS | path join $'clips\branches\($path)\application')
    } else if $tag {
      cd ($CLIPS | path join $'clips\tags\($path)\application')
    } else {
      cd ($CLIPS | path join $'clips\trunk\application')
    }

    ./console/cake.bat server -H 127.0.0.1 -p $port
  }
}
