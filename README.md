# alias

Portable shell configuration for zsh and bash — aliases, git shortcuts, Raspberry Pi helpers, and a directory jump function.

## Install (one line)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/refap3/alias/master/install.sh)
```

Clones a shallow copy (no history) into `~/alias` and runs `deploy.sh`.
To update later: `git -C ~/alias pull`

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
| `jump.sh` | Directory jump function (`j`) |
| `deploy.sh` | Install script — 4 variants: zsh/bash × home/custom |

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
| `tree [dir]` | Display full file/folder tree from current (or given) directory |
| `tree -u [dir]` | Same, with human-readable sizes on each node |
| `treed [dir]` | Display directory-only tree |
| `treed -j [dir]` | Directory tree and add all dirs to `~/.jumplocations` |
| `cpu` | System dashboard: CPU, OS, mem, disk, net, Docker, uptime (brief by default) |
| `cpu -v` | Same info in full section-by-section view |
| `vsc [path]` | **Mac:** open VS Code. **Pi:** open VS Code on Mac with Remote SSH to this Pi |

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
