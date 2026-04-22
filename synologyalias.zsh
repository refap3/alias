# Synology NAS SSH/SFTP aliases for zsh
#
# Host: 192.168.1.116  User: pipi  Port: 22
# Key: ~/.ssh/id_rsa

SY_HOST="192.168.1.116"
SY_USER="pipi"
PI_KEY="$HOME/.ssh/id_rsa"

_SYOPT=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)

_sykey() {
    if [ -f "$PI_KEY" ]; then
        chmod 600 "$PI_KEY" 2>/dev/null
        _SYKEYOPT=(-i "$PI_KEY")
    else
        _SYKEYOPT=()
    fi
}

# --- Help ---
# syh  — show Synology NAS alias reference
syh() {
    echo "Synology aliases  (host: $SY_HOST  user: $SY_USER)"
    echo ""
    echo "  syp              — interactive SSH session"
    echo "  syc  <cmd...>    — run command on NAS (stdin pipe → bash)"
    echo ""
    echo "  syw              — interactive SFTP session"
    echo "  sywl  [dir]      — list remote directory (default: ~)"
    echo "  sywg  <remote> [local]  — download file/dir (scp -r)"
    echo "  sywu  <local> [remote]  — upload   file/dir (scp -r)"
    echo "  sywmk <dir>      — mkdir on remote"
    echo "  sywrm <path>     — rm on remote (confirms first)"
    echo ""
    echo "  syauth           — add Mac pubkey to NAS authorized_keys (password prompt)"
    echo ""
    echo "  Note: VS Code Remote SSH not supported (NAS glibc 2.26 < required 2.28)"
}

# --- SSH ---
# syp  — interactive SSH session to NAS, using key
syp()  { _sykey; ssh "${_SYKEYOPT[@]}" "${_SYOPT[@]}" "$SY_USER@$SY_HOST"; }
# sypp — interactive SSH session to NAS, no key (password)
sypp() { ssh "${_SYOPT[@]}" "$SY_USER@$SY_HOST"; }   # without key (password)

# Run a command on the NAS via stdin → bash (avoids SSH quoting issues)
syc() {
    _sykey
    local _cmd; _cmd=$(printf 'shopt -s expand_aliases; %s' "$*")
    printf '%s\n' "$_cmd" | ssh "${_SYKEYOPT[@]}" "${_SYOPT[@]}" "$SY_USER@$SY_HOST" bash -i 2>/dev/null
}

# --- Key setup (password auth — run before key auth is set up) ---
# syauth  — add Mac pubkey to NAS + configure passwordless sudo (password prompt)
syauth() {
    local _u; _u=$(whoami)
    echo "Step 1/2: adding Mac pubkey (SSH password prompt)..."
    cat ~/.ssh/id_rsa.pub | ssh "${_SYOPT[@]}" "$SY_USER@$SY_HOST" \
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    echo "Step 2/2: setting up passwordless sudo (sudo password prompt)..."
    ssh "${_SYKEYOPT[@]}" "${_SYOPT[@]}" -t "$SY_USER@$SY_HOST" \
        "echo '$SY_USER ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/$SY_USER > /dev/null && sudo chmod 0440 /etc/sudoers.d/$SY_USER && echo 'sudo: done'"
    echo "syauth done: pubkey added, passwordless sudo configured."
}

# --- SFTP ---
# syw  — interactive SFTP session to NAS
syw() { _sykey; sftp "${_SYKEYOPT[@]}" "${_SYOPT[@]}" "$SY_USER@$SY_HOST"; }

_sysftp() { printf '%s\n' "${@}" | sftp "${_SYKEYOPT[@]}" "${_SYOPT[@]}" -b - "$SY_USER@$SY_HOST"; }

sywl()  { _sykey; _sysftp "ls ${1:-.}"; }                                                              # sywl  [dir]
sywg()  { _sykey; scp -r "${_SYKEYOPT[@]}" "${_SYOPT[@]}" "$SY_USER@$SY_HOST:$1" "${2:-.}"; }         # sywg  <remote> [local]
sywu()  { _sykey; scp -r "${_SYKEYOPT[@]}" "${_SYOPT[@]}" "$1" "$SY_USER@$SY_HOST:${2:-.}"; }         # sywu  <local>  [remote]
sywmk() { _sykey; _sysftp "mkdir $1"; }                                                                # sywmk <dir>
sywrm() { _sykey; printf 'rm %s? [y/N] ' "$1"; read -r _reply; [[ "$_reply" == [yY] ]] && _sysftp "rm $1"; }  # sywrm <path>
