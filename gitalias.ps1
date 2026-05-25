# gitalias.ps1 — PowerShell equivalents of gitalias.zsh
# Requires git in PATH. Source from $PROFILE via deploy.ps1.

# Remove built-in PS aliases that would shadow our git shortcuts
# (PS resolution order: aliases > functions — so aliases must be removed first)
'gi','gc','gl' | ForEach-Object { Remove-Item "Alias:$_" -Force -ErrorAction SilentlyContinue }

# ── Helper ────────────────────────────────────────────────────────────────────

# _GitDefaultBranch — detect default branch (main or master)
function _GitDefaultBranch {
    git rev-parse --verify main 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { "main" } else { "master" }
}

# ── Standard aliases ──────────────────────────────────────────────────────────

# gi — git init
function gi   { git init @args }
# gcl — git clone
function gcl  { git clone @args }
# ga — git add
function ga   { git add @args }
# gc — git commit -m
function gc   { git commit -m @args }
# gac — git commit -a -m
function gac  { git commit -a -m @args }
# gaca — git commit -a --amend
function gaca { git commit -a --amend @args }
# gch — git checkout
function gch  { git checkout @args }
# gb — git branch
function gb   { git branch @args }
# gm — git merge
function gm   { git merge @args }
# gdi — git diff
function gdi  { git diff @args }
# gdin — git diff --name-only
function gdin { git diff --name-only @args }
# gt — git tag
function gt   { git tag @args }
# gl — git log --decorate --graph --all
function gl   { git log --decorate --graph --all @args }
# glo — git log --oneline
function glo  { git log --oneline @args }
# glf — git log -- (file history)
function glf  { git log -- @args }
# glfp — git log -p -- (file history with patch)
function glfp { git log -p -- @args }
# grh — git reset HEAD --hard
function grh  { git reset HEAD --hard @args }
# gre — git reset
function gre  { git reset @args }
# gdt — git difftool
function gdt  { git difftool @args }
# gpl — git pull
function gpl  { git pull @args }
# gf — git fetch
function gf   { git fetch @args }
# gr — git remote -v
function gr   { git remote -v @args }
# grs — git remote set-url origin
function grs  { git remote set-url origin @args }
# gbl — git blame
function gbl  { git blame @args }
# gbis — git bisect start
function gbis { git bisect start @args }
# gbir — git bisect reset
function gbir { git bisect reset @args }
# gbig — git bisect good
function gbig { git bisect good @args }
# gbib — git bisect bad
function gbib { git bisect bad @args }
# gst — git stash
function gst  { git stash @args }
# gstp — git stash pop
function gstp { git stash pop @args }
# grl — git reflog
function grl  { git reflog @args }

# ── Smart functions ───────────────────────────────────────────────────────────

# gs — git status -s + fetch + diff vs default branch origin
function gs {
    $b = _GitDefaultBranch
    git status -s
    git fetch
    git diff $b "origin/$b"
}

# gps — git push origin <default-branch> --tags [extra args]
function gps {
    $b = _GitDefaultBranch
    git push origin $b --tags @args
}

# gdm — git diff <default-branch> origin/<default-branch>
function gdm {
    $b = _GitDefaultBranch
    git diff $b "origin/$b" @args
}

# ── History management ────────────────────────────────────────────────────────

# gstrip — replace full history with single commit (current files only)
function gstrip {
    $b = _GitDefaultBranch
    git checkout --orphan _stripped
    git add -A
    git commit -m "stripped"
    git branch -D $b
    git branch -m $b
}

# gplstrip — update files from remote without restoring history
function gplstrip {
    git fetch origin
    $b = _GitDefaultBranch
    git reset --hard "origin/$b"
}

# grestore — wipe local repo and re-clone fresh with full history
function grestore {
    $remote = git remote get-url origin 2>$null
    if (-not $remote) { Write-Error "No remote origin found"; return }
    $dir  = Get-Location
    $name = Split-Path $dir -Leaf
    Set-Location ..
    Remove-Item $dir -Recurse -Force
    git clone $remote $name
    Set-Location $dir
}
