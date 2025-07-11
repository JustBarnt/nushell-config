# config.nu
#
# Installed by:
# version = "0.103.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

mut is_ocs133_enabled = true

if "TERM_PROGRAM" in $env {
  # Disable ocs133 in WEZTERM. Everytime you type a character it inserts a new
  # line into the terminal
  $is_ocs133_enabled = false

  # If we are in Rider, don't use starship
  if $env.TERM_PROGRAM != "Rider" {
    use ~/.cache/starship/init.nu
  }
}

$env.config.show_banner = false
$env.config.filesize.unit = "binary"
$env.config.table = {
  mode: single #reinforced
  index_mode: auto
  show_empty: true
  padding: {left: 1 right: 1}
  trim: {
    methodology: wrapping
    wrapping_try_keep_words: true
    truncating_suffix: "..."
  }
  header_on_separator: false
}
$env.config.error_style = "fancy"
$env.config.rm.always_trash = true
$env.config.ls = {
  use_ls_colors: true
  clickable_links: true
}
$env.config.history = {
  max_size: 5_000_000
  sync_on_enter: true
  file_format: "sqlite"
  isolation: true
}
$env.config.completions = {
  case_sensitive: false
  quick: true
  partial: false
  algorithm: "prefix"
  external: {
    enable: true
    max_results: 100
    completer: null
  }
  use_ls_colors: true
}
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"
$env.config.footer_mode = 50
# $env.config.float_precision = 2
$env.config.buffer_editor = "nvim"
$env.config.use_ansi_coloring = true
$env.config.bracketed_paste = true
$env.config.edit_mode = "vi"
$env.config.shell_integration = {
  osc2: true
  osc7: true
  osc8: true
  osc9_9: false
  osc133: true #$is_ocs133_enabled
  osc633: true
  reset_application_mode: true
}
$env.config.render_right_prompt_on_last_line = true
$env.config.use_kitty_protocol = true
$env.config.highlight_resolved_externals = true
$env.config.recursion_limit = 50
$env.config.plugins = {}
$env.config.plugin_gc = {
  default: {
    enabled: true
    stop_after: 10sec
  }
  plugins: {
    gstat: {
      enabled: true
    }
    query: {
      enabled: true
    }
    formats: {
      enabled: true
    }
  }
}
$env.config.hooks = {
  pre_prompt: [{ null }] # run before the prompt is shown
  pre_execution: [{ null }] # run before the repl input is run
  env_change: {
    PWD: [{|before, after| null }] # run if the PWD environment is different since the last repl input
  }
  display_output: "if (term size).columns >= 100 { table -e } else { table }" # run to display the output of a pipeline
  command_not_found: { null } # return an error message when a command is not found
}

source ~/.local/share/zoxide/.zoxide.nu

# Custom Completion Sources
source ./completions/scoop-completions.nu
source ./completions/cargo-completions.nu
source ./completions/dotnet-completions.nu
source ./completions/git-completions.nu
source ./completions/rg-completions.nu
source ./completions/zoxide-completions.nu

# Custom Completion Menus
source ./menus/zoxide-menu.nu

# Custom Modules
use modules/warp
use modules/db
use modules/docs
use modules/msvs
use modules/expand

# Alias VIM
alias core-vim = vim
alias vim = nvim
alias nv = neovide

def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  yazi ...$args --cwd-file $tmp
  let cwd = (open $tmp)
  if $cwd != "" and $cwd != $env.PWD {
    cd $cwd
  }
  rm -fp $tmp
}

def usevim [name: string, args] {
  $env.NVIM_APPNAME = $name
  nvim $args
}

def nu-treesitter-highlights [] {
  let remote = "https://raw.githubusercontent.com/nushell/tree-sitter-nu/main/queries/nu/"
  let local = (
    $env.XDG_DATA_HOME?
    | default ($env.LOCALAPPDATA | path join "nvim-data")
    | path join "nvim" "lazy" "nvim-treesitter" "queries" "nu"
  )

  let file = "highlights.scm"

  mkdir $local
  http get ([$remote $file] | str join "/") | save --force ($local | path join $file)
}

