# jump.ps1 — PowerShell equivalent of jump.sh
# j: jump to cached directory by partial name
# Set-Location wrapper: auto-caches every directory visit
# Source from $PROFILE via deploy.ps1.

$global:JumpCache = Join-Path $HOME ".jumplocations"

# _JumpAdd <path> — add path to cache if not already present (helper)
function _JumpAdd {
    param([string]$Path)
    if (-not (Test-Path $global:JumpCache)) {
        New-Item $global:JumpCache -ItemType File -Force | Out-Null
    }
    $existing = Get-Content $global:JumpCache -ErrorAction SilentlyContinue
    if ($existing -notcontains $Path) {
        Add-Content $global:JumpCache $Path
    }
}

# Override Set-Location to cache visited dirs (wrap builtin)
# Override Set-Location using module-qualified builtin to avoid recursion
function Set-Location {
    param([Parameter(Position=0, ValueFromPipeline)][string]$Path)
    if ($Path) { Microsoft.PowerShell.Management\Set-Location $Path }
    else       { Microsoft.PowerShell.Management\Set-Location }
    if ($?) { _JumpAdd (Get-Location).Path }
}

# j <partial-name> — jump to cached directory; -d remove current; -dr remove recursive
function j {
    param([string]$Query)

    if (-not $Query) {
        "Usage: j <partial-folder-name>"
        "       j -d   remove current dir from jump cache"
        "       j -dr  remove current dir and all subdirs from cache"
        return
    }

    $cache = $global:JumpCache
    if (-not (Test-Path $cache)) {
        "No cached locations found."
        return
    }

    $pwd = (Get-Location).Path

    if ($Query -eq "-d" -or $Query -eq "--delete-current") {
        $lines = Get-Content $cache | Where-Object { $_ -ne $pwd }
        Set-Content $cache ($lines -join "`n")
        Write-Host "Removed: $pwd"
        return
    }

    if ($Query -eq "-dr" -or $Query -eq "--delete-current-recursive") {
        $lines = Get-Content $cache | Where-Object { $_ -ne $pwd -and -not $_.StartsWith("$pwd$([System.IO.Path]::DirectorySeparatorChar)") }
        $removed = (Get-Content $cache).Count - $lines.Count
        Set-Content $cache ($lines -join "`n")
        Write-Host "Removed $removed director$(if ($removed -eq 1) {'y'} else {'ies'}) under $pwd"
        return
    }

    $queryLower = $Query.ToLower()

    # Read cache, clean non-existent dirs, find matches
    $all     = Get-Content $cache | Where-Object { $_ -ne "" }
    $valid   = $all | Where-Object { Test-Path $_ }
    $matches = $valid | Where-Object { (Split-Path $_ -Leaf).ToLower().Contains($queryLower) }

    # Rewrite cache: valid only, deduplicated
    $deduped = $valid | Select-Object -Unique
    Set-Content $cache ($deduped -join "`n")

    if (-not $matches) {
        "No match found for: $Query"
        return
    }

    $matchList = @($matches)
    if ($matchList.Count -eq 1) {
        Microsoft.PowerShell.Management\Set-Location $matchList[0]
        _JumpAdd $matchList[0]
        Get-Location
        return
    }

    Write-Host "Multiple matches:"
    for ($i = 0; $i -lt $matchList.Count; $i++) {
        Write-Host "  $($i+1)) $($matchList[$i])"
    }
    $sel = Read-Host "Select [1-$($matchList.Count)]"
    if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $matchList.Count) {
        Microsoft.PowerShell.Management\Set-Location $matchList[[int]$sel - 1]
        _JumpAdd $matchList[[int]$sel - 1]
        Get-Location
    } else {
        Write-Host "Invalid selection."
    }
}
