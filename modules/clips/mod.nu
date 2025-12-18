export def main [] { }

const CLIPS = 'D:\CommSys\CLIPS\'

def branches [] {
    let branches = []
    let $clips_branches = ls D:\CommSys\CLIPS\CLIPS\Branches
    | where type == dir
    | get name
    | path parse
    | get stem

    let $tool_branches = ls D:\CommSys\CLIPS\FormTools\Branches
    | where type == dir
    | get name
    | path parse
    | get stem

    let $tag_branches = ls D:\CommSys\CLIPS\CLIPS\Tags
    | where type == dir
    | get name
    | path parse -e ''
    | get stem
    
   $clips_branches | append $tool_branches | append $tag_branches
}

export def start [
  --branch (-b)
  --path (-p): string@branches
  --tools (-t)
  --tag (-T)
  --port (-P) = "8080"
] {
  match $tools {
    true => {
      mut $formtools = 'FormTools\Trunk\ClipsWebTools'
      if $branch {
        $formtools = $'FormTools\Branches\($path)\ClipsWebTools'
      }
      cd ($CLIPS | path join $formtools)
      php -S $"127.0.0.1:($port)" -t .
    }
    false => {
      if $branch {
        cd ($CLIPS | path join $'CLIPS\Branches\($path)\Application')
      } else if $tag {
        cd ($CLIPS | path join $'CLIPS\Tags\($path)\Application')
      } else {
        cd ($CLIPS | path join $'CLIPS\Trunk\Application')
      }

      ./console/cake.bat server -H 127.0.0.1 -p 80
    }
  }
}
