# raspberryalias.ps1 — PowerShell equivalents of raspberryalias.zsh
# Requires OpenSSH (standard on Windows 10 1809+ and macOS).
# Source from $PROFILE via deploy.ps1.

$script:PI_KEY  = Join-Path $HOME ".ssh/id_rsa"
$script:PC_KEY  = Join-Path $HOME ".ssh/id_ed25519"
$script:PC_USER = "rainer"
$script:PI_SSHOPT = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-o", "LogLevel=ERROR")

# _PiKeyOpt — return SSH key args array for Pi key (helper)
function _PiKeyOpt {
    if (Test-Path $script:PI_KEY) { @("-i", $script:PI_KEY) } else { @() }
}

# _PcKeyOpt — return SSH key args array for PC key (helper)
function _PcKeyOpt {
    if (Test-Path $script:PC_KEY) { @("-i", $script:PC_KEY) } else { @() }
}

# _RaCmd <cmd...> — build remote bash command string (helper)
function _RaCmd {
    "shopt -s expand_aliases; $($args -join ' ')"
}

# _PiSsh <target> <cmd> — pipe cmd to remote bash -i (helper)
function _PiSsh {
    param([string]$Target, [string]$Cmd)
    $Cmd | ssh @(_PiKeyOpt) @($script:PI_SSHOPT) $Target bash -i 2>$null
}

# ── Raspberry Pi SSH ──────────────────────────────────────────────────────────

# rap <octet> — SSH to Pi by IP, with key
function rap   { param([string]$Oct) ssh @(_PiKeyOpt) @($script:PI_SSHOPT) "pi@192.168.1.$Oct" }
# rapp <octet> — SSH to Pi by IP, password (no key)
function rapp  { param([string]$Oct) ssh @($script:PI_SSHOPT) "pi@192.168.1.$Oct" }
# rapv <host> — SSH to Pi by .ssb8.local hostname, with key
function rapv  { param([string]$H) ssh @(_PiKeyOpt) @($script:PI_SSHOPT) "pi@$H.ssb8.local" }
# rapa <host> — SSH to Pi by .pi.hole hostname, with key
function rapa  { param([string]$H) ssh @(_PiKeyOpt) @($script:PI_SSHOPT) "pi@$H.pi.hole" }

# ── Raspberry Pi remote command execution ─────────────────────────────────────

# rac <octet[,octet,...]> <cmd...> — run command on Pi(s) by IP octet
function rac {
    param([string]$Hosts, [Parameter(ValueFromRemainingArguments)][string[]]$Cmd)
    $cmd = _RaCmd @Cmd
    foreach ($oct in ($Hosts -split ',')) {
        if ($Hosts -match ',') { Write-Host "`n-- 192.168.1.$oct --" }
        _PiSsh "pi@192.168.1.$oct" $cmd
    }
}

# racv <host[,host,...]> <cmd...> — run command on Pi(s) by .ssb8.local hostname
function racv {
    param([string]$Hosts, [Parameter(ValueFromRemainingArguments)][string[]]$Cmd)
    $cmd = _RaCmd @Cmd
    foreach ($h in ($Hosts -split ',')) {
        if ($Hosts -match ',') { Write-Host "`n-- $h --" }
        _PiSsh "pi@$h.ssb8.local" $cmd
    }
}

# raca <host[,host,...]> <cmd...> — run command on Pi(s) by .pi.hole hostname
function raca {
    param([string]$Hosts, [Parameter(ValueFromRemainingArguments)][string[]]$Cmd)
    $cmd = _RaCmd @Cmd
    foreach ($h in ($Hosts -split ',')) {
        if ($Hosts -match ',') { Write-Host "`n-- $h --" }
        _PiSsh "pi@$h.pi.hole" $cmd
    }
}

# ── Raspberry Pi Cloudflare tunnel ────────────────────────────────────────────

