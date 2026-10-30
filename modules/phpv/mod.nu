use log
use utils/ *

# PHP Nushell Module for managing multiple versions PHP
# 
# Subcommands: init, add, set, list
export def main [] {
  let res = try-open-cfg
  if not $res.ok {
    log -p info "phpv has not been setup. Run `phpv init`"
    return
  }

  if $res.data.Current == "" {
    log -p warn "`phpv set` has not been run."
    return
  }

  log $"Running PHP: ($res.data.Current)"
}

# Initializes `phpv` by setting your `Root`
# which is where the version of PHP will be linked to and the `Root`
# will be added to your path when you run `phpv set` after adding
# at least one version
export def init [
  root: string # A directory where you want your PHP version to be sourced from
] {

  if not (test-path cfg-path) {
    mkdir $'(cfg-path)'
  }

  let res = try-open-cfg

  try {
    let out = $res.data | upsert $.Root ($root | path split | path join)
    $out | to nuon --indent 2 | save -f $'(cfg-path)\phpmanager.nuon'
  } catch {|err|
    log -e $err ""
  }
}

# Adds the version to list of valid targets for PHP
# version setting
export def add [
  version: string # Version number to add Ex: 8.3
  path: string    # Path to the PHP install Ex: C:\PHPVersions\8.3.36\
] {
  let cell_path = [Targets $version] | into cell-path
  let res = try-open-cfg

  if ($res.data | get Root) == "" {
    log --prefix error "Root is missing please run `phpv init`"
    return
  }

  try {
    let out = $res.data | upsert $cell_path ($path | path split | path join)
    $out | to nuon --indent 2 | save -f $'(cfg-path)\phpmanager.nuon'
  } catch {|err|
    log -e $err ""
  }
}

# Lists out the `phpv` config
export def list [] {
  let res = try-open-cfg

  if not $res.ok {
    log -p error "`phpv` configuration file not found. Please run `phpv init`"
    return
  }

  let cfg = $res.data

  {
    root: $cfg.Root
    current: $cfg.Current
    targets: ($cfg.Targets | transpose name dir | insert active {|t| $t.name == $cfg.Current })
  } | table --expand
}

# Sets the active PHP version by creating a junction between
# the version you specified and the root you have set
# if `Root` is not in your path after this command is ran
# the first time, it will be added
export def --env set [
  version: string # PHP Version to switch to
] {
  let res = try-open-cfg

  if not $res.ok {
    log -p info "phpv has not been setup. Run `phpv init`"
    return
  }

  try {
    let root = $res.data | get Root
    let target = $res.data | get Targets | get $version

    # Create a junction of the folder back into our Root
    junction set $root $target
    # Add our $root to the users PATH if it wasn't already there
    add to path $root

    let out = $res.data | upsert $.Current $version
    $out | to nuon --indent 2 | save -f $'(cfg-path)\phpmanager.nuon'
  } catch {|err|
    log -e $err ""
  }

  refresh-environment
}
