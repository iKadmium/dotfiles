#!/usr/bin/env nu
# Usage: get-age-key.nu [output-path]
# Fetches the Chezmoi age key from LastPass via a Docker container and writes
# it to [output-path], or prints it to stdout if omitted.

def cleanup [image: string] {
    ^docker image rm --force $image out+err>| ignore
}

def main [key_file?: string] {
    let email     = "jesse.d.higginson@gmail.com"
    let note_name = "Chezmoi Age Key"
    let image     = "lpass-chezmoi-tmp"
    let script_dir = ($env.CURRENT_FILE | path dirname)
    let dockerfile = ($script_dir | path join "lpass.Dockerfile")

    # ── Build image ───────────────────────────────────────────────────────────
    print --stderr $"(ansi cyan)Building LastPass container...(ansi reset)"
    let build = (^docker build -q -t $image -f $dockerfile $script_dir | complete)
    if $build.exit_code != 0 {
        cleanup $image
        error make {msg: "Docker build failed."}
    }

    # ── Login + retrieve in a single container run ────────────────────────────
    # The note is written to a mounted temp file; docker runs with -i so
    # lpass can read password input from the caller's stdin.
    let tmpfile = if ("TMPDIR" in $env) {
        $env.TMPDIR | path join "chezmoi-age-key.txt"
    } else if ("TEMP" in $env) {
        $env.TEMP | path join "chezmoi-age-key.txt"
    } else {
        "/tmp/chezmoi-age-key.txt"
    }

    print --stderr $"(ansi cyan)Authenticating with LastPass...(ansi reset)"
    "" | save --force $tmpfile
    ^docker run --rm -it -v $"($tmpfile):/tmp/note.txt" $image $email $note_name
    if $env.LAST_EXIT_CODE != 0 {
        cleanup $image
        rm --force $tmpfile
        error make {msg: $"Failed to retrieve secret '($note_name)'."}
    }

    let note = (open $tmpfile | str trim)
    rm --force $tmpfile
    cleanup $image

    if ($key_file == null) {
        print $note
    } else {
        $note | save --force $key_file
        if $nu.os-info.name != "windows" {
            ^chmod 600 $key_file
        }
        print --stderr $"(ansi green)Age key written to ($key_file)(ansi reset)"
    }
}
