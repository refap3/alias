# alias

Portable shell configuration for zsh and bash — aliases, git shortcuts, Raspberry Pi helpers, and a directory jump function.

## Install (one line)

```bash
curl -fsSL https://raw.githubusercontent.com/refap3/alias/master/install.sh | bash
```

Clones a shallow copy (no history) into `~/alias` and runs `deploy.sh`.

## Update

```bash
alu
```

Pulls the latest changes and re-runs `deploy.sh`. The `alu` alias is available once the repo is deployed. Or manually:

```bash
git -C ~/alias pull && bash ~/alias/deploy.sh
```

## Test a clean install

Wipe the repo and deployed dotfiles, then re-run the installer:

```bash
cd ~
rm -rf ~/alias ~/.zshrc ~/.bashrc
curl -fsSL https://raw.githubusercontent.com/refap3/alias/master/install.sh | bash
```

## Quick start (manual)

```bash
git clone https://github.com/refap3/alias ~/alias
cd ~/alias
./deploy.sh
```

`deploy.sh` auto-detects your shell and symlinks dotfiles directly under `~/`. Open a new shell (or `source ~/.zshrc`) to activate.

## Deploy options

```bash
./deploy.sh [--shell zsh|bash] [--home | --path <dir>]
```

| Option | Description |
|--------|-------------|
| `--shell zsh\|bash` | Shell to configure (auto-detected if omitted) |
| `--home` | Symlink rc file and helpers directly under `~/` (default) |
| `--path <dir>` | Create `<dir>`, symlink all dotfiles into it, then link rc from `~/` |

**Examples:**

```bash
# Auto-detect shell, symlink from ~/
./deploy.sh

# Explicit zsh, symlink from ~/
./deploy.sh --shell zsh --home

# Bash with a named dotfiles folder
./deploy.sh --shell bash --path ~/dotfiles
```

Existing regular files (e.g. `~/.zshrc`) are backed up with a timestamp before being replaced.

## First-time setup on a new machine

```bash
sudo apt install git -y          # Debian/Ubuntu — skip on macOS
git clone https://github.com/refap3/alias ~/alias
~/alias/deploy.sh
source ~/.zshrc     # or source ~/.bashrc
```

## Files

| File | Purpose |
|------|---------|
| `.zshrc` | zsh config — sets `DOTFILES`, loads alias files, defines `j` jump function |
| `.bashrc` | bash config — sets `DOTFILES` via `readlink`, loads alias files |
| `alias.zsh` | General aliases (`up`, `home`, `cls`, `dt`, `aalias`, `ddd`, etc.) |
| `gitalias.zsh` | Git shortcuts (auto-loaded at login, unload with `sl`) |
| `raspberryalias.zsh` | SSH/SFTP aliases for Raspberry Pi hosts |
| `synologyalias.zsh` | SSH/SFTP aliases for Synology NAS (fixed host, user pipi) |
| `jump.sh` | Directory jump function (`j`) |
| `deploy.sh` | Install script — 4 variants: zsh/bash × home/custom |
| `nwtools` | Interactive network troubleshooting menu (Mac + Pi) |
| `nwtools_testplan.md` | Test plan for `nwtools` |
| `man/man1/alias.1` | Man page — `man alias` (available once alias.zsh is sourced) |

## Aliases

**General** (auto-loaded on shell start):

