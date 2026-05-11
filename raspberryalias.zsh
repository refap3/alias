# Raspberry Pi SSH/SFTP aliases for zsh
# Converted from raspberryalias.dat (PuTTY/WinSCP → ssh/sftp)
#
# Key: ~/.ssh/id_rsa (standard SSH location, independent of dotfiles path)

DOTFILES="${DOTFILES:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/dotfiles}"
PI_KEY="$HOME/.ssh/id_rsa"

# Lab: skip host key checking — OS reinstalls change the host key frequently
_PIOPT=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

# Fix key permissions if present; set _PIKEYOPT for ssh/sftp/scp calls.
# When key is absent (e.g. on a Pi) _PIKEYOPT is empty → falls back to ssh-agent.
_pikey() {
    if [ -f "$PI_KEY" ]; then
        chmod 600 "$PI_KEY" 2>/dev/null
        _PIKEYOPT=(-i "$PI_KEY")
    else
        _PIKEYOPT=()
    fi
}

# --- Help ---
# Show Raspberry Pi alias reference (raspberryalias.zsh)
rah() { clear; echo "USE breevy ras for pw!"; echo "ra Put|Win [P] Vie|Aig"; echo "----------------------------"; cat "$DOTFILES/raspberryalias.zsh"; }

# --- SSH: pi user, by IP (last octet as argument) ---
# rap <octet>  — SSH to Pi by IP octet, using key
rap()   { _pikey; ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@192.168.1.$1; }   # rap  <octet>  — with key
# rapp <octet>  — SSH to Pi by IP octet, no key (password)
rapp()  { ssh "${_PIOPT[@]}" pi@192.168.1.$1; }                        # rapp <octet>  — without key
# Build the remote command string piped to bash -i via stdin.
# bash -i loads .bashrc (aliases/functions); expand_aliases is on by default in interactive mode.
# Stdin piping avoids all SSH quoting issues — no -c, no printf %q needed.
_ra_cmd() { printf 'shopt -s expand_aliases; %s' "$*"; }
# Run a command on one Pi (octet) or multiple Pis (comma-separated octets)
rac() {
    _pikey
    local _cmd; _cmd=$(_ra_cmd "${@:2}")
    case "$1" in
        *,*)
            local oct
            for oct in $(printf '%s' "$1" | tr ',' ' '); do
                printf '\n-- 192.168.1.%s --\n' "$oct"
                printf '%s\n' "$_cmd" | ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@192.168.1.$oct" bash -i 2>/dev/null
            done
            ;;
        *)
            printf '%s\n' "$_cmd" | ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@192.168.1.$1" bash -i 2>/dev/null
            ;;
    esac
}
# racv <host[,host,...]> <cmd...>  — run command on Pi by .ssb8.local hostname(s)
racv() {  # racv <host[,host,...]> <cmd...>
    _pikey
    local _cmd; _cmd=$(_ra_cmd "${@:2}")
    case "$1" in
        *,*)
            local h
            for h in $(printf '%s' "$1" | tr ',' ' '); do
                printf '\n-- %s --\n' "$h"
                printf '%s\n' "$_cmd" | ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@$h.ssb8.local" bash -i 2>/dev/null
            done
            ;;
        *)
            printf '%s\n' "$_cmd" | ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@$1.ssb8.local" bash -i 2>/dev/null
            ;;
    esac
}
# raca <host[,host,...]> <cmd...>  — run command on Pi by .pi.hole hostname(s)
raca() {  # raca <host[,host,...]> <cmd...>
    _pikey
    local _cmd; _cmd=$(_ra_cmd "${@:2}")
    case "$1" in
        *,*)
            local h
            for h in $(printf '%s' "$1" | tr ',' ' '); do
                printf '\n-- %s --\n' "$h"
                printf '%s\n' "$_cmd" | ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@$h.pi.hole" bash -i 2>/dev/null
            done
            ;;
        *)
            printf '%s\n' "$_cmd" | ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@$1.pi.hole" bash -i 2>/dev/null
            ;;
    esac
}

