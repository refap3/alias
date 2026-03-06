# nwtools Test Plan

## Platforms
- [ ] Mac (zsh / bash)
- [ ] Raspberry Pi / Debian (bash) — host 93

---

## Menu Behaviour

| # | Test | Expected |
|---|------|----------|
| M1 | Launch `./nwtools` | Screen clears, menu displays |
| M2 | Enter invalid input (e.g. `x`, `99`) | "Invalid choice.", 1s pause, menu redisplays |
| M3 | Enter `0` | "Exiting...", script exits cleanly |
| M4 | After any tool: press Enter | Returns to menu |
| M5 | After any tool: verify layout | "Begin X", separator, output, separator, "End X", prompt |

---

## Tool Tests — Mac

| # | Choice | Test | Expected |
|---|--------|------|----------|
| T1 | 1 | ipconfig | Only `inet` (v4) lines + ether; no `inet6` |
| T2 | i | ipconfig v6 | Only `inet6` lines; no bare `inet` |
| T3 | 2 | ipconfig /all | Interfaces (v4), Hardware Ports, DNS sections |
| T4 | j | ipconfig /all v6 | Interfaces (v6), Hardware Ports, DNS sections |
| T5 | 3 | ipconfig /release | sudo prompt, "Releasing DHCP lease on: en0", "Done." |
| T6 | 1 | ipconfig after release | IP gone from active iface |
| T7 | 4 | ipconfig /renew | sudo, "Renewing DHCP lease on: en0", "Done." |
| T8 | 1 | ipconfig after renew | IP restored |
| T9 | 5 | flushdns | sudo prompts, "DNS cache flushed." |
| T10 | 6 | arp -a | ARP table IP → MAC |
| T11 | 7 | arp -d | "Clearing ARP cache...", sudo, "Done." |

---

## Tool Tests — Raspberry Pi / Debian (host 93)

| # | Choice | Test | Expected |
|---|--------|------|----------|
| L1 | 1 | ipconfig | `ip -4 addr` output, no docker/veth/br- ifaces, no inet6 lines |
| L2 | i | ipconfig v6 | `ip -6 addr` output, no docker/veth/br- ifaces |
| L3 | 2 | ipconfig /all | Interfaces (v4), Routes (v4), DNS sections |
| L4 | j | ipconfig /all v6 | Interfaces (v6), IPv6 Routes section, DNS |
| L5 | 3 | ipconfig /release (dhclient present) | "Releasing DHCP lease on: eth0", "Done." |
| L6 | 3 | ipconfig /release (no dhclient/dhcpcd) | "ERROR: Neither dhclient nor dhcpcd found." |
| L7 | 4 | ipconfig /renew | "Renewing DHCP lease on: eth0", "Done.", IP re-assigned |
| L8 | 5 | flushdns (resolvectl present) | "DNS cache flushed (resolvectl)." |
| L9 | 5 | flushdns (no systemd) | ERROR message + /etc/resolv.conf printed |
| L10 | 6 | arp -a | ARP table |
| L11 | 7 | arp -d | `ip neigh flush all`, "Done." |

---

## New Tools — Mac + Pi

| # | Choice | Test | Expected |
|---|--------|------|----------|
| N1 | k | iface summary | Table with INTERFACE / STATE / IPv4 / IPv6 columns, one row per active iface |
| N2 | k | iface summary — docker present (Pi) | docker0/veth/br- rows excluded |
| N3 | k | iface summary — v6 only iface | IPv4 column blank, IPv6 populated |
| N4 | k | iface summary — link-local only | fe80 addresses NOT shown in IPv6 column |
| N5 | l | bandwidth test | Latency section: gateway RTT + 8.8.8.8 RTT; Download section: MB/s result |
| N6 | l | bandwidth test — no gateway | Gateway section skipped, internet ping still runs |
| N7 | l | bandwidth test — no curl/wget | "curl/wget not found — cannot test download speed." |
| N8 | l | bandwidth test — curl timeout | "(test failed or timed out)" |

---

## DNS Lookup — enhanced

| # | Choice | Test | Expected |
|---|--------|------|----------|
| D1 | b | default host + default type (A) | A record for google.com |
| D2 | b | custom host, type AAAA | IPv6 address returned |
| D3 | b | custom host, type MX | MX records returned |
| D4 | b | custom host, type TXT | TXT records returned |
| D5 | b | type NS | NS records returned |
| D6 | b | no dig, nslookup present | nslookup -type= used |
| D7 | b | no dig/nslookup, host present | host -t used |
| D8 | b | no DNS tools | ERROR + install hint |

---

## IPv4/IPv6 isolation — no cross-contamination

| # | Test | Expected |
|---|------|----------|
| V1 | Run `1` on host with both v4 and v6 | Zero `inet6` lines in output |
| V2 | Run `i` on host with both v4 and v6 | Zero bare `inet ` lines (only `inet6`) |
| V3 | Run `2` and `j`, diff Interfaces section | v4 shows only `inet`, v6 shows only `inet6` |
| V4 | Run `2` (Linux) | Routes section uses `ip route` (v4), no ip -6 route |
| V5 | Run `j` (Linux) | Routes section uses `ip -6 route`, filtered |

---

## Edge Cases

| # | Test | Expected |
|---|------|----------|
| E1 | Run release/renew with no default route | "ERROR: Could not detect active interface." |
| E2 | Run as non-sudo user | sudo password prompt appears (no silent failure) |
| E3 | Run on Linux with `ip` but no `arp` installed | `ip neigh show` fallback used |
| E4 | Disconnect network, run tool 1 | Graceful output (empty or loopback only), no crash |
| E5 | Run `i` on host with no IPv6 | Empty output, no crash |
| E6 | Run `l` bandwidth, slow connection (<1 MB/s) | Result shown correctly (not 0 or blank) |

---

## Extended (pre-existing tools — regression)

| # | Choice | Test | Expected |
|---|--------|------|----------|
| X1 | 8 | ping gateway | Auto-detects gateway, 4 pings, RTT shown |
| X2 | 9 | ping 8.8.8.8 | 4 replies |
| X3 | a | traceroute (default 8.8.8.8) | Hops displayed |
| X4 | c | routing table | Routes shown; Pi also shows IPv6 section |
| X5 | d | connections (Pi, ss) | ss -tulpn output |
| X6 | e | external IP | Public IP printed |
| X7 | f | port test — open port | success message |
| X8 | f | port test — closed port | connection refused |
| X9 | f | port test — empty input | "ERROR: Host and port required." |
| X10 | g | wifi info — wired Pi | no wireless / ERROR message, no crash |
| X11 | h | WOL — empty MAC | "ERROR: MAC address required." |
