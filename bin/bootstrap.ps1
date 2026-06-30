#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$DOTFILES_REPO = "https://github.com/ikadmium/dotfiles.git"

function Test-WingetPackage {
    param([string]$Id)
    $result = winget list --id $Id --exact --accept-source-agreements 2>&1
    return $LASTEXITCODE -eq 0 -and ($result -match $Id)
}

function Install-WingetPackage {
    param([string]$Id, [string]$Name)
    if (Test-WingetPackage $Id) {
        Write-Host "$Name is already installed, skipping."
    } else {
        Write-Host "Installing $Name..."
        winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install $Name (winget exit code $LASTEXITCODE)"
        }
    }
}

# ── 1. Ensure winget is available ────────────────────────────────────────────
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is not available. Please install App Installer from the Microsoft Store and re-run."
}

# ── 2. Install dependencies ──────────────────────────────────────────────────
Install-WingetPackage "Twpayne.Chezmoi"         "chezmoi"
Install-WingetPackage "Nushell.Nushell"         "nushell"
Install-WingetPackage "Docker.DockerDesktop"    "Docker Desktop"

# Refresh PATH so newly installed tools are visible in this session
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("PATH", "User")

# ── 3. Ensure Docker is running ──────────────────────────────────────────────
Write-Host "Waiting for Docker to be ready..."
$attempts = 0
do {
    Start-Sleep -Seconds 3
    $dockerReady = (docker info 2>&1) -notmatch "error"
    $attempts++
    if ($attempts -ge 20) { throw "Docker did not become ready in time. Start Docker Desktop and re-run." }
} while (-not $dockerReady)

# ── 4. Initialize chezmoi ────────────────────────────────────────────────────
# chezmoi will handle LastPass auth via Docker when processing the config template
Write-Host "Initializing dotfiles..."
chezmoi init --apply $DOTFILES_REPO

Write-Host ""
Write-Host "Bootstrap complete."
