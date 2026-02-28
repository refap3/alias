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
rah() { clear; echo "USE breevy ras for pw!"; echo "ra Put|Win [P] Vie|Aig"; echo "----------------------------"; cat "$DOTFILES/raspberryalias.zsh"; }

# --- SSH: pi user, by IP (last octet as argument) ---
rap()   { _pikey; ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@192.168.1.$1; }   # rap  <octet>  — with key
rapp()  { ssh "${_PIOPT[@]}" pi@192.168.1.$1; }                        # rapp <octet>  — without key
# Build a remote bash -i -c string: enables alias expansion and loads ~/.bash_aliases.
# Uses bash -i so .bashrc (and its aliases) is auto-loaded; TTY warnings are filtered by the caller.
_ra_cmd() { printf 'shopt -s expand_aliases; [ -f ~/.bash_aliases ] && . ~/.bash_aliases 2>/dev/null; %s' "$*"; }
# Run a command on one Pi (octet) or multiple Pis (comma-separated octets)
rac() {
    _pikey
    local _cmd; _cmd=$(_ra_cmd "${@:2}")
    case "$1" in
        *,*)
            local oct
            for oct in $(printf '%s' "$1" | tr ',' ' '); do
                printf '\n-- 192.168.1.%s --\n' "$oct"
                ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@192.168.1.$oct" "bash -i -c $(printf '%q' "$_cmd")" 2> >(grep -Ev '^bash: (cannot set terminal|no job control|warning: setlocale)' >&2)
            done
            ;;
        *)
            ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@192.168.1.$1" "bash -i -c $(printf '%q' "$_cmd")" 2> >(grep -Ev '^bash: (cannot set terminal|no job control|warning: setlocale)' >&2)
            ;;
    esac
}
racv() { _pikey; local _cmd; _cmd=$(_ra_cmd "${@:2}"); ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@$1.ssb8.local" "bash -i -c $(printf '%q' "$_cmd")" 2> >(grep -Ev '^bash: (cannot set terminal|no job control|warning: setlocale)' >&2); }  # racv <host> <cmd...>
raca() { _pikey; local _cmd; _cmd=$(_ra_cmd "${@:2}"); ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" "pi@$1.pi.hole"    "bash -i -c $(printf '%q' "$_cmd")" 2> >(grep -Ev '^bash: (cannot set terminal|no job control|warning: setlocale)' >&2); }  # raca <host> <cmd...>

# --- SSH: pi user, by hostname ---
rapv()  { _pikey; ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@$1.ssb8.local; }  # rapv  <host>  — with key
rappv() { ssh "${_PIOPT[@]}" pi@$1.ssb8.local; }                        # rappv <host>  — without key
rapa()  { _pikey; ssh "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@$1.pi.hole; }     # rapa  <host>  — with key
rappa() { ssh "${_PIOPT[@]}" pi@$1.pi.hole; }                           # rappa <host>  — without key

# --- SSH: root/hassio, port 22222 ---
raphav() { _pikey; ssh -p 22222 "${_PIKEYOPT[@]}" "${_PIOPT[@]}" root@hassio.ssb8.local; }
raphaa() { _pikey; ssh -p 22222 "${_PIKEYOPT[@]}" "${_PIOPT[@]}" root@hassio.pi.hole; }

# --- Copy SSH keys to remote host (password auth — use before key auth is set up) ---
racpub()  { scp "${_PIOPT[@]}" ~/.ssh/id_rsa.pub pi@192.168.1.$1:~/.ssh/; }                                              # racpub <octet>  — copy public key file
racpri()  { ssh "${_PIOPT[@]}" pi@192.168.1.$1 "mkdir -p ~/.ssh && chmod 700 ~/.ssh" && scp "${_PIOPT[@]}" ~/.ssh/id_rsa pi@192.168.1.$1:~/.ssh/ && ssh "${_PIOPT[@]}" pi@192.168.1.$1 "chmod 600 ~/.ssh/id_rsa"; } # racpri <octet>  — copy private key + fix perms
raauth()  { cat ~/.ssh/id_rsa.pub | ssh "${_PIOPT[@]}" pi@192.168.1.$1 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"; }  # raauth <octet>  — add Mac pubkey to authorized_keys

# --- SFTP: pi user (WinSCP equivalent) ---
raw()   { _pikey; sftp "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@192.168.1.$1; }  # raw  <octet>  — with key
rawv()  { _pikey; sftp "${_PIKEYOPT[@]}" "${_PIOPT[@]}" pi@$1.ssb8.local; } # rawv  <host>  — with key
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

# help
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
