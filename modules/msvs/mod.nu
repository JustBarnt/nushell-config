def --env find_msvs [] {
  export-env {
    $env.MSVS_BASE_PATH = $env.Path
    $env.PATH_VAR = (if "Path" in $env { "Path" } else { "PATH" })

    # According to https://github.com/microsoft/vswhere/wiki/Installing, vswhere should always be in this location.
    let vswhere_cmd = ($'($env."ProgramFiles(x86)")\Microsoft Visual Studio\Installer\vswhere.exe')
    let info = (
      if ($vswhere_cmd | path exists) {
        (^$vswhere_cmd -format json -nocolor -utf8 | from json)
      } else {
        # this should really error out here
        ('[{"installationPath": ""}]' | from json)
      }
    )

    $env.MSVS_ROOT = $info.0.installationPath

    $env.MSVS_MSVC_ROOT = (
      if not ($'($env.MSVS_ROOT)\VC\Tools\MSVC\' | path exists) {
        ""
      } else if (ls ($'($env.MSVS_ROOT)\VC\Tools\MSVC\*' | into glob) | is-empty) {
        ""
      } else {
        ((ls ($'($env.MSVS_ROOT)\VC\Tools\MSVC\*' | into glob)).name.0)
      }
    )

    $env.MSVS_MSDK_ROOT = (registry query --hklm 'SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0' InstallationFolder | get value)

    $env.MSVS_MSDK_VER = (registry query --hklm 'SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0' ProductVersion | get value) + '.0'

    $env.MSVS_INCLUDE_PATH = (
      [
        $'($env.MSVS_ROOT)\Include\($env.MSVS_MSDK_VER)\cppwinrt\winrt'
        $'($env.MSVS_MSVC_ROOT)\Include'
        $'($env.MSVS_MSVC_ROOT)\atlmfc\include'
        $'($env.MSVS_MSDK_ROOT)Include\($env.MSVS_MSDK_VER)\cppwinrt\winrt'
        $'($env.MSVS_MSDK_ROOT)Include\($env.MSVS_MSDK_VER)\shared'
        $'($env.MSVS_MSDK_ROOT)Include\($env.MSVS_MSDK_VER)\ucrt'
        $'($env.MSVS_MSDK_ROOT)Include\($env.MSVS_MSDK_VER)\um'
      ] | str join (char esep)
    )

    let esep_path_converter = {
      from_string: {|s| $s | split row (char esep) }
      to_string: {|v| $v | path expand | str join (char esep) }
    }

    $env.ENV_CONVERSIONS = {
      Path: $esep_path_converter
      DYLD_FALLBACK_LIBRARY_PATH: $esep_path_converter
      PSModulePath: $esep_path_converter
      MSVS_BASE_PATH: $esep_path_converter
      MSVS_INCLUDE_PATH: $esep_path_converter
      INCLUDE: $esep_path_converter
      LIB: $esep_path_converter
    }

    # Debugging Info
    # print $"MSVS_BASE_PATH: ($env.MSVS_BASE_PATH)"
    # print $"PATH_VAR: ($env.PATH_VAR)"
    # print $"MSVS_ROOT: ($env.MSVS_ROOT)"
    # print $"MSVS_MSVC_ROOT: ($env.MSVS_MSVC_ROOT)"
    # print $"MSVS_MSDK_ROOT: ($env.MSVS_MSDK_ROOT)"
    # print $"MSVS_MSDK_VER: ($env.MSVS_MSDK_VER)"
    # print $"MSVS_INCLUDE_PATH: ($env.MSVS_INCLUDE_PATH)"
  }
}

