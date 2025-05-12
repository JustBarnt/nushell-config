def commands [] {
  {
    options: { case_sensitive: false, completion_algorithm: prefix, positional: true, sort: true },
    completions: ["sync", "patch"] 
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
        print "`fd` was not found on the system, please install fd with `scoop install fd` first."
        exit
      }

      let match: list<string> = sys disks | get mount | par-each {|disk|
        let stdout: string = fd -tf New-ClipsPatch.ps1 | complete | get stdout
        return $stdout
      }
      if ($match != "") {
        pwsh -c New-ClipsPatch.ps1
      } else {
        error make {
          msg: "Unable to find a New-ClipsPatch.ps1 file on the system."
        }
      }
    },
    "sync" => {
      let is_git_dir = (".git" | path exists)
      let is_svn_dir = (".svn" | path exists)

      db-export $name

      if $is_git_dir {
        let res = git_update | complete
        match $res.exit_code {
          0 => {
            db-import $name
          },
          1 => {
            db-import $name
          },
          _ => {
            error make { msg: $"Something horrible went wrong, ERROR: ($res.stderr)" }
          }
        }
      } else {
        svn_update
        db-import $name
      }
    }
  }
}

# Exports the database
def db-export [name?: string] {
  if ($env.PWD =~ "CLIPS") {
    print "Exporting CLIPS Database..."
    if ($name != null) { dbmanager export-content --database=$name }
  } else {
    print "Exporting COMMSYS Database..."
    if ($name == null) { dbmanager export-content }
  }
}

# Imports the database
def db-import [name?: string] {
  if ($env.PWD =~ "CLIPS") {
    print "Importing CLIPS Database... This WILL take a while..."
    dbmanager import-content --database=$name
  } else {
    print "Importing COMMSYS Database..."
    dbmanager import-content
  }
  print "Import complete! Make sure commit any changes!"
}

# Runs git: [stash, fetch, rebase, and stash pop]
def git_update [] {
  print "Export finished - Stashing any changes and updating working copy..."
  git stash; git fetch; git rebase
  print "Working copy updated! Applying stash..."
  git stash pop
}

# Runs svn: [update]
def svn_update [] {
  print "Export finished - updating working copy..."
  svn update
}
