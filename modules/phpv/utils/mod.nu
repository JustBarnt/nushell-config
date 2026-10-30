use ../log

export const default = {
  Root: ""
  Targets: {}
  Current: ""
}

export def test-path [path: string] {
  if ($path | path exists) { true } else { false }
}

export def cfg-path [] {
  $'($nu.default-config-dir)\phpmanager\'
}

export def cfg-file [] {
  $'($nu.default-config-dir)\phpmanager\phpmanager.nuon'
}

export def try-open-cfg []: nothing -> record<ok: bool, data: record> {
  try {
    let file = open $'(cfg-file)'
    {ok: true data: $file}
  } catch {
    $default | to nuon --indent 2 | save -f $'(cfg-path)\phpmanager.nuon'
    {ok: false data: $default}
  }
}

export def "add to path" [dir: path] {
  let dir = ($dir | path expand --no-symlink | str trim --right --char '\')
  let norm = {|p| $p | str trim --right --char '\' | str lowercase }

  let current = try {
    registry query --hkcu --no-expand Environment Path | get value
  } catch { '' }
  let parts = ($current | split row ';' | where $it != '')

  if ($parts | any {|p| (do $norm $p) == (do $norm $dir) }) { return }

  let new = ($parts | append $dir | str join ';')
  let r = (^reg add 'HKCU\Environment' /v Path /t REG_EXPAND_SZ /d $new /f | complete)
  if $r.exit_code != 0 { error make {msg: $"reg add failed: ($r.stderr)"} }

  # write dummy var to broadcast changes
  ^setx __nu_broadcast 1 | ignore
  # delete dummy var
  ^reg delete 'HKCU\Environment' /v __nu_broadcast /f | ignore
}

export def "junction set" [root: path target: path] {
  let alias = ($root | path expand --no-symlink)
  let target = ($target | path expand --no-symlink)

  if ($target | path type) != 'dir' {
    error make {msg: $"($target) is not a real directory"}
  }

  match ($root | path type) {
    null => { }
    "symlink" => {
      let r = (^cmd /c rmdir $root | complete)
      if $r.exit_code != 0 { error make {msg: $"rmdir failed: ($r.stderr)"} }
    }
    $t => { error make {msg: $"($root) exists and is a ($t), not a junction"} }
  }

  let r = (^cmd /c mklink /J $root $target | complete)
  if $r.exit_code != 0 { error make {msg: $"mklink failed: ($r.stdout)($r.stderr)"} }
}

export def --env refresh-environment [] {
  let user_path = registry query --hkcu environment | where name == Path | get value | split row ';' | where {|x| $x != '' }
  let sys_path = registry query --hklm 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment' | where name == Path | get value | split row ';' | where {|x| $x != '' }

  let out = $user_path ++ $sys_path ++ $env.path | uniq --ignore-case
  $env.path = $out
}
