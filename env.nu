# env.nu
#
# Installed by:
# version = "0.103.0"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

$env.PROMPT_COMMAND = {||
    let dir = match (do -i { $env.PWD | path relative-to $nu.home-path }) {
        null => $env.PWD
        '' => '~'
        $relative_pwd => ([~ $relative_pwd] | path join)
    }

    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
    let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
    let path_segment = $"($path_color)($dir)(ansi reset)"

    $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
}

$env.PROMPT_COMMAND_RIGHT = {||
    # create a right prompt in magenta with green separators and am/pm underlined
    let time_segment = ([
        (ansi reset)
        (ansi magenta)
        (date now | format date '%x %X') # try to respect user's locale
    ] | str join | str replace --regex --all "([/:])" $"(ansi green)${1}(ansi magenta)" |
        str replace --regex --all "([AP]M)" $"(ansi magenta_underline)${1}")

    let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
        (ansi rb)
        ($env.LAST_EXIT_CODE)
    ] | str join)
    } else { "" }

    ([$last_exit_code, (char space), $time_segment] | str join)
}

$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# $env.NUPM_HOME = ($env.LOCALAPPDATA | path join "nupm")

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions') # default home for nushell completions
    # ($env.NUPM_HOME | path join "modules")
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
    # ($env.NUPM_HOME | path join "bin" "plugins")
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')
# An alternate way to add entries to $env.PATH is to use the custom command `path add`
# which is built into the nushell stdlib:
use std "path add"

path add ($env.PATH | path join '~/.local/bin')

if (sys host | get hostname | $in == "CommSys-PC58") {
  path add ($env.PATH | path join 'D:\CommSys\Tools\DbManager\.bin')
  path add ($env.PATH | path join 'C:\Utilities\SysinternalsSuite\')
  path add ($env.PATH | path join 'C:\Utilities\StrawberryPerl\perl\bin')
}

if (sys host | $in.name == "Windows") {
  $env.HOME = ([$env.HOMEDRIVE $env.HOMEPATH]) | path join
  path add ($env.PATH | path join $'($env."ProgramFiles(x86)")\Microsoft Visual Studio\Installer\')
}

# TODO: All of these if I am on windows need to get added via dos command to my path instead of being set on if I am in terminal
$env.BAT_CONFIG_PATH = '~/.config/bat/'
$env.YAZI_CONFIG_HOME = '~/.config/yazi/'
$env.TELEVISION_CONFIG = 'C:\Users\bwilliams\.config\television\'
$env.OPENSSL_DIR = 'C:\Users\bwilliams\scoop\apps\openssl\current\bin\'

$env.GOPATH = 'C:\Users\bwilliams\go\'
$env.PNPM_HOME = 'C:\Users\bwilliams\AppData\Local\pnpm\'
$env.BAT_PAGER = 'less -RF'
$env.YAZI_FILE_ONE = 'C:\Program Files\Git\usr\bin\file.exe'

$env.EDITOR = 'nvim'
$env.WEZTERM_LOG = "debug wezterm"
$env.SQL_EDITOR = "nvim"

$env.DOTNET_UPGRADEASSISTANT_TELEMETRY_OPTOUT = 1
$env.JIRA_CASE_DIR = "D:/CommSys/Projects/JIRA/Logs/"
$env.JIRA_ATTACHMENTS_DIR = "G:/Support/JIRA Attachments/"
$env.TOPIARY_CONFIG_FILE = ($env.XDG_CONFIG_HOME | path join topiary languages.ncl)
$env.TOPIARY_LANGUAGE_DIR = ($env.XDG_CONFIG_HOME | path join topiary languages)
$env.JAVA_HOME = "C:/Program Files/Java/jdk-24"

$env._ZO_RESOLVE_SYMLINKS = 1

$env.NEOVIDE_CONFIG = "~/.config/neovide/neovide.toml"

# To load from a custom file you can use:
# source ()

let starship_dir = "~/.local/share/starship"

mkdir ~/.local/share/starship | starship init nu | save -f ~/.local/share/starship/init.nu
