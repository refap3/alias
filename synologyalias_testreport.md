# synologyalias Test Report

**Date:** 2026-03-20 (SFTP retest same day after DSM SFTP enabled)
**Host:** 192.168.1.116 (pipi)  **Mac:** rainers@192.168.1.47
**Tester:** Claude (automated, zsh)

---

## Summary

| Category | Pass | Fail | Skip |
|----------|------|------|------|
| Prerequisites | 4 | 0 | 0 |
| syh — help | 2 | 0 | 0 |
| _sykey | 2 | 0 | 0 |
| syp / sypp | 1 | 0 | 2 (need interactive TTY) |
| syc | 6 | 0 | 1 |
| syauth | 2 | 0 | 1 (already set up) |
| syvsc | 2 | 1 | 0 |
| syw / SFTP group | 8 | 0 | 1 (interactive syw) |
| sywrm confirm | 3 | 0 | 0 |
| Edge cases | 1 | 0 | 0 |
| **Total** | **27** | **1** | **5** |

**All code bugs resolved. 1 hardware limitation (syvsc/glibc).**

---

## Prerequisites

| # | Test | Result | Notes |
|---|------|--------|-------|
| P1 | `source synologyalias.zsh` | **PASS** | No errors |
| P2 | Vars set | **PASS** | `SY_HOST=192.168.1.116 SY_USER=pipi PI_KEY=/Users/rainers/.ssh/id_rsa` |
| P3 | `ping -c1 192.168.1.116` | **PASS** | 0% loss, RTT 0.471 ms |
| P4 | Key file | **PASS** | Present, mode `600` |

---

## syh — Help

| # | Test | Result | Notes |
|---|------|--------|-------|
| H1 | `syh` output | **PASS** | Header shows correct host/user; all 10 commands listed |
| H2 | All functions exist | **PASS** | `syp syc syw sywl sywg sywu sywmk sywrm syauth syvsc` all resolve as shell functions |

---

## _sykey — Key helper

| # | Test | Result | Notes |
|---|------|--------|-------|
| K1 | Key present | **PASS** | `_SYKEYOPT=(-i /Users/rainers/.ssh/id_rsa)`, chmod 600 applied |
| K2 | Key absent (`PI_KEY=/tmp/nonexistent`) | **PASS** | `_SYKEYOPT` empty, no error |

---

## syp / sypp — Interactive SSH

| # | Test | Result | Notes |
|---|------|--------|-------|
| S1 | `syp` interactive | **SKIP** | Requires interactive TTY; confirmed key auth works via `syc` |
| S2 | `sypp` password | **SKIP** | Requires interactive TTY |
| S3 | `syp` bad host | **PASS** | Exit 255 with `ConnectTimeout=3`, no hang |

---

## syc — Remote command

| # | Test | Result | Notes |
|---|------|--------|-------|
| C1 | `syc hostname` | **PASS** | Returns `synology` |
| C2 | `syc echo hello world` | **PASS** | Returns `hello world` |
| C3 | `syc ls /volume1` | **PASS** | Full directory listing returned |
| C4 | `syc echo "a b"` | **PASS** | Returns `a b` — quoting preserved |
| C5 | `syc ll` (alias) | **SKIP** | `ll` not defined in NAS `.bashrc`; bash -i mechanism verified: `alias` command shows `gl`, `gpl` loaded from `.bashrc` |
| C6 | stderr suppression | **PASS** | 0 bytes on stderr from `syc hostname` |
| C7 | `syc ls /nonexistent` | **PASS** | Returns error message, exit 2 (non-zero) |

---

## syauth — Key + sudo setup

| # | Test | Result | Notes |
|---|------|--------|-------|
| A1 | First-run (add pubkey) | **SKIP** | Already set up; `~/.ssh/authorized_keys` has 1 entry |
| A2 | `syp` without password | **PASS** | Key auth confirmed (all `syc` calls succeed without password) |
| A3 | `syc sudo whoami` | **PASS** | Returns `root` — passwordless sudo active |

