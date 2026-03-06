# Retrieve the theme settings
export def main [] {
    return {
        binary: '#957FB8'
        block: '#7E9CD8'
        cell-path: '#DCD7BA'
        closure: '#7AA89F'
        custom: '#C8C093'
        duration: '#E6C384'
        float: '#E46876'
        glob: '#C8C093'
        int: '#957FB8'
        list: '#7AA89F'
        nothing: '#E46876'
        range: '#E6C384'
        record: '#7AA89F'
        string: '#98BB6C'

        bool: {|| if $in { '#7AA89F' } else { '#E6C384' } }

        date: {|| (date now) - $in |
            if $in < 1hr {
                { fg: '#E46876' attr: 'b' }
            } else if $in < 6hr {
                '#E46876'
            } else if $in < 1day {
                '#E6C384'
            } else if $in < 3day {
                '#98BB6C'
            } else if $in < 1wk {
                { fg: '#98BB6C' attr: 'b' }
            } else if $in < 6wk {
                '#7AA89F'
            } else if $in < 52wk {
                '#7E9CD8'
            } else { 'dark_gray' }
        }

        filesize: {|e|
            if $e == 0b {
                '#DCD7BA'
            } else if $e < 1mb {
                '#7AA89F'
            } else {{ fg: '#7E9CD8' }}
        }

        shape_and: { fg: '#957FB8' attr: 'b' }
        shape_binary: { fg: '#957FB8' attr: 'b' }
        shape_block: { fg: '#7E9CD8' attr: 'b' }
        shape_bool: '#7AA89F'
        shape_closure: { fg: '#7AA89F' attr: 'b' }
        shape_custom: '#98BB6C'
        shape_datetime: { fg: '#7AA89F' attr: 'b' }
        shape_directory: '#7AA89F'
        shape_external: '#7AA89F'
        shape_external_resolved: '#7AA89F'
        shape_externalarg: { fg: '#98BB6C' attr: 'b' }
        shape_filepath: '#7AA89F'
        shape_flag: { fg: '#7E9CD8' attr: 'b' }
        shape_float: { fg: '#E46876' attr: 'b' }
        shape_garbage: { fg: '#1F1F28' bg: '#E82424' attr: 'b' }
        shape_glob_interpolation: { fg: '#7AA89F' attr: 'b' }
        shape_globpattern: { fg: '#7AA89F' attr: 'b' }
        shape_int: { fg: '#957FB8' attr: 'b' }
        shape_internalcall: { fg: '#7AA89F' attr: 'b' }
        shape_keyword: { fg: '#957FB8' attr: 'b' }
        shape_list: { fg: '#7AA89F' attr: 'b' }
        shape_literal: '#7E9CD8'
        shape_match_pattern: '#98BB6C'
        shape_matching_brackets: { attr: 'u' }
        shape_nothing: '#E46876'
        shape_operator: '#E6C384'
        shape_or: { fg: '#957FB8' attr: 'b' }
        shape_pipe: { fg: '#957FB8' attr: 'b' }
        shape_range: { fg: '#E6C384' attr: 'b' }
        shape_raw_string: { fg: '#C8C093' attr: 'b' }
        shape_record: { fg: '#7AA89F' attr: 'b' }
        shape_redirection: { fg: '#957FB8' attr: 'b' }
        shape_signature: { fg: '#98BB6C' attr: 'b' }
        shape_string: '#98BB6C'
        shape_string_interpolation: { fg: '#7AA89F' attr: 'b' }
        shape_table: { fg: '#7E9CD8' attr: 'b' }
        shape_vardecl: { fg: '#7E9CD8' attr: 'u' }
        shape_variable: '#957FB8'

        foreground: '#DCD7BA'
        background: '#1F1F28'
        cursor: '#C8C093'

        empty: '#7E9CD8'
        header: { fg: '#98BB6C' attr: 'b' }
        hints: '#54546D'
        leading_trailing_space_bg: { attr: 'n' }
        row_index: { fg: '#98BB6C' attr: 'b' }
        search_result: { fg: '#E46876' bg: '#DCD7BA' }
        separator: '#DCD7BA'
    }
}

# Update the Nushell configuration
export def --env "set color_config" [] {
    $env.config.color_config = (main)
}

# Update terminal colors
export def "update terminal" [] {
    let theme = (main)

    # Set terminal colors
    let osc_screen_foreground_color = '10;'
    let osc_screen_background_color = '11;'
    let osc_cursor_color = '12;'
        
    $"
    (ansi -o $osc_screen_foreground_color)($theme.foreground)(char bel)
    (ansi -o $osc_screen_background_color)($theme.background)(char bel)
    (ansi -o $osc_cursor_color)($theme.cursor)(char bel)
    "
    # Line breaks above are just for source readability
    # but create extra whitespace when activating. Collapse
    # to one line and print with no-newline
    | str replace --all "\n" ''
    | print -n $"($in)\r"
}

export module activate {
    export-env {
        set color_config
        update terminal
    }
}

# Activate the theme when sourced
use activate