# --- SSH: Cloudflare tunnel (external access) ---
# rap59cv  — SSH to Pi .59 Vienna via Cloudflare tunnel
rap59cv()  { ssh pi@ssh59.deprec.uk; }     # rap59cv  — Pi .59 Vienna via Cloudflare tunnel
# rap168ca — SSH to Pi .168 Aigen via Cloudflare tunnel
rap168ca() { ssh pi@ssh168.cfaig2vie.uk; } # rap168ca — Pi .168 Aigen via Cloudflare tunnel
# raphacv  — SSH to Home Assistant Vienna via Cloudflare tunnel, port 22222
raphacv()  { ssh ssh32.deprec.uk; }    # raphacv  — HA Vienna via Cloudflare tunnel
# raphaca  — SSH to Home Assistant Aigen via Cloudflare tunnel, port 22222
raphaca()  { ssh ssh5.cfaig2vie.uk; }  # raphaca  — HA Aigen via Cloudflare tunnel

# --- VS Code Remote SSH: open VS Code on Mac connected to a Pi ---
# vscr <octet> [path]  — open VS Code remote SSH to Pi by IP octet
vscr()  { code --remote "ssh-remote+pi@192.168.1.$1" "${2:-/home/pi}"; }  # vscr  <octet> [path]
# vscrv <host> [path]  — open VS Code remote SSH to Pi by .ssb8.local hostname
vscrv() { code --remote "ssh-remote+pi@$1.ssb8.local" "${2:-/home/pi}"; } # vscrv <host>  [path]
# vscra <host> [path]  — open VS Code remote SSH to Pi by .pi.hole hostname
vscra() { code --remote "ssh-remote+pi@$1.pi.hole"    "${2:-/home/pi}"; } # vscra <host>  [path]

# --- SSH: pi user, by hostname ---
# rapv  <host>  — SSH to Pi by .ssb8.local hostname, using key
rapv()  { _pikey; ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@$1.ssb8.local; }  # rapv  <host>  — with key
# rappv <host>  — SSH to Pi by .ssb8.local hostname, no key (password)
rappv() { ssh "${_PIOPT[@]}" pi@$1.ssb8.local; }                        # rappv <host>  — without key
# rapa  <host>  — SSH to Pi by .pi.hole hostname, using key
rapa()  { _pikey; ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@$1.pi.hole; }     # rapa  <host>  — with key
# rappa <host>  — SSH to Pi by .pi.hole hostname, no key (password)
rappa() { ssh "${_PIOPT[@]}" pi@$1.pi.hole; }                           # rappa <host>  — without key

# --- SSH: root/hassio, port 22222 ---
# raphav  — SSH to Home Assistant at hassio.ssb8.local:22222 as root, using key
raphav() { _pikey; ssh -p 22222 "${_PIKEYOPT[@]}" "${_PIOPT[@]}" root@hassio.ssb8.local; }
# raphaa  — SSH to Home Assistant at hassio.pi.hole:22222 as root, using key
raphaa() { _pikey; ssh -p 22222 "${_PIKEYOPT[@]}" "${_PIOPT[@]}" root@hassio.pi.hole; }

# --- PC (Windows) configuration ---
PC_KEY="$HOME/.ssh/id_ed25519"
PC_USER="rainer"
PC_DOMAIN="ssb8"
_PCOPT=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

# Fix key permissions if present; set _PCKEYOPT for ssh calls.
_pckey() {
    if [ -f "$PC_KEY" ]; then
        chmod 600 "$PC_KEY" 2>/dev/null
        _PCKEYOPT=(-i "$PC_KEY")
    else
        _PCKEYOPT=()
    fi
}

