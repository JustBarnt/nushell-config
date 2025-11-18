def commands [] {
  {
    options: { case_sensitive: false, completion_algorithm: prefix, positional: true, sort: true },
    completions: ["update", "patch"]
  }
}

def synchronize [] {
    let $repo =  [(git remote get-url origin | str trim) (git rev-parse --abbrev-ref HEAD | str trim)] | str join "/"
    mut $is_clips = $repo == "https://svnstore:3000/clips/database/dev"

    if $is_clips {
        dbmanager export-content --database="Clips1"
    } else {
        dbmanager export-content
    }

    print $"(ansi bu)Export finished - Checking to for upstream changes...(ansi reset)"

    # fetch content
    let fetch_attempt = git fetch origin dev | complete
    if $fetch_attempt.exit_code != 0 {
        git fetch origin dev
    }

    print $"(ansi bu)Stashing Content...(ansi reset)"
    do -i { git stash }

    # rebase content
    print $"(ansi bu)Rebasing now...(ansi reset)"
    do -i { git rebase }

    # pop stash if local was behind after rebase
    print $"(ansi bu)Rebase successul... Applying stashed changes...(ansi reset)"
    do -i { git stash pop }

    if ($is_clips) {
        dbmanager import-content --database="Clips1"
    } else {
        dbmanager import-content
    }

    if ($is_clips) {
        print $"(ansi bu)Syncing Changes between Clips 1 and Clips 2 database(ansi reset)"
        cd ../database-2/
        .\dbsync CLIPS1 CLIPS2 localhost
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
        match $command {
            "patch" => { patch },
            "update" => { synchronize }
            }
    }