# rap59cv — SSH to Pi .59 Vienna via Cloudflare tunnel
function rap59cv  { ssh pi@ssh59.deprec.uk }
# rap168ca — SSH to Pi .168 Aigen via Cloudflare tunnel
function rap168ca { ssh pi@ssh168.cfaig2vie.uk }
# raphacv — SSH to HA Vienna via Cloudflare tunnel
function raphacv  { ssh ssh32.deprec.uk }
# raphaca — SSH to HA Aigen via Cloudflare tunnel
function raphaca  { ssh ssh5.cfaig2vie.uk }

# ── Raspberry Pi VS Code Remote SSH ──────────────────────────────────────────

# vscr <octet> [path] — VS Code remote SSH to Pi by IP octet
function vscr  { param([string]$Oct, [string]$Path = "/home/pi") code --remote "ssh-remote+pi@192.168.1.$Oct" $Path }
# vscrv <host> [path] — VS Code remote SSH to Pi by .ssb8.local
function vscrv { param([string]$H, [string]$Path = "/home/pi") code --remote "ssh-remote+pi@$H.ssb8.local" $Path }
# vscra <host> [path] — VS Code remote SSH to Pi by .pi.hole
function vscra { param([string]$H, [string]$Path = "/home/pi") code --remote "ssh-remote+pi@$H.pi.hole" $Path }

# ── Raspberry Pi SFTP ─────────────────────────────────────────────────────────

function _PiSftp {
    param([string]$Target, [string[]]$Cmds)
    $Cmds | sftp @(_PiKeyOpt) @($script:PI_SSHOPT) -b - $Target
}

# raw <octet> — interactive SFTP to Pi by IP
function raw  { param([string]$Oct) sftp @(_PiKeyOpt) @($script:PI_SSHOPT) "pi@192.168.1.$Oct" }
# rawv <host> — interactive SFTP to Pi by .ssb8.local
function rawv { param([string]$H) sftp @(_PiKeyOpt) @($script:PI_SSHOPT) "pi@$H.ssb8.local" }
# rawa <host> — interactive SFTP to Pi by .pi.hole
function rawa { param([string]$H) sftp @(_PiKeyOpt) @($script:PI_SSHOPT) "pi@$H.pi.hole" }

# rawl <octet> [dir] — list remote dir on Pi by IP
function rawl  { param([string]$Oct, [string]$Dir = ".") _PiSftp "pi@192.168.1.$Oct" @("ls $Dir") }
# rawlv <host> [dir] — list remote dir on Pi by .ssb8.local
function rawlv { param([string]$H, [string]$Dir = ".") _PiSftp "pi@$H.ssb8.local" @("ls $Dir") }
# rawg <octet> <remote> [local] — download file/dir from Pi by IP
function rawg  { param([string]$Oct, [string]$Remote, [string]$Local = ".") scp -r @(_PiKeyOpt) @($script:PI_SSHOPT) "pi@192.168.1.$Oct`:$Remote" $Local }
# rawgv <host> <remote> [local] — download file/dir from Pi by .ssb8.local
function rawgv { param([string]$H, [string]$Remote, [string]$Local = ".") scp -r @(_PiKeyOpt) @($script:PI_SSHOPT) "pi@$H.ssb8.local`:$Remote" $Local }
# rawu <octet> <local> [remote] — upload file/dir to Pi by IP
function rawu  { param([string]$Oct, [string]$Local, [string]$Remote = "~") scp -r @(_PiKeyOpt) @($script:PI_SSHOPT) $Local "pi@192.168.1.$Oct`:$Remote" }
# rawuv <host> <local> [remote] — upload file/dir to Pi by .ssb8.local
function rawuv { param([string]$H, [string]$Local, [string]$Remote = "~") scp -r @(_PiKeyOpt) @($script:PI_SSHOPT) $Local "pi@$H.ssb8.local`:$Remote" }
# rawmk <octet> <dir> — mkdir on Pi by IP
function rawmk  { param([string]$Oct, [string]$Dir) _PiSftp "pi@192.168.1.$Oct" @("mkdir $Dir") }
# rawmkv <host> <dir> — mkdir on Pi by .ssb8.local
function rawmkv { param([string]$H, [string]$Dir) _PiSftp "pi@$H.ssb8.local" @("mkdir $Dir") }
# rawrm <octet> <path> — rm on Pi by IP (confirms first)
function rawrm {
    param([string]$Oct, [string]$Path)
    $ans = Read-Host "rm $Path on 192.168.1.$Oct? [y/N]"
    if ($ans -match '^[yY]') { _PiSftp "pi@192.168.1.$Oct" @("rm $Path") }
}
# rawrmv <host> <path> — rm on Pi by .ssb8.local (confirms first)
function rawrmv {
    param([string]$H, [string]$Path)
    $ans = Read-Host "rm $Path on $H.ssb8.local? [y/N]"
    if ($ans -match '^[yY]') { _PiSftp "pi@$H.ssb8.local" @("rm $Path") }
}

