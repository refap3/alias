# synologyalias.ps1 — PowerShell equivalents of synologyalias.zsh
# Requires OpenSSH in PATH.
# Source from $PROFILE via deploy.ps1.

$script:SY_HOST = "192.168.1.116"
$script:SY_USER = "pipi"
$script:SY_KEY  = Join-Path $HOME ".ssh/id_rsa"
$script:SY_SSHOPT = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-o", "LogLevel=ERROR")

# _SyKeyOpt — return SSH key args for NAS (helper)
function _SyKeyOpt {
    if (Test-Path $script:SY_KEY) { @("-i", $script:SY_KEY) } else { @() }
}

function _SySftp {
    param([string[]]$Cmds)
    $Cmds | sftp @(_SyKeyOpt) @($script:SY_SSHOPT) -b - "$($script:SY_USER)@$($script:SY_HOST)"
}

# ── SSH ───────────────────────────────────────────────────────────────────────

# syp — interactive SSH session to NAS, with key
function syp  { ssh @(_SyKeyOpt) @($script:SY_SSHOPT) "$($script:SY_USER)@$($script:SY_HOST)" }
# sypp — interactive SSH session to NAS, password (no key)
function sypp { ssh @($script:SY_SSHOPT) "$($script:SY_USER)@$($script:SY_HOST)" }

# syc <cmd...> — run command on NAS via stdin → bash
function syc {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Cmd)
    $c = "shopt -s expand_aliases; $($Cmd -join ' ')"
    $c | ssh @(_SyKeyOpt) @($script:SY_SSHOPT) "$($script:SY_USER)@$($script:SY_HOST)" bash -i 2>$null
}

# ── SFTP ──────────────────────────────────────────────────────────────────────

# syw — interactive SFTP session to NAS
function syw { sftp @(_SyKeyOpt) @($script:SY_SSHOPT) "$($script:SY_USER)@$($script:SY_HOST)" }

# sywl [dir] — list remote directory on NAS
function sywl { param([string]$Dir = ".") _SySftp @("ls $Dir") }
# sywg <remote> [local] — download file/dir from NAS (scp -r)
function sywg { param([string]$Remote, [string]$Local = ".") scp -r @(_SyKeyOpt) @($script:SY_SSHOPT) "$($script:SY_USER)@$($script:SY_HOST)`:$Remote" $Local }
# sywu <local> [remote] — upload file/dir to NAS (scp -r)
function sywu { param([string]$Local, [string]$Remote = "~") scp -r @(_SyKeyOpt) @($script:SY_SSHOPT) $Local "$($script:SY_USER)@$($script:SY_HOST)`:$Remote" }
# sywmk <dir> — mkdir on NAS
function sywmk { param([string]$Dir) _SySftp @("mkdir $Dir") }
# sywrm <path> — rm on NAS (confirms first)
function sywrm {
    param([string]$Path)
    $ans = Read-Host "rm $Path on NAS ($($script:SY_HOST))? [y/N]"
    if ($ans -match '^[yY]') { _SySftp @("rm $Path") }
}

# ── Key setup ─────────────────────────────────────────────────────────────────

# syauth — add local pubkey to NAS authorized_keys (password prompt)
function syauth {
    $pubkey = Get-Content "$($script:SY_KEY).pub" -Raw -ErrorAction SilentlyContinue
    if (-not $pubkey) { Write-Error "syauth: $($script:SY_KEY).pub not found"; return }
    Write-Host "Step 1/2: adding pubkey (SSH password prompt)..."
    $pubkey | ssh @($script:SY_SSHOPT) "$($script:SY_USER)@$($script:SY_HOST)" `
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    Write-Host "Step 2/2: setting passwordless sudo (sudo password prompt)..."
    ssh @(_SyKeyOpt) @($script:SY_SSHOPT) -t "$($script:SY_USER)@$($script:SY_HOST)" `
        "echo '$($script:SY_USER) ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$($script:SY_USER) > /dev/null && sudo chmod 0440 /etc/sudoers.d/$($script:SY_USER) && echo 'sudo: done'"
    Write-Host "syauth done."
}

# ── Help ──────────────────────────────────────────────────────────────────────

# syh — show Synology NAS alias reference
function syh {
    Write-Host "Synology aliases  (host: $($script:SY_HOST)  user: $($script:SY_USER))"
    Write-Host ""
    Write-Host "  syp              — interactive SSH session"
    Write-Host "  syc  <cmd...>    — run command on NAS (stdin pipe → bash)"
    Write-Host ""
    Write-Host "  syw              — interactive SFTP session"
    Write-Host "  sywl  [dir]      — list remote directory (default: ~)"
    Write-Host "  sywg  <remote> [local]  — download file/dir (scp -r)"
    Write-Host "  sywu  <local> [remote]  — upload   file/dir (scp -r)"
    Write-Host "  sywmk <dir>      — mkdir on remote"
    Write-Host "  sywrm <path>     — rm on remote (confirms first)"
    Write-Host ""
    Write-Host "  syauth           — add pubkey to NAS authorized_keys"
}
