# alias.ps1 — PowerShell equivalents of alias.zsh
# Requires PowerShell 7+. Source from $PROFILE via deploy.ps1.
# alh: Get-Content $PSCommandPath | Select-String '# [\w_][\w_\-]*.*—' | ForEach-Object { $_.Line.Trim() }

# Remove built-in aliases that would shadow our functions
'psfe', 'psfed', 'sdf' | ForEach-Object { Remove-Item "Alias:$_" -Force -ErrorAction SilentlyContinue }

# ── Navigation ───────────────────────────────────────────────────────────────

# up — go up one directory
function up { Set-Location .. }
# hom — go to home directory
function hom { Set-Location ~ }
# home — go to home directory
function home { Set-Location ~ }
# sdf — show current directory path
function sdf { Get-Location }
# lo — exit shell
function lo { exit }
# cls — clear screen
function cls { Clear-Host }
# md — make directory
function md { param([string]$Path) New-Item -ItemType Directory -Path $Path }
# rd — remove directory
function rd { param([string]$Path) Remove-Item -Recurse -Force -Path $Path }
# mov — move file or directory
function mov { param([string]$Source, [string]$Dest) Move-Item -Path $Source -Destination $Dest }

# Platform-specific: open current dir in file manager
# x — open current directory in Finder (macOS) or Explorer (Windows)
function x {
    if ($IsWindows) { explorer.exe . }
    else            { open . }
}

# np — open file in text editor (TextEdit on macOS, Notepad on Windows)
function np {
    param([string]$File = "")
    if ($IsWindows) { notepad.exe $File }
    else            { open -e $File }
}

# w — open file/folder/URL in default app
function w {
    param([string]$Target)
    if ($IsWindows) { Start-Process $Target }
    else            { open $Target }
}

# ia — show network interface info
function ia {
    if ($IsWindows) { ipconfig }
    else            { ifconfig }
}

# vsc — open VS Code
function vsc { code @args }

# ── File listing ──────────────────────────────────────────────────────────────

# d [filter...] — list files only (no dirs), human-readable; optional name filter
function d {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Filter)
    $items = Get-ChildItem -Force | Where-Object { -not $_.PSIsContainer }
    if ($Filter) {
        $items = $items | Where-Object {
            $name = $_.Name
            $Filter | ForEach-Object { $name -ilike $_ } | Where-Object { $_ } | Select-Object -First 1
        }
    }
    $items | ForEach-Object {
        $size = _PsHumanSize $_.Length
        "{0,-30}  {1,-20}  {2,7}" -f $_.Name, $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm"), $size
    }
}

# dd [filter...] — list directories only; optional name filter
function dd {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Filter)
    $items = Get-ChildItem -Force | Where-Object { $_.PSIsContainer }
    if ($Filter) {
        $items = $items | Where-Object {
            $name = $_.Name
            $Filter | ForEach-Object { $name -ilike $_ } | Where-Object { $_ } | Select-Object -First 1
        }
    }
    $items | Sort-Object Name | ForEach-Object { $_.Name }
}

# dt [filter...] — list all files/dirs modified today; optional name filter
function dt {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Filter)
    $today = (Get-Date).Date
    $items = Get-ChildItem -Force | Where-Object { $_.LastWriteTime.Date -eq $today }
    if ($Filter) {
        $items = $items | Where-Object {
            $name = $_.Name
            $Filter | ForEach-Object { $name -ilike $_ } | Where-Object { $_ } | Select-Object -First 1
        }
    }
    $items | Sort-Object Name | ForEach-Object { $_.Name }
}

# ff <pattern> [dir] — find files recursively, skipping hidden dirs
function ff {
    param([string]$Pattern, [string]$Dir = ".")
    Get-ChildItem -Path $Dir -Recurse -File -Filter "*$Pattern*" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[/\\]\.' } |
        ForEach-Object { $_.FullName }
}

# fff <pattern> [dir] — find files recursively, including hidden
function fff {
    param([string]$Pattern, [string]$Dir = ".")
    Get-ChildItem -Path $Dir -Recurse -File -Filter "*$Pattern*" -Force -ErrorAction SilentlyContinue |
        ForEach-Object { $_.FullName }
}