# ── Windows PC SSH ────────────────────────────────────────────────────────────

# pcp <octet> — PowerShell SSH session to Windows PC by IP, loading profile
function pcp  { param([string]$Oct) ssh @(_PcKeyOpt) @($script:PI_SSHOPT) -t "$($script:PC_USER)@192.168.1.$Oct" 'pwsh -NoExit -Command ". $profile.CurrentUserAllHosts"' }
# pcpv <host> — PowerShell SSH session to PC by .ssb8.local
function pcpv { param([string]$H)   ssh @(_PcKeyOpt) @($script:PI_SSHOPT) -t "$($script:PC_USER)@$H.ssb8.local" 'pwsh -NoExit -Command ". $profile.CurrentUserAllHosts"' }
# pcp203cv — PowerShell SSH session to PC .203 Vienna via Cloudflare tunnel
function pcp203cv { ssh @(_PcKeyOpt) @($script:PI_SSHOPT) -t "$($script:PC_USER)@ssh203.deprec.uk" 'pwsh -NoExit -Command ". $profile.CurrentUserAllHosts"' }
# pcs203cv — plain SSH session to PC .203 Vienna via Cloudflare tunnel
function pcs203cv { ssh @(_PcKeyOpt) @($script:PI_SSHOPT) "$($script:PC_USER)@ssh203.deprec.uk" }

# ── Windows PC remote command execution ──────────────────────────────────────

function _PcSsh {
    param([string]$Target, [string]$Cmd)
    $Cmd | ssh @(_PcKeyOpt) @($script:PI_SSHOPT) $Target pwsh -NonInteractive -Command -
}

# pcc <octet[,octet,...]> <cmd...> — run PS command on PC(s) by IP octet
function pcc {
    param([string]$Hosts, [Parameter(ValueFromRemainingArguments)][string[]]$Cmd)
    $cmd = $Cmd -join ' '
    foreach ($oct in ($Hosts -split ',')) {
        if ($Hosts -match ',') { Write-Host "`n-- 192.168.1.$oct --" }
        _PcSsh "$($script:PC_USER)@192.168.1.$oct" $cmd
    }
}

# pccv <host[,host,...]> <cmd...> — run PS command on PC(s) by .ssb8.local
function pccv {
    param([string]$Hosts, [Parameter(ValueFromRemainingArguments)][string[]]$Cmd)
    $cmd = $Cmd -join ' '
    foreach ($h in ($Hosts -split ',')) {
        if ($Hosts -match ',') { Write-Host "`n-- $h --" }
        _PcSsh "$($script:PC_USER)@$h.ssb8.local" $cmd
    }
}

# pcc203cv <cmd...> — run PS command on PC .203 via Cloudflare tunnel
function pcc203cv {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Cmd)
    ($Cmd -join ' ') | ssh @(_PcKeyOpt) @($script:PI_SSHOPT) "$($script:PC_USER)@ssh203.deprec.uk" pwsh -NonInteractive -Command -
}

# ── Windows PC SFTP ───────────────────────────────────────────────────────────

function _PcSftp {
    param([string]$Target, [string[]]$Cmds)
    $Cmds | sftp @(_PcKeyOpt) @($script:PI_SSHOPT) -b - $Target
}