export def --env activate [
  --host (-h): string = x64 # Host architecture, must be x64 or x86 (case insensitive)
  --target (-t): string = x64 # Target architecture, must be x64 or x86 (case insensitive)
  --sdk (-s): string = latest # Version of Windows SDK, must be "latest" or a valid version string
  --silent
] {
  # I changed export-env {} to a custom command to avoid having export-env run when loading the module
  # because:
  # 1. I couldn't use activate because it depends on env vars being set that were hidden with deactivate
  # 2. It seems that export-env executed at `use`, leaves `$env.FILE_PWD` available in the environment
  #    which I think may be a bug. So, putting it in a custom command avoids that.
  find_msvs

  if (($env.MSVS_ROOT | is-empty) or ($env.MSVS_MSVC_ROOT | is-empty)) {
    print "Either Microsoft Visual Studio or MSVC is invalid."
    return
  }

  let fh = ($host | str downcase)
  let ft = ($target | str downcase)
  let fs = (
    if ($sdk != latest) {
      $sdk
    } else {
      $env.MSVS_MSDK_VER
    }
  )

  if (($fh != x64) and ($fh != x86)) {
    print $"Wrong host architecture specified: ($fh)."
    help n_msvc activate
    return
  }

  if (($ft != x64) and ($ft != x86)) {
    print $"Wrong target architecture specified: ($ft)."
    help n_msvc activate
    return
  }

  if not ($'($env.MSVS_MSDK_ROOT)bin\($fs)' | path exists) {
    print $"Invalid Windows SDK version specified: ($fs)."
    return
  }

  let env_path = [
    ($'($env.MSVS_ROOT)\..\Shared\Common\VSPerfCollectionTools\vs2019' | path expand)
    $'($env.MSVS_ROOT)\Common7\IDE'
    $'($env.MSVS_ROOT)\Common7\IDE\CommonExtensions\Microsoft\TestWindow'
    $'($env.MSVS_ROOT)\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer'
    $'($env.MSVS_ROOT)\Common7\IDE\Extensions\Microsoft\IntelliCode\CLI'
    $'($env.MSVS_ROOT)\Common7\IDE\Tools'
    $'($env.MSVS_ROOT)\Common7\IDE\VC\VCPackages'
    $'($env.MSVS_ROOT)\Common7\Tools\devinit'
    $'($env.MSVS_ROOT)\MSBuild\Current\bin'
    $'($env.MSVS_ROOT)\MSBuild\Current\bin\Roslyn'
    $'($env.MSVS_ROOT)\Team Tools\DiagnosticsHub\Collector'
    $'($env.MSVS_ROOT)\Team Tools\Performance Tools'
    $'($env.MSVS_MSVC_ROOT)\bin\Host($fh)\($ft)'
    $'($env.MSVS_MSDK_ROOT)bin\($ft)'
    $'($env.MSVS_MSDK_ROOT)bin\($fs)\($ft)'
  ]

  let env_path = (
    if ($ft == x64) {
      ($env_path | prepend ($'($env.MSVS_ROOT)\..\Shared\Common\VSPerfCollectionTools\vs2019\x64' | path expand))
    } else {
      $env_path
    }
  )

  let env_path = (
    if ($ft == x64) {
      ($env_path | prepend $'($env.MSVS_ROOT)\Team Tools\Performance Tools\x64')
    } else {
      $env_path
    }
  )

  let env_path = (
    if ($ft != $fh) {
      ($env_path | prepend $'($env.MSVS_MSVC_ROOT)\bin\Host($fh)\($fh)')
    } else {
      $env_path
    }
  )

  let env_path = ($env.MSVS_BASE_PATH | prepend $env_path)

  let lib_path = (
    [
      $'($env.MSVS_MSDK_ROOT)Lib\($env.MSVS_MSDK_VER)\ucrt\($ft)'
      $'($env.MSVS_MSDK_ROOT)Lib\($env.MSVS_MSDK_VER)\um\($ft)'
      $'($env.MSVS_MSVC_ROOT)\lib\($ft)'
    ] | str join (char esep)
  )

  if (not $silent) {
    print "Activating Microsoft Visual Studio environment."
  }
  load-env {
    $env.PATH_VAR: $env_path
    INCLUDE: $env.MSVS_INCLUDE_PATH
    LIB: $lib_path
  }

  # Debug Information
  # print $"PATH_VAR: ($env.PATH_VAR)"
  # print $"INCLUDE: ($env.INCLUDE)"
  # print $"LIB: ($env.LIB)"
}