| Command | Description |
|---------|-------------|
| `up` | `cd ..` |
| `home` / `hom` | `cd ~` |
| `cls` | Clear screen |
| `dd` | List only directories in current dir |
| `aalias <name>` | Show definition of any alias or function |
| `alh` | One-line help for every alias and function (parsed from source comments) |
| `x` | Open current directory in Finder |
| `np <file>` | Open file in TextEdit |
| `ia` | Network info (`ifconfig`) |
| `dt [dir]` | List files created/modified today (default: current dir) |
| `ff <name> [dir]` | Find file by name (skips hidden dirs; default: current dir) |
| `fff <name> [dir]` | Find file by name (includes hidden; default: current dir) |
| `psfe [dir]` | Count files by extension, sorted by count (default: current dir) |
| `psfed [dir]` | List empty directories (default: current dir) |
| `psfed -d [dir]` | Delete empty leaf directories |
| `psfed -dr [dir]` | Delete empty directories recursively until none remain |
| `sshfp` | Show fingerprints of all `~/.ssh` key pairs (private + public) to verify they match |
| `mch` | Show Mac-to-Mac alias reference |
| `mcv <name>` | Open Screen Sharing → `<name>.local` (e.g. `mcv mm`) |
| `mcp <name>` | SSH → `rainers@<name>.local` using private key (e.g. `mcp mm`, `mcp mb`) |
| `mcw <name>` | SFTP → `rainers@<name>.local` using private key (e.g. `mcw mm`, `mcw mb`) |
| `mcc <name[,name]> <cmd>` | Run command on one or more Macs by `.local` name (e.g. `mcc mm,mb uptime`) |
| `tree [dir]` | Display full file/folder tree from current (or given) directory |
| `tree -u [dir]` | Same, with human-readable sizes on each node |
| `tree -h [dir]` | Include hidden (dot) files and folders |
| `treed [dir]` | Display directory-only tree |
| `treed -h [dir]` | Directory-only tree including hidden dirs |
| `treed -j [dir]` | Directory tree and add all dirs to `~/.jumplocations` |
| `loop <cmd>` | Repeat a command every 2s, clearing screen each time (ESC or Ctrl-C to stop) |
| `loop <n>s <cmd>` | Same with custom wait (e.g. `loop 5s ls`) |
| `loop <cmd> + <cmd>` | Run multiple commands per cycle (e.g. `loop ls + pwd`) |
| `loop "<cmd>;<cmd>"` | Same using quoted semicolons (e.g. `loop "ls;pwd"`) |
| `loopk [<n>s] <cmd>` | Like `loop` but keeps output — no clear screen between runs |
| `cpu` | System dashboard: CPU, OS, mem, disk, net, Docker, uptime (brief by default) |
| `cpu -v` | Same info in full section-by-section view |
| `vsc [path]` | **Mac:** open VS Code. **Pi:** open VS Code on Mac with Remote SSH to this Pi |
| `dcu [folder]` | `docker compose up` (auto-detects plugin vs standalone; optional folder) |
| `dcud [folder]` | `docker compose up -d` (detached; optional folder) |
| `dcd [folder]` | `docker compose down` (optional folder) |
| `dcde [folder]` | `docker compose down` + remove all images, volumes, networks, orphans |

**Mac Screen Sharing setup** (one-time, run on the remote Mac if Remote Management blocks VNC):

```bash
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
  -activate -configure -access -on -privs -all -users rainers \
  -clientopts -setvnclegacy -vnclegacy yes -setvncpw -vncpw <password>
```

Then connect with `mcv <name>` using the VNC password set above (not the Mac login password).

**Raspberry Pi** (auto-loaded, key read from `~/.ssh/id_rsa`):

| Command | Description |
|---------|-------------|
| `rap <octet>` | SSH → `pi@192.168.1.<octet>` with key |
| `rapp <octet>` | SSH → `pi@192.168.1.<octet>` without key |
| `rapv <host>` | SSH → `pi@<host>.ssb8.local` with key |
| `rapa <host>` | SSH → `pi@<host>.pi.hole` with key |
| `raphav` | SSH → `root@hassio.ssb8.local` port 22222 with key |
| `raphaa` | SSH → `root@hassio.pi.hole` port 22222 with key |
| `rac <octet> <cmd>` | Run command on Pi by IP octet (or comma-separated list) |
| `racv <host> <cmd>` | Run command on Pi by `.ssb8.local` hostname |
| `raca <host> <cmd>` | Run command on Pi by `.pi.hole` hostname |
| `raw <octet>` | SFTP → `pi@192.168.1.<octet>` with key |
| `rawv <host>` | SFTP → `pi@<host>.ssb8.local` with key |
| `rawa <host>` | SFTP → `pi@<host>.pi.hole` with key |
| `raauth <octet>` | Add Mac's `id_rsa.pub` to Pi's `authorized_keys` + write `MAC_USER` to Pi's `.bashrc` |
| `racpub <octet>` | Copy `id_rsa.pub` to `pi@192.168.1.<octet>:~/.ssh/` |
| `racpri <octet>` | Copy `id_rsa` to `pi@192.168.1.<octet>:~/.ssh/` and `chmod 600` |
| `vscr <octet> [path]` | Open VS Code with Remote SSH to `pi@192.168.1.<octet>` |
| `vscrv <host> [path]` | Open VS Code with Remote SSH to `pi@<host>.ssb8.local` |
| `vscra <host> [path]` | Open VS Code with Remote SSH to `pi@<host>.pi.hole` |
| `rah` | Show this alias reference |