# pcw <octet> — interactive SFTP to PC by IP
function pcw  { param([string]$Oct) sftp @(_PcKeyOpt) @($script:PI_SSHOPT) "$($script:PC_USER)@192.168.1.$Oct" }
# pcwv <host> — interactive SFTP to PC by .ssb8.local
function pcwv { param([string]$H) sftp @(_PcKeyOpt) @($script:PI_SSHOPT) "$($script:PC_USER)@$H.ssb8.local" }
# pcwl <octet> [dir] — list remote dir on PC by IP
function pcwl  { param([string]$Oct, [string]$Dir = ".") _PcSftp "$($script:PC_USER)@192.168.1.$Oct" @("ls $Dir") }
# pcwlv <host> [dir] — list remote dir on PC by .ssb8.local
function pcwlv { param([string]$H, [string]$Dir = ".") _PcSftp "$($script:PC_USER)@$H.ssb8.local" @("ls $Dir") }
# pcwg <octet> <remote> [local] — download file/dir from PC by IP
function pcwg  { param([string]$Oct, [string]$Remote, [string]$Local = ".") scp -r @(_PcKeyOpt) @($script:PI_SSHOPT) "$($script:PC_USER)@192.168.1.$Oct`:$Remote" $Local }
# pcwgv <host> <remote> [local] — download file/dir from PC by .ssb8.local
function pcwgv { param([string]$H, [string]$Remote, [string]$Local = ".") scp -r @(_PcKeyOpt) @($script:PI_SSHOPT) "$($script:PC_USER)@$H.ssb8.local`:$Remote" $Local }
# pcwu <octet> <local> [remote] — upload file/dir to PC by IP
function pcwu  { param([string]$Oct, [string]$Local, [string]$Remote = "~") scp -r @(_PcKeyOpt) @($script:PI_SSHOPT) $Local "$($script:PC_USER)@192.168.1.$Oct`:$Remote" }
# pcwuv <host> <local> [remote] — upload file/dir to PC by .ssb8.local
function pcwuv { param([string]$H, [string]$Local, [string]$Remote = "~") scp -r @(_PcKeyOpt) @($script:PI_SSHOPT) $Local "$($script:PC_USER)@$H.ssb8.local`:$Remote" }
# pcwmk <octet> <dir> — mkdir on PC by IP
function pcwmk  { param([string]$Oct, [string]$Dir) _PcSftp "$($script:PC_USER)@192.168.1.$Oct" @("mkdir $Dir") }
# pcwmkv <host> <dir> — mkdir on PC by .ssb8.local
function pcwmkv { param([string]$H, [string]$Dir) _PcSftp "$($script:PC_USER)@$H.ssb8.local" @("mkdir $Dir") }
# pcwrm <octet> <path> — rm on PC by IP (confirms first)
function pcwrm {
    param([string]$Oct, [string]$Path)
    $ans = Read-Host "rm $Path on 192.168.1.$Oct? [y/N]"
    if ($ans -match '^[yY]') { _PcSftp "$($script:PC_USER)@192.168.1.$Oct" @("rm $Path") }
}
# pcwrmv <host> <path> — rm on PC by .ssb8.local (confirms first)
function pcwrmv {
    param([string]$H, [string]$Path)
    $ans = Read-Host "rm $Path on $H.ssb8.local? [y/N]"
    if ($ans -match '^[yY]') { _PcSftp "$($script:PC_USER)@$H.ssb8.local" @("rm $Path") }
}

# ── Help ──────────────────────────────────────────────────────────────────────

# rah — show Raspberry Pi alias reference
function rah {
    Write-Host "Pi SSH:   rap/rapv/rapa <host>   — interactive SSH (IP/ssb8/pi.hole)"
    Write-Host "Pi cmd:   rac/racv/raca <host> <cmd>  — run command on Pi(s)"
    Write-Host "Pi SFTP:  raw/rawv <host>        — interactive; rawl/rawg/rawu/rawmk/rawrm"
    Write-Host "PC SSH:   pcp/pcpv <host>        — PowerShell SSH session"
    Write-Host "PC cmd:   pcc/pccv <host> <cmd>  — run PS command; pcc203cv for tunnel"
    Write-Host "PC SFTP:  pcw/pcwv <host>        — interactive; pcwl/pcwg/pcwu/pcwmk/pcwrm"
    Write-Host "Tunnel:   rap59cv / raphacv / pcs203cv / pcp203cv / pcc203cv"
}