# fr — show free/used/total disk space for current drive
function fr {
    $drive = (Get-Location).Drive
    $disk  = Get-PSDrive -Name $drive.Name
    $used  = $disk.Used
    $free  = $disk.Free
    $total = $used + $free
    "Free: {0}  Used: {1}  Total: {2}" -f (_PsHumanSize $free), (_PsHumanSize $used), (_PsHumanSize $total)
}

# psfe [dir] — count files grouped by extension, sorted by count descending
function psfe {
    param([string]$Dir = ".")
    Get-ChildItem -Path $Dir -Recurse -File -ErrorAction SilentlyContinue |
        Group-Object Extension |
        Sort-Object Count -Descending |
        ForEach-Object { "{0,-16} {1,5}" -f ($_.Name -replace '^$','(none)'), $_.Count }
}

# psfed [-d|-dr] [dir] — find empty directories; -d delete leaves; -dr delete recursively
function psfed {
    param(
        [switch]$d,
        [switch]$dr,
        [string]$Dir = "."
    )
    if ($dr) {
        do {
            $empty = Get-ChildItem -Path $Dir -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                Where-Object { (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 }
            $empty | ForEach-Object { Write-Host $_.FullName; Remove-Item $_.FullName -Force }
        } while ($empty.Count -gt 0)
    } elseif ($d) {
        Get-ChildItem -Path $Dir -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 } |
            ForEach-Object { Remove-Item $_.FullName -Force }
    } else {
        Get-ChildItem -Path $Dir -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 } |
            ForEach-Object { $_.FullName }
    }
}

# sshfp — show fingerprints of all SSH keys in ~/.ssh (private + public)
function sshfp {
    Get-ChildItem "$HOME/.ssh/id_*.pub" -ErrorAction SilentlyContinue | ForEach-Object {
        $pub = $_.FullName
        $pri = $pub -replace '\.pub$', ''
        Write-Host "--- $(Split-Path $pri -Leaf) ---"
        if (Test-Path $pri) {
            $fp = (ssh-keygen -lf $pri 2>$null) -split ' ' | Select-Object -First 2
            Write-Host "  private: $($fp -join ' ')"
        } else {
            Write-Host "  private: not found"
        }
        $fp = (ssh-keygen -lf $pub 2>$null) -split ' ' | Select-Object -First 2
        Write-Host "  public:  $($fp -join ' ')"
    }
}

# ── Tree display ──────────────────────────────────────────────────────────────