export def --env "gen clangd" [output_path: string = ".clangd"] {
  find_msvs

  let atlmfc = ([$env.MSVS_MSVC_ROOT "atlmfc" "include"] | path join | str replace --all '\' '\\')
  let msvc_inc = ([$env.MSVS_MSVC_ROOT "include"] | path join | str replace --all '\' '\\')
  let sdk_um = ([$env.MSVS_MSDK_ROOT "Include" $env.MSVS_MSDK_VER "um"] | path join | str replace --all '\' '\\')
  let sdk_sh = ([$env.MSVS_MSDK_ROOT "Include" $env.MSVS_MSDK_VER "shared"] | path join | str replace --all '\' '\\')
  let sdk_ucrt = ([$env.MSVS_MSDK_ROOT "Include" $env.MSVS_MSDK_VER "ucrt"] | path join | str replace --all '\' '\\')
  let sdk_winrt = ([$env.MSVS_MSDK_ROOT "Include" $env.MSVS_MSDK_VER "winrt"] | path join | str replace --all '\' '\\')
  let content = $"# .clangd configuration template for MSVC projects
# 
# This file should be placed in the root of your project directory,
# next to compile_commands.json
#
# Generated by ms2cc for use with clangd and MSVC compile_commands.json
# See: https://clangd.llvm.org/config for full documentation

Diagnostics:
  # Suppress common MSVC-related warnings that are noisy in clangd
  Suppress:
    - ignored-pragmas              # MSVC-specific #pragma optimize, etc.
    - missing-field-initializers   # Common in MSVC codebases using aggregate init
    - unused-const-variable        # Often intentional in headers
    - null-pointer-subtraction     # Used in some low-level code patterns
    - ignored-qualifiers           # const on return types \(old MSVC pattern\)
    - unused-but-set-variable      # Debug/retail conditional code
  
  # Don't report unused includes - too noisy for large MSVC projects
  UnusedIncludes: None
  
  # Don't report missing includes
  MissingIncludes: None

# Uncomment to suppress clang-tidy checks:
# Diagnostics:
#   ClangTidy:
#     Remove: ['modernize-*', 'readability-*']

# The compile_commands.json generated by ms2cc already contains
# correctly formatted flags for clang-cl. clangd will automatically
# use --driver-mode=cl when it sees MSVC-style flags.
#
# Uncomment to add or remove compiler flags if needed:
CompileFlags:
  Add:
    - \"-std=c++20\"
    - \"-ferror-limit=0\"              # No limit
    - \"-fdelayed-template-parsing\"   # MSVC-style template parsing
    - \"-fms-compatibility\"           # Enable MSVC compatibility
    - \"-fms-extensions\"              # Enable MSVC extensions
    # CryptoPP explicitly errors if both _MSC_VER and __clang__ are defined
    # simultaneously, which happens when clangd runs in clang-cl mode.
    - -D__clang_analyzer__
    - -D_AFXDLL
    - \"-imsvc ($atlmfc)\"
    - \"-imsvc ($msvc_inc)\"
    - \"-imsvc ($sdk_um)\"
    - \"-imsvc ($sdk_sh)\"
    - \"-imsvc ($sdk_ucrt)\"
    - \"-imsvc ($sdk_winrt)\"

#   Remove:
#     - \"/some-problematic-flag\"

# For large codebases, you may want to tune indexing performance.
# Uncomment and adjust as needed:
# Index:
#   Background: 2              # Limit background indexing threads \(default: 4\)
#   StandardLibrary: No        # Don't index STL \(faster startup\)

Hover:
  ShowAKA: Yes                 # Show type aliases and \"also known as\" info

InlayHints:
  Enabled: Yes                 # Enable inline parameter and type hints
  ParameterNames: Yes          # Show parameter names inline
  DeducedTypes: Yes            # Show deduced types inline
  # Note: Disable these if you find inline hints distracting

# ============================================================================
# Per-file or per-directory overrides
# ============================================================================
# You can add additional YAML documents below \(separated by '---'\)
# to override settings for specific files or directories.
#
# Example: Suppress warnings in test files
# ---
# If:
#   PathMatch: .*test.*
# Diagnostics:
#   Suppress:
#     - unused-parameter
#
# Example: Add flags for specific directory
# ---
# If:
#   PathMatch: src/SpecificModule/.*
# CompileFlags:
#   Add:
#     - \"-DMODULE_SPECIFIC_FLAG\"
#
# Example: Suppress MSVC-specific __m128i union access errors
# ---
# If:
#   PathMatch: .*ClMulCrcSSE\\.cpp
# Diagnostics:
#   Suppress:
#     - typecheck_member_reference_struct_union"
  $content | save --force $output_path
  print $"Saved to ($output_path)"
}

export def --env deactivate [] {
  if (($env.MSVS_ROOT | is-empty) or ($env.MSVS_MSVC_ROOT | is-empty)) {
    print "Either Microsoft Visual Studio or MSVC is valid."
    return
  }

  load-env {
    $env.PATH_VAR: $env.MSVS_BASE_PATH
  }

  hide-env INCLUDE
  hide-env LIB
  hide-env MSVS_BASE_PATH
  hide-env MSVS_ROOT
  hide-env MSVS_MSVC_ROOT
  hide-env MSVS_MSDK_ROOT
  hide-env MSVS_MSDK_VER
  hide-env MSVS_INCLUDE_PATH
}
