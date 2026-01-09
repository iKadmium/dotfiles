# Dracula Theme for Nushell
# Official Dracula colors: https://draculatheme.com/contribute

# Export the Dracula theme
export def main [] {
    # Dracula color palette
    let dracula_background = "#282a36"
    let dracula_current_line = "#44475a"
    let dracula_foreground = "#f8f8f2"
    let dracula_comment = "#6272a4"
    let dracula_cyan = "#8be9fd"
    let dracula_green = "#50fa7b"
    let dracula_orange = "#ffb86c"
    let dracula_pink = "#ff79c6"
    let dracula_purple = "#bd93f9"
    let dracula_red = "#ff5555"
    let dracula_yellow = "#f1fa8c"

    {
        # Primitives
        separator: $dracula_comment
        leading_trailing_space_bg: $dracula_current_line
        header: { fg: $dracula_cyan attr: b }
        empty: $dracula_purple
        bool: $dracula_purple
        int: $dracula_purple
        filesize: $dracula_cyan
        duration: $dracula_pink
        date: $dracula_pink
        datetime: $dracula_pink
        range: $dracula_pink
        float: $dracula_purple
        string: $dracula_yellow
        nothing: $dracula_orange
        binary: $dracula_orange
        cell-path: $dracula_foreground
        row_index: { fg: $dracula_cyan attr: b }
        record: $dracula_foreground
        list: $dracula_foreground
        block: $dracula_foreground
        hints: $dracula_comment

        # Shapes (syntax highlighting)
        shape_garbage: { fg: $dracula_foreground bg: $dracula_red attr: b }
        shape_binary: $dracula_purple
        shape_bool: $dracula_purple
        shape_int: $dracula_purple
        shape_float: $dracula_purple
        shape_range: { fg: $dracula_pink attr: b }
        shape_internalcall: { fg: $dracula_cyan attr: b }
        shape_external: $dracula_green
        shape_externalarg: $dracula_foreground
        shape_literal: $dracula_cyan
        shape_operator: $dracula_pink
        shape_signature: { fg: $dracula_green attr: b }
        shape_string: $dracula_yellow
        shape_string_interpolation: { fg: $dracula_cyan attr: b }
        shape_datetime: { fg: $dracula_pink attr: b }
        shape_list: { fg: $dracula_cyan attr: b }
        shape_table: { fg: $dracula_purple attr: b }
        shape_record: { fg: $dracula_cyan attr: b }
        shape_block: { fg: $dracula_cyan attr: b }
        shape_filepath: $dracula_green
        shape_directory: $dracula_cyan
        shape_globpattern: { fg: $dracula_cyan attr: b }
        shape_variable: $dracula_foreground
        shape_flag: { fg: $dracula_pink attr: b }
        shape_custom: $dracula_green
        shape_nothing: $dracula_orange
        shape_pipe: { fg: $dracula_pink attr: b }
        shape_redirection: { fg: $dracula_pink attr: b }
        shape_and: { fg: $dracula_pink attr: b }
        shape_or: { fg: $dracula_pink attr: b }
        shape_keyword: { fg: $dracula_pink attr: b }
        shape_match_pattern: $dracula_green
    }
}

# Alternate export for direct usage
export def dracula_theme [] {
    main
}