**SSH key setup for a new Pi** (run from Mac, using password auth):

```bash
raauth 59    # adds Mac's public key to Pi .59's authorized_keys + writes MAC_USER to Pi .bashrc
racpri 59    # copies Mac's private key to Pi .59 (needed for Pi-to-Pi SSH and vsc)
```

After `raauth`, `rap <octet>` works from the Mac. After `racpri`, the Pi can also SSH into other Pis that have been set up with `raauth`.

**VS Code Remote SSH** (`vsc` from a Pi, or `vscr`/`vscrv`/`vscra` from the Mac):

- **From Mac:** `vscr 52` opens VS Code connected to Pi 52 at `/home/pi`.
- **From Pi:** type `vsc` (or `vsc /some/path`) — it reverse-SSHes to the Mac and opens VS Code with a Remote SSH session pointing at the Pi.

Prerequisites:
1. Mac **Remote Login** enabled: System Settings → General → Sharing → Remote Login → ON
2. Run `raauth <octet>` from the Mac for each Pi (adds Mac key to Pi + writes `MAC_USER` to Pi's `.bashrc`)
3. Run `racpri <octet>` from the Mac for each Pi (copies private key to Pi so it can reverse-SSH back)

```bash
# One-time setup per Pi (from Mac, password auth):
raauth 52    # authorize Mac key on Pi + set MAC_USER
racpri 52    # copy private key to Pi

# Then from Pi 52 (via rap 52):
vsc          # opens VS Code on Mac → Remote SSH → Pi 52:/home/pi
vsc ~/myproject  # opens a specific folder
```

**Synology NAS** (auto-loaded, host `192.168.1.116`, user `pipi`, key `~/.ssh/id_rsa`):

| Command | Description |
|---------|-------------|
| `syp` | SSH into Synology (with key) |
| `sypp` | SSH into Synology (password, no key) |
| `syc <cmd>` | Run command on NAS via stdin pipe to bash |
| `syw` | Interactive SFTP session |
| `sywl [dir]` | List remote directory (default: `~`) |
| `sywg <remote> [local]` | Download file/dir (scp -r; default local: `.`) |
| `sywu <local> [remote]` | Upload file/dir (scp -r; default remote: `~`) |
| `sywmk <dir>` | Create directory on NAS |
| `sywrm <path>` | Remove file on NAS (confirms first) |
| `syvsc [path]` | Open VS Code with Remote SSH (default: `/volume1/homes/pipi`) |
| `syauth` | Add Mac's `id_rsa.pub` to NAS + configure passwordless sudo (two password prompts) |
| `syh` | Show Synology alias help |

**First-time setup on a new Synology** (run from Mac, password auth):

```bash
syauth    # step 1: adds Mac key to authorized_keys; step 2: sets up passwordless sudo
```

After `syauth`, `syp` and `syc` work without a password.

> **Note:** Synology's default login shell is `/bin/sh` (ash). The `.bashrc` in this repo is written to be sourced from ash without errors. Do not edit `/etc/passwd` directly — DSM manages it and manual edits break SSH auth. To change the shell, use DSM Control Panel or the `admin` account with `chsh`.

**Git** (auto-loaded at login — `sl` to unload, `gital` to reload, `gh` to list):

| Command | Description |
|---------|-------------|
| `gs` | `git status` + fetch + diff vs default branch |
| `gps` | Push to default branch with tags |
| `gdm` | Diff current state vs default branch on origin |
| `gl` | Log with graph and all branches |
| `glo` | Log one-line |
| `ga` | `git add` |
| `gc` | `git commit -m` |
| `gac` | `git commit -a -m` |
| `gch` | `git checkout` |
| `gb` | `git branch` |
| `gpl` | `git pull` |
| `gdi` | `git diff` |
| `gst` / `gstp` | Stash / stash pop |
| `gstrip` | Replace full local history with a single commit (files unchanged) |
| `gplstrip` | Pull latest files from remote without restoring history |
| `grestore` | Wipe local repo and re-clone fresh with full history from remote |

### Git history management

These three commands let you work with minimal local storage by stripping git history, while keeping the ability to get it back.

**Typical workflows:**

**Clone and immediately strip history** (read-only use, save disk space):
```bash
gcl https://github.com/user/repo
cd repo
gstrip        # squashes all history into one commit locally
```

**Update files after stripping** (no history pulled):
```bash
gplstrip      # fetches + resets to remote HEAD — history stays stripped
```

**Make changes and push** (need full history for this):
```bash
grestore      # wipes local folder, re-clones with full history
# edit files
gac "my change"
gps
gstrip        # strip again when done
```

**Commands explained:**

| Command | What it does | When to use |
|---------|-------------|-------------|
| `gstrip` | Creates an orphan branch with all current files as a single commit, deletes old branch — remote is untouched | After cloning, or after pushing, when you want minimal local storage |
| `gplstrip` | `git fetch` + `git reset --hard origin/<branch>` — updates files without pulling history | Routine updates on a stripped repo (like `dbu` equivalent) |
| `grestore` | Saves the remote URL, deletes the local folder, re-clones from remote | Before making changes that need to be pushed |

> **Note:** `gstrip` only affects your local repo. The remote always keeps full history. `grestore` is destructive — any uncommitted local changes will be lost.

**Shell management:**

| Command | Description |
|---------|-------------|
| `j <name>` | Jump to a previously-visited directory by partial name |
| `j -d` | Remove current directory from jump cache |
| `j -dr` | Remove current directory and all subdirs from jump cache |
| `allal` | Reload all alias files from scratch |
| `sl` | Unload git aliases and reload shell profile |
| `gital` | Reload git aliases |
| `gh` | List all git aliases |

---

## Network Tools (`nwtools`)

Interactive menu for network troubleshooting — Windows `ipconfig`/`arp` equivalents. Works on Mac (zsh) and Raspberry Pi (bash). Docker interfaces are automatically hidden on Pi.

```bash
~/alias/nwtools
```

| Choice | Tool | Description |
|--------|------|-------------|
| `1` | ipconfig | IPv4 addresses (real interfaces, docker hidden) |
| `i` | ipconfig v6 | IPv6 addresses |
| `2` | ipconfig /all | IPv4 full details: interfaces, routes, DNS |
| `j` | ipconfig /all v6 | IPv6 full details: interfaces, IPv6 routes, DNS |
| `3` | ipconfig /release | Release DHCP lease on active interface |
| `4` | ipconfig /renew | Renew DHCP lease on active interface |
| `5` | ipconfig /flushdns | Flush DNS cache |
| `6` | arp -a | Show ARP/neighbour table |
| `7` | arp -d | Clear ARP/neighbour table |
| `8` | ping gateway | Ping auto-detected default gateway |
| `9` | ping 8.8.8.8 | Internet connectivity check |
| `a` | traceroute | Trace route to host (mtr → traceroute → tracepath) |
| `b` | dns lookup | Query A/AAAA/MX/NS/TXT via dig / nslookup / host |
| `c` | routing table | Show routes (v4 + v6 on Linux) |
| `d` | connections | Active/listening ports (`ss -tulpn` / `netstat`) |
| `e` | external IP | Fetch public IP via ifconfig.me |
| `f` | port test | `nc -zv <host> <port>` |
| `g` | wifi info | Wireless interface details |
| `h` | wake-on-LAN | Send WOL magic packet |
| `k` | iface summary | One-line table: interface / state / IPv4 / IPv6 |
| `l` | bandwidth test | Gateway + internet latency, Cloudflare download speed |
| `0` | exit | |

Missing tools (nc, traceroute, etc.) show a clear error with `apt install` hint rather than silently failing.
