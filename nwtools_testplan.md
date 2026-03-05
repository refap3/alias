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

## Tool Tests — Extended (Mac + Pi)

| # | Choice | Test | Expected |
|---|--------|------|----------|
| X1 | 8 | Ping gateway | Auto-detects gateway, pings 4 times, shows RTT |
| X2 | 8 | Ping gateway — no default route | "ERROR: Could not detect default gateway." |
| X3 | 9 | Ping 8.8.8.8 | 4 ping replies, shows RTT |
| X4 | a | Traceroute — accept default (8.8.8.8) | Hops to 8.8.8.8 displayed |
| X5 | a | Traceroute — custom host | Hops to entered host |
| X6 | a | Traceroute — Pi, mtr present | mtr --report output |
| X7 | a | Traceroute — Pi, no mtr/traceroute | ERROR with install hint |
| X8 | b | DNS lookup — accept default (google.com) | A record returned |
| X9 | b | DNS lookup — custom hostname | DNS response shown |
| X10 | b | DNS lookup — no dig/nslookup | ERROR message |
| X11 | c | Routing table — Mac | `netstat -rn` output with gateway column |
| X12 | c | Routing table — Pi | `ip route` + `ip -6 route` output |
| X13 | d | Connections — Mac | LISTEN/ESTABLISHED lines from netstat |
| X14 | d | Connections — Pi (ss present) | `ss -tulpn` output |
| X15 | d | Connections — Pi (no ss) | netstat fallback or ERROR |
| X16 | e | External IP | Public IP printed, no trailing newline issues |
| X17 | e | External IP — no curl/wget | ERROR message |
| X18 | f | Port test — open port (e.g. 80 on google.com) | "Connection succeeded" / "open" |
| X19 | f | Port test — closed port | nc reports connection refused |
| X20 | f | Port test — empty host/port | "ERROR: Host and port required." |
| X21 | f | Port test — no nc | ERROR with install hint |
| X22 | g | WiFi info — Mac | SSID, BSSID, channel, signal strength |
| X23 | g | WiFi info — Pi (iwconfig) | Interface wireless stats |
| X24 | g | WiFi info — Pi (iw fallback) | `iw dev` output |
| X25 | g | WiFi info — Pi wired only | ERROR or no wireless extensions message |
| X26 | h | Wake-on-LAN — valid MAC | "Sending magic packet" message |
| X27 | h | Wake-on-LAN — empty MAC | "ERROR: MAC address required." |
| X28 | h | Wake-on-LAN — no wakeonlan/wol | ERROR with install hint |