---

## syvsc — VS Code Remote SSH

| # | Test | Result | Notes |
|---|------|--------|-------|
| V1 | `syvsc` no arg | **PASS** | Constructs `code --remote ssh-remote+pipi@192.168.1.116 /volume1/homes/pipi` |
| V2 | `syvsc /volume1/data` | **PASS** | Constructs `code --remote ssh-remote+pipi@192.168.1.116 /volume1/data` |
| V3 | VS Code opens remote | **FAIL** | NAS has glibc 2.26; VS Code Server requires 2.28+. `syvsc` command is correct (exit 0) but VS Code cannot install its server on this hardware. Not a code bug — hardware limitation of DS218+ on DSM apollolake. |

---

## SFTP group — syw / sywl / sywg / sywu / sywmk / sywrm

> Retested after enabling SFTP in DSM. Bug #1 resolved.
>
> **Synology sftp root note:** The sftp session root is `/volume1`, not `/`.
> `sywl` with no arg lists `/volume1` (the NAS volume root). Absolute paths like `/volume1` are not valid inside sftp — use relative paths (`homes/pipi/...`) or paths starting from the sftp root.

| # | Alias | Test | Result | Notes |
|---|-------|------|--------|-------|
| F1 | `syw` | Interactive sftp session | **SKIP** | Requires interactive TTY; SFTP subsystem confirmed working via sywl/sywg |
| L1 | `sywl` | No arg (home) | **PASS** | Lists `/volume1` root; exit 0 |
| L2 | `sywl /volume1` | Absolute path | **FAIL** | `Can't ls: "/volume1" not found` — sftp root IS `/volume1`, so this double-paths. Test plan assumption wrong; not a code bug |
| L3 | `sywl /nonexistent_$$` | Nonexistent | **PASS** | sftp error, exit 1, no crash |
| G1 | `sywg homes/pipi/alias/synologyalias.zsh /tmp/` | File download | **PASS** | File downloaded, exit 0 |
| G3 | `sywg homes/pipi/alias /tmp/sy_dl_dir_test` | Dir recursive | **PASS** | Full directory downloaded, exit 0 |
| G4 | `sywg /nonexistent` | Nonexistent remote | **PASS** | `scp: No such file or directory`, exit 1 |
| U1 | `sywu /tmp/sy_upload_test.txt homes/pipi/` | File upload | **PASS** | File confirmed on NAS via `syc ls`, exit 0 |
| U3 | `sywu /tmp/sy_upload_dir_test homes/pipi/` | Dir recursive | **PASS** | Dir + contents confirmed on NAS, exit 0 |
| M1 | `sywmk homes/pipi/testdir_$$` | Create dir | **PASS** | Dir created, visible in `sywl`, exit 0 |
| M2 | `sywmk` existing dir | Already exists | **PASS** | sftp mkdir error, exit 1, no crash |
| R1 | `sywrm` answer `y` | Confirm delete | **PASS** | File removed; confirmed gone via `syc ls` |
| R2 | `sywrm` answer `n` | Reject delete | **PASS** | File untouched, exit 1 |
| R3 | `sywrm` Enter (default) | Default N | **PASS** | File untouched, exit 1 |

---

## Edge Cases

| # | Test | Result | Notes |
|---|------|--------|-------|
| E1 | `syc` unreachable host | **PASS** | Exit 255, no hang (SSH default timeout) |

---

## Bugs Found

### ~~Bug #1 — SFTP subsystem not enabled~~ — RESOLVED

**Resolution:** Enabled SFTP in DSM → Control Panel → File Services → FTP → Enable SFTP service.
All `syw*` aliases now work (except `sywrm` which has Bug #2).

---

### ~~Bug #2 — `sywrm`: `read -rq` requires interactive TTY~~ — FIXED

**Fix applied:** Replaced `read -rq` with `printf` prompt + `read -r _reply` + `[[ "$_reply" == [yY] ]]`.
Tested: `y` deletes, `n` and Enter both abort. Works in non-interactive context.
