# deploy.ps1 — set up PowerShell profile to source all alias .ps1 files
# Works on Windows (pwsh) and macOS/Linux (pwsh).
# Usage: pwsh ~/alias/deploy.ps1

$repoDir = $PSScriptRoot

# Determine profile path
$profilePath = $PROFILE.CurrentUserAllHosts

# Ensure profile directory exists
$profileDir = Split-Path $profilePath
if (-not (Test-Path $profileDir)) {
    New-Item $profileDir -ItemType Directory -Force | Out-Null
}

# Back up existing profile
if (Test-Path $profilePath) {
    $ts     = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup = "$profilePath.bak_$ts"
    Copy-Item $profilePath $backup
    Write-Host "Backed up existing profile to: $backup"
}

# Files to source, in load order
$files = @(
    "alias.ps1",
    "gitalias.ps1",
    "jump.ps1",
    "raspberryalias.ps1",
    "synologyalias.ps1"
)

# Build dot-source lines; skip if already present
$existing = if (Test-Path $profilePath) { Get-Content $profilePath -Raw } else { "" }

$added = 0
foreach ($f in $files) {
    $full = Join-Path $repoDir $f
    if (-not (Test-Path $full)) { continue }
    # Normalise to forward slashes for cross-platform readability
    $line = ". '$($full.Replace('\', '/'))'"
    if ($existing -notmatch [regex]::Escape($full.Replace('\', '/'))) {
        Add-Content $profilePath "`n$line"
        Write-Host "Added: $line"
        $added++
    } else {
        Write-Host "Already present: $f"
    }
}

if ($added -gt 0) {
    Write-Host "`ndeploy.ps1: $added file(s) added to profile."
    Write-Host "Reload profile with: . `$PROFILE.CurrentUserAllHosts"
} else {
    Write-Host "`ndeploy.ps1: profile already up to date."
}
