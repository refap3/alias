# nwtools Test Plan

## Platforms
- [ ] Mac (zsh / bash)
- [ ] Raspberry Pi (bash)

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
| T1 | 1 | Run ipconfig | ifconfig output with inet/ether lines |
| T2 | 2 | Run ipconfig /all | Three sections: Interfaces, Hardware Ports, DNS |
| T3 | 3 | Run ipconfig /release | sudo prompt, "Releasing DHCP lease on: en0" (or active iface), "Done." |
| T4 | 1 | Run ipconfig after release | IP address gone from active iface |
| T5 | 4 | Run ipconfig /renew | sudo prompt, "Renewing DHCP lease on: en0", "Done." |
| T6 | 1 | Run ipconfig after renew | IP address restored |
| T7 | 5 | Run ipconfig /flushdns | sudo prompts, "DNS cache flushed." |
| T8 | 6 | Run arp -a | ARP table with IP → MAC entries |
| T9 | 7 | Run arp -d | "Clearing ARP cache...", sudo, "Done." |
| T10 | 6 | Run arp -a after arp -d | Table empty or repopulating |

---

## Tool Tests — Raspberry Pi (Linux)

| # | Choice | Test | Expected |
|---|--------|------|----------|
| L1 | 1 | Run ipconfig | `ip addr show` output |
| L2 | 2 | Run ipconfig /all | Four sections: Interfaces, Link, Routes, DNS |
| L3 | 3 | Run ipconfig /release (dhclient present) | "Releasing DHCP lease on: eth0", "Done." |
| L4 | 3 | Run ipconfig /release (no dhclient/dhcpcd) | "ERROR: Neither dhclient nor dhcpcd found." |
| L5 | 4 | Run ipconfig /renew | "Renewing DHCP lease on: eth0", "Done.", IP re-assigned |
| L6 | 5 | Run flushdns (systemd-resolve present) | "DNS cache flushed." |
| L7 | 5 | Run flushdns (no systemd-resolve) | ERROR message with manual fallback hint |
| L8 | 6 | Run arp -a | ARP table |
| L9 | 7 | Run arp -d | `ip neigh flush all`, "Done." |

---

## Edge Cases

| # | Test | Expected |
|---|------|----------|
| E1 | Run release/renew with no default route | "ERROR: Could not detect active interface." |
| E2 | Run as non-sudo user | sudo password prompt appears (no silent failure) |
| E3 | Run on Linux with `ip` but no `arp` installed | arp tools fail with clear error |
| E4 | Disconnect network, run tool 1 | Graceful output (empty or loopback only), no crash |

---

## Suggested Additional Tools (not yet implemented)

| # | Tool | Windows equiv | Notes |
|---|------|---------------|-------|
| S1 | Ping gateway | `ping <gateway>` | auto-detect gateway |
| S2 | Ping 8.8.8.8 | `ping 8.8.8.8` | internet connectivity check |
| S3 | Traceroute | `tracert` | Mac: `traceroute`, Pi: `traceroute`/`mtr` |
| S4 | DNS lookup | `nslookup`/`dig` | prompt for hostname |
| S5 | Routing table | `route print` | Mac: `netstat -rn`, Pi: `ip route` |
| S6 | Active connections | `netstat -an` | Mac: `netstat -an`, Pi: `ss -tulpn` |
| S7 | External IP | — | `curl -s ifconfig.me` |
| S8 | Port test | `telnet <host> <port>` | `nc -zv <host> <port>` |
| S9 | WiFi info | `netsh wlan show` | Mac: `airport -I`, Pi: `iwconfig` |
| S10 | Wake-on-LAN | — | `wakeonlan <mac>` or `wol` |
