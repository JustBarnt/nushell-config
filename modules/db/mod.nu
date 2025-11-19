# Updates and synchronizes the databases
#
# Input:
#   None
export def "update" [] {
  let $repo = get_repo_url
  let $is_clips = is_clips_repo $repo

  try {
    if $is_clips {
      dbmanager export-content --database="Clips1"
    } else {
      dbmanager export-content
    }

    log "Export finished - Checking to for upstream changes..."

    # Saftey net in case it has been more than 24 hours since last gitea request
    if (git fetch origin dev | complete).exit_code != 0 {
      git fetch origin dev
    }

    log "Stashing and pulling latest changes..."
    git pull --rebase --autostash origin dev
    log "Successfully updated from remote..."

    if ($is_clips) {
      dbmanager import-content --database="Clips1"
      log "Syncing Changes between Clips 1 and Clips 2 database..."
      cd ../database-2/
      .\dbsync CLIPS1 CLIPS2 localhost
    } else {
      dbmanager import-content
    }
  } catch {|err|
    log "Something went wrong..."
    log "" -e $err
  }
}

# Creates a CLIPS Dbd Patch. You need `New-ClipsPatch.ps1` in your $PATH
#
# Input:
#   None
export def "patch" [] {
  try {
    pwsh -c New-ClipsPatch.ps1
  } catch {|err|
    log "" --error $err
  }
}

# This module provides an easy interface to update and synchronize your databases
#
# Commands:
#   Patch  - Creates a CLIPS Patch
#   Update - Updates and Synchronizes the database using your current directory as
#            an indicator for which database
export def main []: nothing -> string {
  help db
}

def get_repo_url []: nothing -> string {
  if (".git" | path exists) {
    [(git remote get-url origin) (git rev-parse --abbrev-ref HEAD)] | str join "/" | str trim
  } else {
    svn info --show-item url | str trim
  }
}

def is_clips_repo [url: string]: nothing -> bool {
  ["https://svnstore:3000/clips/database/dev" "https://svnstore:8443/svn/CommSys/Clips/Database/Branches/dev"]
  | any {|| ($in | str downcase) == $url }
}
