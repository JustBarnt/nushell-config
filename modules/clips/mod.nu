export def main [] { }

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
    
   $clips_branches | append $tool_branches
}

export def start [
  --branch (-b)
  --path (-p): string@branches
  --tools (-t)
  --port (-P) = "8080"
] {
  mut CLIPS = 'D:\CommSys\CLIPS\'

  if $tools {
      mut $formtools = 'FormTools\Trunk\ClipsWebTools'
      if $branch {
        $formtools = $'FormTools\Branches\($path)\ClipsWebTools'
      }
      $CLIPS = ($CLIPS | path join $formtools)
      cd $CLIPS
      php -S $"127.0.0.1:($port)" -t .
      return;
  }

  if $branch {
    $CLIPS = ($CLIPS | path join $'CLIPS\Branches\($path)\Application')
    cd $CLIPS
  } else {
    $CLIPS = ($CLIPS | path join $'CLIPS\Trunk\Application')
    cd $CLIPS
  }
  ./console/cake.bat server -H 127.0.0.1 -p 80
}