# _PsHumanSize <bytes> — format bytes as human-readable string (helper)
function _PsHumanSize {
    param([long]$Bytes)
    # Use InvariantCulture so decimal separator is always '.' regardless of system locale
    $ic = [System.Globalization.CultureInfo]::InvariantCulture
    if     ($Bytes -ge 1GB) { [string]::Format($ic, "{0:N1}G", $Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { [string]::Format($ic, "{0:N1}M", $Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { [string]::Format($ic, "{0:N1}K", $Bytes / 1KB) }
    else                    { "${Bytes}B" }
}

# _PsTreeHelper — recursive tree renderer (helper)
function _PsTreeHelper {
    param(
        [string]$Dir,
        [string]$Prefix,
        [bool]$ShowSize,
        [bool]$ShowHidden,
        [bool]$SortBySize
    )
    $gcArgs = @{ Path = $Dir; Force = $ShowHidden; ErrorAction = 'SilentlyContinue' }
    $items  = @(Get-ChildItem @gcArgs)
    # On Windows, dotfiles have no Hidden attribute — filter them explicitly when -h not set
    if (-not $ShowHidden) { $items = @($items | Where-Object { $_.Name -notlike '.*' }) }
    if ($SortBySize) {
        $items = @($items | Sort-Object {
            if ($_.PSIsContainer) {
                (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum).Sum
            } else { $_.Length }
        })
    } else {
        $items = @($items | Sort-Object Name)
    }
    $count = $items.Count
    for ($i = 0; $i -lt $count; $i++) {
        $item      = $items[$i]
        $isLast    = ($i -eq ($count - 1))
        $connector = if ($isLast) { "└── " } else { "├── " }
        $ext       = if ($isLast) { "    " } else { "│   " }
        $sizeTag   = ""
        if ($ShowSize) {
            if ($item.PSIsContainer) {
                $sz = (Get-ChildItem $item.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum).Sum
                $sizeTag = "[" + (_PsHumanSize ($sz ?? 0)) + "] "
            } else {
                $sizeTag = "[" + (_PsHumanSize $item.Length) + "] "
            }
        }
        "$Prefix$connector$sizeTag$($item.Name)"
        if ($item.PSIsContainer) {
            _PsTreeHelper $item.FullName "$Prefix$ext" $ShowSize $ShowHidden $SortBySize
        }
    }
}

# tree [dir] [-u] [-h] [-t] [-z] — display folder/file tree
#   -u  show sizes on each node
#   -h  show hidden files
#   -t  top-level dirs only with recursive total size
#   -z  with -t, sort by size ascending (largest last)
function tree {
    param(
        [string]$Path     = ".",
        [switch]$u,
        [switch]$h,
        [switch]$t,
        [switch]$z
    )
    $absPath = (Resolve-Path $Path).Path

    if ($t) {
        $items = @(Get-ChildItem -Path $absPath -Directory -Force:$h -ErrorAction SilentlyContinue)
        if (-not $h) { $items = @($items | Where-Object { $_.Name -notlike '.*' }) }
        $items = @($items | Sort-Object Name)
        $pairs = @($items | ForEach-Object {
            $sz = (Get-ChildItem $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue |
                Measure-Object Length -Sum).Sum ?? 0
            [pscustomobject]@{ Name = $_.Name; Size = $sz }
        })
        if ($z) { $pairs = @($pairs | Sort-Object Size) }
        $count = $pairs.Count
        $absPath
        for ($i = 0; $i -lt $count; $i++) {
            $connector = if ($i -eq ($count - 1)) { "└── " } else { "├── " }
            "$connector[$(_PsHumanSize $pairs[$i].Size)] $($pairs[$i].Name)"
        }
        return
    }

    if ($u) {
        $total = (Get-ChildItem $absPath -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object Length -Sum).Sum ?? 0
        "$absPath  [$(_PsHumanSize $total)]"
    } else {
        $absPath
    }
    _PsTreeHelper $absPath "" ([bool]$u) ([bool]$h) ([bool]$z)
}

# _PsTreedHelper — recursive dirs-only tree renderer (helper)
function _PsTreedHelper {
    param(
        [string]$Dir,
        [string]$Prefix,
        [bool]$ShowHidden
    )
    $items = @(Get-ChildItem -Path $Dir -Directory -Force:$ShowHidden -ErrorAction SilentlyContinue)
    if (-not $ShowHidden) { $items = @($items | Where-Object { $_.Name -notlike '.*' }) }
    $items = @($items | Sort-Object Name)
    $count = $items.Count
    for ($i = 0; $i -lt $count; $i++) {
        $item   = $items[$i]
        $isLast = ($i -eq ($count - 1))
        $connector = if ($isLast) { "└── " } else { "├── " }
        $ext       = if ($isLast) { "    " } else { "│   " }
        "$Prefix$connector$($item.Name)"
        _PsTreedHelper $item.FullName "$Prefix$ext" $ShowHidden
    }
}

# treed [dir] [-h] — display directory-only tree
function treed {
    param(
        [string]$Path = ".",
        [switch]$h
    )
    $absPath = (Resolve-Path $Path).Path
    $absPath
    _PsTreedHelper $absPath "" ([bool]$h)
}

# ── Loop utilities ────────────────────────────────────────────────────────────

# loop [<n>s] <cmd> [+ <cmd> ...] — repeatedly run command(s), clearing screen; ESC or Ctrl-C to stop
function loop {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Args)
    $wait = 2
    $startIdx = 0
    if ($Args -and $Args[0] -match '^(\d+)s$') {
        $wait = [int]$Matches[1]
        $startIdx = 1
    }
    $cmdParts = if ($Args) { $Args[$startIdx..($Args.Count - 1)] } else { @() }
    $cmd = ($cmdParts -join ' ') -replace '\s*\+\s*', '; '

    try {
        while ($true) {
            Clear-Host
            Invoke-Expression $cmd
            $deadline = [DateTime]::Now.AddSeconds($wait)
            while ([DateTime]::Now -lt $deadline) {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq [ConsoleKey]::Escape) { return }
                }
                Start-Sleep -Milliseconds 100
            }
        }
    } catch [System.Management.Automation.PipelineStoppedException] { }
}

# loopk [<n>s] <cmd> [+ <cmd> ...] — like loop but keeps output (no clear screen)
function loopk {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Args)
    $wait = 2
    $startIdx = 0
    if ($Args -and $Args[0] -match '^(\d+)s$') {
        $wait = [int]$Matches[1]
        $startIdx = 1
    }
    $cmdParts = if ($Args) { $Args[$startIdx..($Args.Count - 1)] } else { @() }
    $cmd = ($cmdParts -join ' ') -replace '\s*\+\s*', '; '

    try {
        while ($true) {
            Invoke-Expression $cmd
            $deadline = [DateTime]::Now.AddSeconds($wait)
            while ([DateTime]::Now -lt $deadline) {
                if ([Console]::KeyAvailable) {
                    $key = [Console]::ReadKey($true)
                    if ($key.Key -eq [ConsoleKey]::Escape) { return }
                }
                Start-Sleep -Milliseconds 100
            }
        }
    } catch [System.Management.Automation.PipelineStoppedException] { }
}

