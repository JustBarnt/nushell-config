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

# TODO: Setup proper use of $nu.data-dir
# NU_LIB_DIRS
# -----------
# Directories in this constant are searched by the
# `use` and `source` commands.
#
# By default, the `scripts` subdirectory of the default configuration
# directory is included:
# const NU_LIB_DIRS = [
#     ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
#     ($nu.data-dir | path join 'completions') # default home for nushell completions
# ]
# # You can replace (override) or append to this list by shadowing the constant
# const NU_LIB_DIRS = $NU_LIB_DIRS ++ [($nu.default-config-dir | path join 'modules')]

# # An environment variable version of this also exists. It is searched after the constant.
# $env.NU_LIB_DIRS ++= [ ($nu.data-dir | path join "nu_scripts") ]

use themes/onedark.nu
$env.config.color_config = (onedark)
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
  missing_value_symbol: "NULL"
}
$env.config.error_style = "fancy"
$env.config.rm.always_trash = true
$env.config.ls = {
  use_ls_colors: true
  clickable_links: true
}
$env.config.history = {
  file_format: "plaintext"
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
  osc9_9: true
  osc133: true
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
  # pre_prompt: [{ null }] # run before the prompt is shown
  pre_execution: [{ null }] # run before the repl input is run
  env_change: {
    PWD: [{|before, after| null }] # run if the PWD environment is different since the last repl input
  }
  display_output: "if (term size).columns >= 100 { table -e } else { table }" # run to display the output of a pipeline
  command_not_found: { null } # return an error message when a command is not found
}

use ~/.cache/starship/init.nu

# Custom Completion Sources
source ./completions/dbmanager-completions.nu
source ./completions/cargo-completions.nu
source ./completions/completions-jj.nu
source ./completions/dotnet-completions.nu
source ./completions/tree-sitter-completions.nu
source ./completions/git-completions.nu
source ./completions/rg-completions.nu
source ./completions/scoop-completions.nu
source ./completions/uv-completions.nu
source ./completions/winget-completions.nu

# Custom Completion Menus


# Custom Modules
use modules/log
use modules/utils [from-rgb to-rgb]
use modules/clips
use modules/db
use modules/docs
use modules/msvs
use modules/expand
use modules/windows
use modules/jira *

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

def edit-vars [] {
  let host = sys host | get name
  if $host == "Windows" {
    rundll32.exe sysdm.cpl,EditEnvironmentVariables
  } else {
    echo "Warning: Unix systems do not usually include GUI editors for Environment Variables. \n Exiting... Command"
  }
}

# TODO: Move to module
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

# TODO: Move to module, also default path here so it can be called from anywhere
def "count tags" [patterns: list<string>] {
  for pat in $patterns {
    let count = rg -o $pat | wc -l

    return {pattern: $pat found: $count}
  }
}

def "date julian" [] {
  let julian = date now | format date "%y%j"
  $julian | clip
  $julian
}

# def "restart into bios" [] {
#   sudo;
#   log "Windows will shutdown in 10 seconds and boot into bios..." --color yellow_bold --prefix "[WARN]"
#   C:\Windows\System32\shutdown.exe /r /fw /t 10
# }

def "empty trash" [] {
  do {
    # run pwsh -c 'whoami /user' to find your SID and replace it there
    rm -rf C:\$Recycle.Bin\S-1-5-21-328912919-4025806940-3881157763-8676\
  }
}
