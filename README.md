# alias

Portable shell configuration for zsh and bash — aliases, git shortcuts, Raspberry Pi helpers, and a directory jump function.

## Quick start

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
| `gitalias.zsh` | Git shortcuts (load on demand with `gital`) |
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
| `dt` | List files created/modified today in current dir |
| `ddd` | List only directories in current dir |
| `aalias <name>` | Show definition of any alias or function |
| `x` | Open current directory in Finder |
| `np <file>` | Open file in TextEdit |
| `ia` | Network info (`ifconfig`) |
| `ff <name>` | Find file by name (skips hidden dirs) |
| `fff <name>` | Find file by name (includes hidden) |
| `sshfp` | Show fingerprints of all `~/.ssh` key pairs (private + public) to verify they match |

**Raspberry Pi** (auto-loaded, key read from `~/.ssh/id_rsa`):

| Command | Description |
|---------|-------------|
| `rap <octet>` | SSH → `pi@192.168.1.<octet>` with key |
| `rapp <octet>` | SSH → `pi@192.168.1.<octet>` without key |
| `rapv <host>` | SSH → `pi@<host>.ssb8.local` with key |
| `rapa <host>` | SSH → `pi@<host>.pi.hole` with key |
| `raphav` | SSH → `root@hassio.ssb8.local` port 22222 with key |
| `raphaa` | SSH → `root@hassio.pi.hole` port 22222 with key |
| `raw <octet>` | SFTP → `pi@192.168.1.<octet>` with key |
| `rawv <host>` | SFTP → `pi@<host>.ssb8.local` with key |
| `rawa <host>` | SFTP → `pi@<host>.pi.hole` with key |
| `raauth <octet>` | Add Mac's `id_rsa.pub` to `pi@192.168.1.<octet>:~/.ssh/authorized_keys` |
| `racpub <octet>` | Copy `id_rsa.pub` to `pi@192.168.1.<octet>:~/.ssh/` |
| `racpri <octet>` | Copy `id_rsa` to `pi@192.168.1.<octet>:~/.ssh/` and `chmod 600` |
| `rah` | Show this alias reference |

**SSH key setup for a new Pi** (run from Mac, using password auth):

```bash
raauth 59    # adds Mac's public key to Pi .59's authorized_keys
racpri 59    # copies Mac's private key to Pi .59 (needed for Pi-to-Pi SSH)
```

After `raauth`, `rap <octet>` works from the Mac. After `racpri`, the Pi can also SSH into other Pis that have been set up with `raauth`.

**Git** (not auto-loaded — run `gital` to load, `gh` to list):

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
| `allal` | Reload all alias files from scratch |
| `sl` | Unload git aliases and reload shell profile |
| `gital` | Load git aliases on demand |
| `gh` | List all loaded git aliases |