# --- PCP: interactive PowerShell session over SSH (loads remote $profile.CurrentUserAllHosts) ---
# pcp  <octet>  — PowerShell SSH session to Windows PC by IP octet
pcp()  { _pckey; ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" -t "${PC_USER}@192.168.1.$1" 'pwsh -NoExit -Command ". $profile.CurrentUserAllHosts"'; }   # pcp  <octet>  — by IP
# pcpv <host>   — PowerShell SSH session to Windows PC by .ssb8.local hostname
pcpv() { _pckey; ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" -t "${PC_USER}@$1.ssb8.local" 'pwsh -NoExit -Command ". $profile.CurrentUserAllHosts"'; }  # pcpv <host>   — by .ssb8.local
# pcpa <host>   — PowerShell SSH session to Windows PC by .pi.hole hostname
pcpa() { _pckey; ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" -t "${PC_USER}@$1.pi.hole"    'pwsh -NoExit -Command ". $profile.CurrentUserAllHosts"'; }  # pcpa <host>   — by .pi.hole

# --- Remote command: run PowerShell command on Windows PC via SSH ---
# pcc <octet[,octet,...]> <cmd...>  — run PowerShell command on PC by IP octet(s)
pcc() {  # pcc <octet[,octet,...]> <cmd...>
    _pckey
    local _cmd="${@:2}"
    case "$1" in
        *,*)
            local oct
            for oct in $(printf '%s' "$1" | tr ',' ' '); do
                printf '\n-- 192.168.1.%s --\n' "$oct"
                printf '%s\n' "$_cmd" | ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@192.168.1.$oct" pwsh -NonInteractive -Command -
            done
            ;;
        *)
            printf '%s\n' "$_cmd" | ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@192.168.1.$1" pwsh -NonInteractive -Command -
            ;;
    esac
}
# pccv <host[,host,...]> <cmd...>  — run PowerShell command on PC by .ssb8.local hostname(s)
pccv() {  # pccv <host[,host,...]> <cmd...>
    _pckey
    local _cmd="${@:2}"
    case "$1" in
        *,*)
            local h
            for h in $(printf '%s' "$1" | tr ',' ' '); do
                printf '\n-- %s --\n' "$h"
                printf '%s\n' "$_cmd" | ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@$h.ssb8.local" pwsh -NonInteractive -Command -
            done
            ;;
        *)
            printf '%s\n' "$_cmd" | ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@$1.ssb8.local" pwsh -NonInteractive -Command -
            ;;
    esac
}
# pcca <host[,host,...]> <cmd...>  — run PowerShell command on PC by .pi.hole hostname(s)
pcca() {  # pcca <host[,host,...]> <cmd...>
    _pckey
    local _cmd="${@:2}"
    case "$1" in
        *,*)
            local h
            for h in $(printf '%s' "$1" | tr ',' ' '); do
                printf '\n-- %s --\n' "$h"
                printf '%s\n' "$_cmd" | ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@$h.pi.hole" pwsh -NonInteractive -Command -
            done
            ;;
        *)
            printf '%s\n' "$_cmd" | ssh "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@$1.pi.hole" pwsh -NonInteractive -Command -
            ;;
    esac
}

# --- SFTP: PC user (WinSCP equivalent) ---
# pcw <octet>  — interactive SFTP session to Windows PC by IP octet
pcw()   { _pckey; sftp "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@192.168.1.$1"; }  # pcw  <octet>  — with key
pcwv()  { _pckey; sftp "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@$1.ssb8.local"; } # pcwv <host>   — with key
pcwa()  { _pckey; sftp "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@$1.pi.hole"; }    # pcwa <host>   — with key

# SFTP one-liners: non-interactive file operations
_pcsftp() { printf '%s\n' "${@:2}" | sftp "${_PCKEYOPT[@]}" "${_PCOPT[@]}" -b - "$1"; }  # _pcsftp <host> <cmd...>

# list remote dir
pcwl()   { _pckey; _pcsftp "${PC_USER}@192.168.1.$1" "ls ${2:-.}"; }         # pcwl   <octet> [dir]
pcwlv()  { _pckey; _pcsftp "${PC_USER}@$1.ssb8.local" "ls ${2:-.}"; }        # pcwlv  <host>  [dir]
pcwla()  { _pckey; _pcsftp "${PC_USER}@$1.pi.hole"    "ls ${2:-.}"; }        # pcwla  <host>  [dir]