# ── Docker Compose ────────────────────────────────────────────────────────────

# _PsDcFile [dir] — resolve compose file path (prefers docker-compose.yml)
function _PsDcFile {
    param([string]$Dir = ".")
    if (Test-Path "$Dir/docker-compose.yml") { "$Dir/docker-compose.yml" }
    elseif (Test-Path "$Dir/compose.yml")    { "$Dir/compose.yml" }
    else                                     { "$Dir/docker-compose.yml" }
}

# dcu [folder] — docker compose up
function dcu  { param([string]$Dir = "."); docker compose -f (_PsDcFile $Dir) up }
# dcud [folder] — docker compose up -d (detached)
function dcud { param([string]$Dir = "."); docker compose -f (_PsDcFile $Dir) up -d }
# dcd [folder] — docker compose down
function dcd  { param([string]$Dir = "."); docker compose -f (_PsDcFile $Dir) down }

# dcde [folder] — docker compose down and erase all images/volumes/networks/orphans
function dcde {
    param([string]$Dir = ".")
    $ans = Read-Host "This will remove all containers, images, volumes and networks. Are you sure? [yes/N]"
    if ($ans -ne "yes") { Write-Host "Aborted."; return }
    docker compose -f (_PsDcFile $Dir) down --rmi all --volumes --remove-orphans
}

# dcinfo [-v] [name] — list containers; -v full inspect; name filters by wildcard
function dcinfo {
    param([switch]$v, [string]$Name = "")
    $filter = if ($Name) { "--filter", "name=$Name" } else { @() }
    if ($v) {
        docker ps -a @filter --format '{{.Names}}' | ForEach-Object {
            Write-Host "=== $_ ==="
            docker inspect $_
        }
    } else {
        docker ps -a @filter --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}'
    }
}

# dclog [name] [n] — show docker logs; n lines (default 10, 0=all); name filters containers
function dclog {
    param([string]$Name = "", [int]$Lines = 10)
    $filter = if ($Name) { "--filter", "name=$Name" } else { @() }
    $containers = docker ps -a @filter --format '{{.Names}}'
    if (-not $containers) {
        if ($Name) { Write-Error "dclog: no containers matching '$Name'" }
        else       { Write-Error "dclog: no containers" }
        return
    }
    $containers | ForEach-Object {
        Write-Host "=== $_ ==="
        if ($Lines -eq 0) { docker logs $_ 2>&1 }
        else              { docker logs --tail $Lines $_ 2>&1 }
    }
}

# soc — strip OceanofPDF branding from EPUB files
function soc { python3 "$HOME/alias/stripocean.py" @args }

# ── Help ──────────────────────────────────────────────────────────────────────

# alh [filter] — show one-line help for all functions from comments
function alh {
    param([string]$Filter = "")
    $files = Get-ChildItem (Split-Path $MyInvocation.MyCommand.ScriptBlock.File) -Filter "*.ps1" -ErrorAction SilentlyContinue
    $files | ForEach-Object {
        Get-Content $_.FullName |
            Select-String '^\s*#\s*[\w_][\w_\-]*.*—' |
            ForEach-Object { $_.Line.Trim() }
    } | Where-Object {
        $_ -notmatch '^#\s*(Requires|Source|alh)' -and
        ($Filter -eq "" -or $_ -imatch $Filter)
    }
}
