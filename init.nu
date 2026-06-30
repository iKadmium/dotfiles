#!/usr/bin/env nu

# Post-installation configuration for installed packages

# Starship init
let starship_init = ($nu.home-dir | path join ".cache" "starship" "init.nu")
if not ($starship_init | path exists) {
    mkdir ($nu.home-dir | path join ".cache" "starship")
    starship init nu | save $starship_init
}

# Zoxide init
let zoxide_init = ($nu.home-dir | path join ".zoxide.nu")
if not ($zoxide_init | path exists) {
    zoxide init nushell --cmd cd | save $zoxide_init
}

# Television init
let tv_init = ($nu.home-dir | path join ".config" "nushell" "vendor" "autoload" "tv.nu")
if not ($tv_init | path exists) {
    mkdir ($nu.home-dir | path join ".config" "nushell" "vendor" "autoload")
    tv init nu | save $tv_init
}

# Carapace init (non-Windows only)
if $nu.os-info.name != "windows" {
    let carapace_init = ($nu.home-dir | path join ".cache" "carapace" "init.nu")
    if not ($carapace_init | path exists) {
        mkdir ($nu.home-dir | path join ".cache" "carapace")
        with-env { CARAPACE_BRIDGES: "zsh,fish,bash" } {
            carapace _carapace nushell | save $carapace_init
        }
    }
}
