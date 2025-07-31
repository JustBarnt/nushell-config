def commands [] {
  {
    options: { case_sensitive: false, completion_algorithm: prefix, positional: true, sort: true },
    completions: ["update", "sync", "patch"] 
  }
}

def synchronize [] {
  let is_git_dir = (".git" | path exists)

  if ($name != null) {
    dbmanager export-content --database=$"($name)"
  } else { 
    dbmanager export-content
  }

  if $is_git_dir {
    print $"(ansi bu)Export finished - Stashing any changes and updating working copy...(ansi reset)"
    # stash content
    git stash
    # fetch content
    let fetch_attempt = git fetch origin dev | complete
    if $fetch_attempt.exit_code != 0 {
      git fetch origin dev
    }
    # rebase content
    git rebase

    # apply stash if `git stash list` has a stdout value
    if (git stash list | complete | $in.stdout != "") {
      print $"(ansi bu)Applying stashed changes...(ansi reset)"
      git stash pop
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

# Synchronize CommSys or CLIPS databases
#
# Use to synchronize your databases OR create a CLIPS DBD Patch
#
# SYNC:  Synchronize a database
# PATCH: Build a database patch using `New-ClipsPatch.ps1`
#        can be found on confluence
export def --env main [
  command: string@commands, # Database command to run
  name?: string # Name of Database (Only needed for clips databases)
] {
  match $command {
    "patch" => {
      if (which fd | length | $in == 0) {
        print $"(ansi red_bold)`fd`(ansi reset) was not found on the system, please install fd with (ansi blue_underlined)`scoop install fd` first.(ansi reset)"
        return
      }

      let match: list<string> = sys disks | get mount | par-each {|disk|
        let stdout: string = fd -tf New-ClipsPatch.ps1 | complete | get stdout | path expand
        return $stdout
      }
      if ($match != "") {
        pwsh -c $"($match)"
      } else {
        error make { msg: "Unable to find a New-ClipsPatch.ps1 file on the system." }
      }
    },
    "sync" => synchronize
    "update" => synchronize
  }
}
