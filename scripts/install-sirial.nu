#!/usr/bin/env nu
# Installs the latest Sirial VST3 plugin from GitHub to C:\Program Files\Common Files\VST3

def is-admin [] {
    let result = (^powershell.exe -NoProfile -Command
        "[bool](([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
        | str trim)
    $result == "True"
}

def main [] {
    let repo = "tiagolr/sirial"
    let install_dir = 'C:\Program Files\Common Files\VST3'

    # ── Elevate if not running as administrator ───────────────────────────────
    if not (is-admin) {
        print $"(ansi yellow)Not running as administrator — relaunching elevated...(ansi reset)"
        ^powershell.exe -NoProfile -Command $"Start-Process nu -ArgumentList '($env.CURRENT_FILE)' -Verb RunAs -Wait"
        return
    }

    # ── Fetch latest release info ─────────────────────────────────────────────
    print $"(ansi cyan)Fetching latest Sirial release...(ansi reset)"
    let release = (http get $"https://api.github.com/repos/($repo)/releases/latest")
    let tag = $release.tag_name
    print $"Latest version: (ansi green)($tag)(ansi reset)"

    # ── Find the Windows asset ────────────────────────────────────────────────
    let asset = (
        $release.assets
        | where name =~ 'win'
        | first
    )
    let download_url = $asset.browser_download_url
    let zip_name = $asset.name

    # ── Download ──────────────────────────────────────────────────────────────
    let tmp_dir = ($env.TEMP | path join "sirial-install")
    let zip_path = ($tmp_dir | path join $zip_name)

    mkdir $tmp_dir
    print $"(ansi cyan)Downloading ($zip_name)...(ansi reset)"
    http get $download_url | save --force $zip_path

    # ── Extract ───────────────────────────────────────────────────────────────
    print $"(ansi cyan)Extracting...(ansi reset)"
    let extract_dir = ($tmp_dir | path join "extracted")
    ^powershell.exe -NoProfile -Command $"Expand-Archive -Force '($zip_path)' '($extract_dir)'"

    # ── Find the .vst3 folder and install ────────────────────────────────────
    # Archive structure: sirial-win/Sirial.vst3/
    let vst3_src = ($extract_dir | path join "sirial-win" "Sirial.vst3")
    if not ($vst3_src | path exists) {
        error make {msg: $"Expected VST3 not found at: ($vst3_src)"}
    }

    print $"(ansi cyan)Installing to ($install_dir)...(ansi reset)"
    let dest = ($install_dir | path join "Sirial.vst3")
    ^powershell.exe -NoProfile -Command $"Copy-Item -Recurse -Force '($vst3_src)' '($dest)'"
    print $"Installed: (ansi green)($dest)(ansi reset)"

    # ── Cleanup ───────────────────────────────────────────────────────────────
    rm -rf $tmp_dir
    print $"(ansi green)Done!(ansi reset)"
}