def edit-vars [] {
  let host = sys host | get name
  if $host == "Windows" {
    rundll32.exe sysdm.cpl,EditEnvironmentVariables
  } else {
    echo "Warning: Unix systems do not usually include GUI editors for Environment Variables. \n Exiting... Command"
  }
}

def "logs copy" [path: string] {
  const JIRA_ATTACHMENTS_DIR = "G:\\Support\\JIRA Attachments\\"
  match ($env.JIRA_CASE_DIR == null) {
    true => {
      error make {
        msg: $"Missing: JIRA_CASE_DIR"
      }
    }
    false => {
      if not ($env.JIRA_CASE_DIR | path exists) {
        print $"(ansi green_bold)JIRA_CASE_DIR not found.\nCreating directory...(ansi reset)"
        mkdir $env.JIRA_CASE_DIR
      }

      let case_dir = $path | str upcase
      let copy_from = $JIRA_ATTACHMENTS_DIR | path join $case_dir

      try {
        let item = (ls -m $copy_from | reduce {|item, acc|
          if ($item.modified) > ($acc.modified) {
            $item
          } else {
            $acc
          }
        })

        match $item.type {
          "application/zip" => {
            print $"(ansi blue_bold)Archive Found: ($item.name)"
            print $"Extracting to: ($env.JIRA_CASE_DIR)/($item.name)"
            tar -xf ($case_dir | path join $item.name)
            print $"Archive Extracted!(ansi reset)"
            return
          }
          "text/plain" => {
            cp $item.name $env.JIRA_CASE_DIR
            return
          }
        }
      } catch {
        "No logs found"
      }
    }
  }
}

def "start clips" [path?: string = "CLIPS"] {
  # TODO:CHECK IF PATH IS VALID
  let clips_dir = $'D:\CommSys\CLIPS'
  let span = (metadata $path).span
  let test_path: string = $'($clips_dir)\($path)\Application'
  match ($test_path | path exists) {
    true => {
      cd $'($clips_dir)\($path)\Application'
      ./console/cake.bat server -H 127.0.0.1 -p 80
    }
    false => {
      error make {
        msg: "Path does not exists"
        label: {
          text: $"Could not change directories to: \n($clips_dir)($path)\\Application"
          span: $span
        }
      }
    }
  }
}

def "start formtools" [] {
  cd `D:\CommSys\CLIPS\FormTools\ClipsWebTools\`
  php -S 127.0.0.1:8080 -t .
}

def glog [count: int] {
  git log --pretty=%h»¦«%s»¦«%aN»¦«%aE»¦«%aD -n $count | lines | split column "»¦«" commit subject name email date
}

def "ternary closure" [condition: closure, first: any, second: any]: any -> any {
  if (do $condition) { $first } else { $second }
}

def "ternary boolean" [condition: bool, first: any, second: any]: any -> any {
  if $condition { $first } else { $second }
}

def --env refreshenv [] {
  let user_path = registry query --hkcu environment | where name == Path | get value | split row ';' | where {|x| $x != '' }
  let sys_path = registry query --hklm 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment' | where name == Path | get value | split row ';' | where {|x| $x != '' }

  let out = $user_path ++ $sys_path ++ $env.path | uniq --ignore-case
  $env.path = $out
}

def "count tags" [patterns: list<string>] {
  for pat in $patterns {
    let count = rg -o $pat | wc -l

    return {pattern: $pat found: $count}
  }
}

def "empty trash" [] {
  do {
    # run pwsh -c 'whoami /user' to find your SID and replace it there
    rm -rf C:\$Recycle.Bin\S-1-5-21-328912919-4025806940-3881157763-8676\
  }
}



