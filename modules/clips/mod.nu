export def main [] { }

def clips-branches [] {
    let CLIPS = 'D:\CommSys\CLIPS\CLIPS\Branches'
    ls $CLIPS
    | where type == dir
    | get name
    | path parse
    | get stem
}

export def start [
  --branch (-b)
  --path (-p): string@clips-branches
  --tools (-t)
] {
  mut CLIPS = 'D:\CommSys\CLIPS\'

  if $tools {
      $CLIPS = ($CLIPS | path join $'FormTools\ClipsWebTools')
      cd $CLIPS
      php -S 127.0.0.1:8080 -t .
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
