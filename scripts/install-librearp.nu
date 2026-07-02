#!/usr/bin/env nu
# Installs the latest LibreArp VST3 plugin from GitLab to C:\Program Files\Common Files\VST3

def is-admin [] {
    let result = (^powershell.exe -NoProfile -Command
        "[bool](([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
        | str trim)
    $result == "True"
}

def main [] {
    let project = "LibreArp%2FLibreArp"
    let install_dir = 'C:\Program Files\Common Files\VST3'

    # ── Elevate if not running as administrator ───────────────────────────────
    if not (is-admin) {
        print $"(ansi yellow)Not running as administrator — relaunching elevated...(ansi reset)"
        ^powershell.exe -NoProfile -Command $"Start-Process nu -ArgumentList '($env.CURRENT_FILE)' -Verb RunAs -Wait"
        return
    }

    # ── Fetch latest release via GitLab API ───────────────────────────────────
    print $"(ansi cyan)Fetching latest LibreArp release...(ansi reset)"
    let releases = (http get $"https://gitlab.com/api/v4/projects/($project)/releases?per_page=1")
    let release = ($releases | first)
    let tag = $release.tag_name
    print $"Latest version: (ansi green)($tag)(ansi reset)"

    # ── Extract Windows VST3 download URL from release description ────────────
    # The binaries are embedded as markdown links in the description, not as
    # formal GitLab release assets.
    let description = $release.description
    let win_url = (
        $description
        | parse --regex '\[Windows[^\]]*\]\((?P<url>[^)]+\.zip)\)'
        | first
        | get url
    )

    # ── Download ──────────────────────────────────────────────────────────────
    let tmp_dir = ($env.TEMP | path join "librearp-install")
    let zip_path = ($tmp_dir | path join "LibreArp.vst3.zip")

    mkdir $tmp_dir
    print $"(ansi cyan)Downloading LibreArp.vst3.zip...(ansi reset)"
    http get $win_url | save --force $zip_path

    # ── Extract directly into the VST3 folder ────────────────────────────────
    print $"(ansi cyan)Installing to ($install_dir)...(ansi reset)"
    ^powershell.exe -NoProfile -Command $"Expand-Archive -Force '($zip_path)' '($install_dir)'"

    # ── Cleanup ───────────────────────────────────────────────────────────────
    rm -rf $tmp_dir
    print $"(ansi green)Done!(ansi reset)"
}
