# synologyalias Test Plan

Host: `192.168.1.116`  User: `pipi`  Key: `~/.ssh/id_rsa`

---

## Prerequisites

| # | Check | Expected |
|---|-------|----------|
| P1 | Source file in zsh: `source synologyalias.zsh` | No errors |
| P2 | `$SY_HOST`, `$SY_USER`, `$PI_KEY` set | `192.168.1.116`, `pipi`, `~/.ssh/id_rsa` |
| P3 | NAS reachable: `ping -c1 192.168.1.116` | Reply received |
| P4 | Key file present: `ls ~/.ssh/id_rsa` | File exists, `chmod 600` applied |

---

## `syh` — Help

| # | Test | Expected |
|---|------|----------|
| H1 | `syh` | Prints host + user header, lists all sy* commands with short descriptions |
| H2 | All aliases named in help exist as functions | `type syp syc syw sywl sywg sywu sywmk sywrm syauth syvsc` all resolve |

---

## `_sykey` — Key helper

| # | Test | Expected |
|---|------|----------|
| K1 | Key present → call `_sykey` | `_SYKEYOPT=(-i ~/.ssh/id_rsa)`, key chmoded 600 |
| K2 | Key absent (rename temporarily) → call `_sykey` | `_SYKEYOPT=()` (empty, no error) |

---

## `syp` / `sypp` — Interactive SSH

| # | Test | Expected |
|---|------|----------|
| S1 | `syp` | Opens interactive shell on NAS (with key auth), `hostname` shows NAS |
| S2 | `sypp` | Opens interactive shell via password (no `-i` key flag in ssh command) |
| S3 | `syp` with bad host (set `SY_HOST=192.168.1.1`) | SSH connection refused/timeout, no crash |

---

## `syc` — Remote command via stdin pipe

| # | Test | Expected |
|---|------|----------|
| C1 | `syc hostname` | NAS hostname printed |
| C2 | `syc echo hello world` | `hello world` |
| C3 | `syc ls /volume1` | Directory listing of `/volume1` |
| C4 | `syc` with multi-word arg: `syc echo "a b"` | `a b` (quoting preserved) |
| C5 | `syc` with alias: `syc ll` | Alias expanded (bash -i loads `.bashrc`) |
| C6 | `syc` stderr suppression | No TTY/locale warnings in output |
| C7 | `syc` failing command: `syc ls /nonexistent` | Error output from remote, exit code non-zero |

---

## `syauth` — Key + sudo setup

| # | Test | Expected |
|---|------|----------|
| A1 | Run `syauth` (no key in `authorized_keys` yet) | Prompts SSH password; adds pubkey; prompts sudo password; configures passwordless sudo; prints "syauth done" |
| A2 | After `syauth`: `syp` (no password) | Logs in without password prompt |
| A3 | After `syauth`: `syc sudo whoami` | Returns `root` without password prompt |
| A4 | Run `syauth` a second time | Pubkey appended again (duplicate) — idempotency note; sudo file overwritten harmlessly |

---

## `syvsc` — VS Code Remote SSH

| # | Test | Expected |
|---|------|----------|
| V1 | `syvsc` (no arg) | `code --remote ssh-remote+pipi@192.168.1.116 /volume1/homes/pipi` invoked |
| V2 | `syvsc /volume1/data` | `code --remote ssh-remote+pipi@192.168.1.116 /volume1/data` invoked |
| V3 | VS Code Remote SSH extension installed | VS Code opens remote window on NAS |

---

## `syw` — Interactive SFTP

| # | Test | Expected |
|---|------|----------|
| F1 | `syw` | Opens interactive sftp prompt on NAS |
| F2 | Inside `syw`: `pwd` | Shows remote home dir |
| F3 | Inside `syw`: `ls` | Lists remote files |

---

## `sywl` — List remote directory

| # | Test | Expected |
|---|------|----------|
| L1 | `sywl` (no arg) | Lists `~` (remote home) |
| L2 | `sywl /volume1` | Lists `/volume1` contents |
| L3 | `sywl /nonexistent` | sftp error, no crash |

---

## `sywg` — Download (scp -r)

| # | Test | Expected |
|---|------|----------|
| G1 | `sywg /volume1/homes/pipi/testfile.txt` | File downloaded to `.` (current dir) |
| G2 | `sywg /volume1/homes/pipi/testfile.txt /tmp/` | File downloaded to `/tmp/` |
| G3 | `sywg /volume1/homes/pipi/testdir` | Directory downloaded recursively to `.` |
| G4 | `sywg /nonexistent` | scp error, no crash |

---

## `sywu` — Upload (scp -r)

| # | Test | Expected |
|---|------|----------|
| U1 | `sywu /tmp/testfile.txt` | File uploaded to remote `.` (home dir) |
| U2 | `sywu /tmp/testfile.txt /volume1/homes/pipi/dest/` | File uploaded to specified remote path |
| U3 | `sywu /tmp/testdir` | Directory uploaded recursively |
| U4 | `sywu /nonexistent` | scp error, no crash |

---

## `sywmk` — Remote mkdir

| # | Test | Expected |
|---|------|----------|
| M1 | `sywmk testdir_$$` | sftp `mkdir` succeeds; `sywl` shows new dir |
| M2 | `sywmk existing_dir` | sftp mkdir error (already exists), no crash |

---

## `sywrm` — Remote rm (with confirmation)

| # | Test | Expected |
|---|------|----------|
| R1 | `sywrm remotefile.txt` — answer `y` | Prompts "rm remotefile.txt? [y/N]"; file removed; `sywl` no longer shows it |
| R2 | `sywrm remotefile.txt` — answer `n` | Prompts; file NOT removed |
| R3 | `sywrm remotefile.txt` — press Enter (default) | Defaults to No; file NOT removed |
| R4 | `sywrm /nonexistent` — answer `y` | sftp error, no crash |

---

## Edge Cases

| # | Test | Expected |
|---|------|----------|
| E1 | NAS unreachable (unplug / wrong IP) — `syc hostname` | SSH timeout/error printed, no hang beyond SSH timeout |
| E2 | Key not yet in `authorized_keys` — `syc hostname` | SSH falls back to password prompt (or fails if no TTY) |
| E3 | `sywl` with path containing spaces: `sywl "/volume1/my dir"` | Correct path passed to sftp; listing shown |
| E4 | `sywg` remote path with spaces | scp handles quoted path correctly |
| E5 | `sywrm` with non-file (directory) | sftp rm fails with error (rm is not rmdir), no crash |
| E6 | Source file in bash (not zsh) | All functions load; `read -rq` in `sywrm` behaves correctly |