# get (download) — scp; use -r for dirs
pcwg()   { _pckey; scp -r "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@192.168.1.$1:$2" "${3:-.}"; }   # pcwg   <octet> <remote> [local]
pcwgv()  { _pckey; scp -r "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@$1.ssb8.local:$2" "${3:-.}"; }  # pcwgv  <host>  <remote> [local]
pcwga()  { _pckey; scp -r "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "${PC_USER}@$1.pi.hole:$2"    "${3:-.}"; }  # pcwga  <host>  <remote> [local]

# put (upload) — scp; use -r for dirs
pcwu()   { _pckey; scp -r "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "$2" "${PC_USER}@192.168.1.$1:${3:-.}"; }   # pcwu   <octet> <local> [remote]
pcwuv()  { _pckey; scp -r "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "$2" "${PC_USER}@$1.ssb8.local:${3:-.}"; }  # pcwuv  <host>  <local> [remote]
pcwua()  { _pckey; scp -r "${_PCKEYOPT[@]}" "${_PCOPT[@]}" "$2" "${PC_USER}@$1.pi.hole:${3:-.}"; }     # pcwua  <host>  <local> [remote]

# mkdir on remote
pcwmk()  { _pckey; _pcsftp "${PC_USER}@192.168.1.$1" "mkdir $2"; }           # pcwmk  <octet> <dir>
pcwmkv() { _pckey; _pcsftp "${PC_USER}@$1.ssb8.local" "mkdir $2"; }          # pcwmkv <host>  <dir>
pcwmka() { _pckey; _pcsftp "${PC_USER}@$1.pi.hole"    "mkdir $2"; }          # pcwmka <host>  <dir>

# rm on remote (with confirmation)
pcwrm()  { _pckey; printf 'rm %s? [y/N] ' "$2"; read -rq && _pcsftp "${PC_USER}@192.168.1.$1" "rm $2"; }  # pcwrm  <octet> <path>
pcwrmv() { _pckey; printf 'rm %s? [y/N] ' "$2"; read -rq && _pcsftp "${PC_USER}@$1.ssb8.local" "rm $2"; } # pcwrmv <host>  <path>
pcwrma() { _pckey; printf 'rm %s? [y/N] ' "$2"; read -rq && _pcsftp "${PC_USER}@$1.pi.hole"    "rm $2"; } # pcwrma <host>  <path>

# pcwh  — show SFTP one-liner reference for Windows PC (pcw* variants)
pcwh() {
  echo "SFTP one-liners  (pcw* = SFTP/SCP, variants: plain=IP octet, v=.ssb8.local, a=.pi.hole)"
  echo "  pcwl [v|a]  <host>  [dir]            — list remote directory (default: ~)"
  echo "  pcwg [v|a]  <host>  <remote> [local] — download file/dir (scp -r; default local: .)"
  echo "  pcwu [v|a]  <host>  <local> [remote] — upload   file/dir (scp -r; default remote: ~)"
  echo "  pcwmk[v|a] <host>  <dir>             — mkdir on remote"
  echo "  pcwrm[v|a] <host>  <path>            — rm on remote (confirms first)"
  echo "  pcw [v|a]  <host>                    — interactive SFTP session"
  echo "  Note: no cd — use full remote paths"
}

# --- Copy SSH keys to remote host (password auth — use before key auth is set up) ---
# racpub <octet>  — copy Mac public key file to Pi
racpub()  { scp "${_PIOPT[@]}" ~/.ssh/id_rsa.pub pi@192.168.1.$1:~/.ssh/; }                                              # racpub <octet>  — copy public key file
# racpri <octet>  — copy Mac private key to Pi + fix permissions
racpri()  { ssh "${_PIOPT[@]}" pi@192.168.1.$1 "mkdir -p ~/.ssh && chmod 700 ~/.ssh" && scp "${_PIOPT[@]}" ~/.ssh/id_rsa pi@192.168.1.$1:~/.ssh/ && ssh "${_PIOPT[@]}" pi@192.168.1.$1 "chmod 600 ~/.ssh/id_rsa"; } # racpri <octet>  — copy private key + fix perms
# raauth <octet>  — add Mac pubkey + write MAC_USER to Pi .bashrc (one password prompt)
raauth()  { local _u; _u=$(whoami); cat ~/.ssh/id_rsa.pub | ssh "${_PIOPT[@]}" pi@192.168.1.$1 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && grep -q 'export MAC_USER=' ~/.bashrc || echo 'export MAC_USER=$_u' >> ~/.bashrc"; echo "raauth done: key added, MAC_USER=$_u written to Pi .bashrc"; }  # raauth <octet>  — add Mac pubkey + write MAC_USER (single SSH = one password prompt)

# --- SFTP: pi user (WinSCP equivalent) ---
# raw  <octet>  — interactive SFTP session to Pi by IP octet
raw()   { _pikey; sftp "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@192.168.1.$1; }  # raw  <octet>  — with key
# rawv  <host>  — interactive SFTP session to Pi by .ssb8.local hostname
rawv()  { _pikey; sftp "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@$1.ssb8.local; } # rawv  <host>  — with key
# rawa  <host>  — interactive SFTP session to Pi by .pi.hole hostname
rawa()  { _pikey; sftp "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@$1.pi.hole; }    # rawa  <host>  — with key
rawpv() { sftp "${_PIOPT[@]}" pi@$1.ssb8.local; }              # rawpv <host>  — without key
rawpa() { sftp "${_PIOPT[@]}" pi@$1.pi.hole; }                 # rawpa <host>  — without key

# --- SFTP one-liners: non-interactive file operations (on top of raw/rawv/rawa) ---
# Tools: scp for get/put (simpler), sftp -b for ls/mkdir/rm
# Address variants: <octet>=192.168.1.x  v=.ssb8.local  a=.pi.hole
_rasftp() { printf '%s\n' "${@:2}" | sftp "${_PIKEYOPT[@]}" "${_PIOPT[@]}" -b - "$1"; }  # _rasftp <host> <cmd...>

# list remote dir
rawl()   { _pikey; _rasftp "pi@192.168.1.$1" "ls ${2:-.}"; }         # rawl   <octet> [dir]
rawlv()  { _pikey; _rasftp "pi@$1.ssb8.local" "ls ${2:-.}"; }        # rawlv  <host>  [dir]
rawla()  { _pikey; _rasftp "pi@$1.pi.hole"    "ls ${2:-.}"; }        # rawla  <host>  [dir]

# get (download) — scp; use -r for dirs
rawg()   { _pikey; scp -r "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@192.168.1.$1:$2" "${3:-.}"; }   # rawg   <octet> <remote> [local]
rawgv()  { _pikey; scp -r "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@$1.ssb8.local:$2" "${3:-.}"; }  # rawgv  <host>  <remote> [local]
rawga()  { _pikey; scp -r "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@$1.pi.hole:$2"    "${3:-.}"; }  # rawga  <host>  <remote> [local]

# put (upload) — scp; use -r for dirs
rawu()   { _pikey; scp -r "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "$2" "pi@192.168.1.$1:${3:-.}"; }   # rawu   <octet> <local> [remote]
rawuv()  { _pikey; scp -r "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "$2" "pi@$1.ssb8.local:${3:-.}"; }  # rawuv  <host>  <local> [remote]
rawua()  { _pikey; scp -r "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "$2" "pi@$1.pi.hole:${3:-.}"; }     # rawua  <host>  <local> [remote]

# mkdir on remote
rawmk()  { _pikey; _rasftp "pi@192.168.1.$1" "mkdir $2"; }           # rawmk  <octet> <dir>
rawmkv() { _pikey; _rasftp "pi@$1.ssb8.local" "mkdir $2"; }          # rawmkv <host>  <dir>
rawmka() { _pikey; _rasftp "pi@$1.pi.hole"    "mkdir $2"; }          # rawmka <host>  <dir>

# rm on remote (with confirmation)
rawrm()  { _pikey; echo "rm $2? [y/N] "; read -rq && _rasftp "pi@192.168.1.$1" "rm $2"; }  # rawrm  <octet> <path>
rawrmv() { _pikey; echo "rm $2? [y/N] "; read -rq && _rasftp "pi@$1.ssb8.local" "rm $2"; } # rawrmv <host>  <path>
rawrma() { _pikey; echo "rm $2? [y/N] "; read -rq && _rasftp "pi@$1.pi.hole"    "rm $2"; } # rawrma <host>  <path>

# rawh  — show SFTP one-liner reference for Pi (raw* variants)
rawh() {
  echo "SFTP one-liners  (raw* = SFTP/SCP, variants: plain=IP octet, v=.ssb8.local, a=.pi.hole)"
  echo "  rawl [v|a]  <host>  [dir]            — list remote directory (default: ~)"
  echo "  rawg [v|a]  <host>  <remote> [local] — download file/dir (scp -r; default local: .)"
  echo "  rawu [v|a]  <host>  <local> [remote] — upload   file/dir (scp -r; default remote: ~)"
  echo "  rawmk[v|a] <host>  <dir>             — mkdir on remote"
  echo "  rawrm[v|a] <host>  <path>            — rm on remote (confirms first)"
  echo "  raw [v|a]  <host>                    — interactive SFTP session (supports cd)"
  echo "  Note: no cd — use full remote paths, e.g. rawl 42 /home/pi/mydir"
}
