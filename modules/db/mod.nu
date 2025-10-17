def commands [] {
  {
    options: { case_sensitive: false, completion_algorithm: prefix, positional: true, sort: true },
    completions: ["update", "sync", "patch"] 
  }
}

def synchronize [
  name?: string
] {
  let is_git_dir = (".git" | path exists)

  if ($name != null) {
    dbmanager export-content --database=$"($name)"
  } else { 
    dbmanager export-content
  }

  if $is_git_dir {
    print $"(ansi bu)Export finished - Checking to for upstream changes...(ansi reset)"

    # fetch content
    let fetch_attempt = git fetch origin dev | complete
    if $fetch_attempt.exit_code != 0 {
      git fetch origin dev
    }

    let is_behind = git status | complete | get stdout | str contains -i "your branch is behind"
    let has_changes = git status --short | complete | get stdout | $in != ""
    if $is_behind and $has_changes {
      # stash content
      print $"(ansi bu)Upstream changes found; Stashing local changes...(ansi reset)"
      git stash
    }

    # rebase content
    print $"(ansi bu)Rebasing now...(ansi reset)"
    git rebase

    # pop stash if local was behind after rebase
    if $has_changes {
      print $"(ansi bu)Rebase successul... Applying stashed changes...(ansi reset)"
      do -i { git stash pop } 
    }
  } else {
    print $"(ansi bu)Export finished - updating working copy...(ansi reset)"
    svn update
  }

  if ($name != null) {
    dbmanager import-content --database=$"($name)"
  } else { 
    dbmanager import-content
  }
}

# Creates a CLIPS Dbd Patch. You need `New-ClipsPatch.ps1` in your $PATH
# for this to work
def patch [] {
  try {
    pwsh -c New-ClipsPatch.ps1
  }
  catch {
    "Could not fine 'New-ClipsPatch.ps1' please make sure it exists and 
    is in a folder defined in `$PATH`"
  }
}

# Synchronize CommSys or CLIPS databases
#
# Use to synchronize your databases OR create a CLIPS DBD Patch
#
# UPDATE: Updates and synchronizes the database
# PATCH:  Build a database patch using `New-ClipsPatch.ps1`
#         can be found on confluence
export def --env main [
  command: string@commands, # Database command to run
  name?: string # Name of Database (Only needed for clips databases)
] {
  let span = (metadata $command).span;
  match $command {
    "patch" => { patch }, 
    "sync" => { 
      error make {
        msg: $"(ansi ri)db sync(ansi rst) is deprecated. See (ansi lgb)db -h(ansi rst)",
        label: { 
          text: $"(ansi ri)sync(ansi rst) is deprecated",
          span: $span 
        } 
      } 
    }
    "update" => { synchronize $name }
  }
}
