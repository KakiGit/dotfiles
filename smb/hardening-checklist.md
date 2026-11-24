# NAS isolation — hardening checklist

The client side (mounts) lives in `smb/`; this file is the server and network
side. Threat model: the NAS is internet-adjacent through the shadowsocks/xray
tunnel on OPNsense, so management and file services are reachable only from
named sources, and a compromised client must not reach anything else.

## Synology (DSM)

### Updates first
- [ ] DSM >= 7.3.2-86009-6 (NGINX2Root, CVE-2026-123007); until then disable
      HTTP/2 under Control Panel → Network → Connectivity
- [ ] Auto-update enabled for DSM and packages
- [ ] Unused packages uninstalled (Web Station / PHP packages if not serving)

### Accounts
- [ ] 2FA on every account, auto-block on failed logins
- [ ] Dedicated accounts per role: `media` (read-only shares), `webdav` (only
      the folders desktop apps need). WebDAV skips 2FA — never reuse personal
      credentials there

### File services
- [ ] SMB only: min/max protocol SMB3, NT1 disabled, guest access disabled,
      NetBIOS disabled; NFS stays off
- [ ] Shared-folder ACLs least privilege, no "Everyone" entries

### WebDAV
- [ ] HTTPS port 5006 only; HTTP port 5005 disabled (cleartext basic auth)

### Exposure
- [ ] QuickConnect disabled, UPnP disabled, no router port forwards
- [ ] Remote access only via the OPNsense tunnel

### Assume breach
- [ ] Scheduled read-only snapshots on shared folders (Snapshot Replication)
- [ ] Hyper Backup to an offsite target with versioning/encryption

## OPNsense

### VLANs
Addresses below are RFC 5737 documentation examples — pick your own.

| VLAN | Name    | Subnet           | Contains |
|------|---------|------------------|----------|
| 10   | Trusted | 192.0.2.0/24     | desktops |
| 20   | Media   | 198.51.100.0/24  | TV boxes, players |
| 30   | Storage | 203.0.113.0/24   | the NAS alone (static .10) |
| 40   | Guest   | any (isolated)   | guests |

Aliases: `NAS_ADDR` = 203.0.113.10; `TUNNEL_SOURCES` = the source IP tunnel
traffic arrives as (check Firewall → Log View after the first connect).

### Rules (per interface tab, top → bottom)
| Interface | Rules |
|-----------|-------|
| Trusted   | allow TCP 445 → `NAS_ADDR`; allow TCP 5006 → `NAS_ADDR`; allow DNS/NTP → this firewall; allow → any (internet); default deny (log) |
| Media     | allow TCP 445 → `NAS_ADDR`; allow DNS/NTP → this firewall; allow → any (internet); default deny (log) |
| Storage   | deny (log) → RFC1918; allow DNS/NTP → this firewall; allow → any (WAN: DSM updates, Hyper Backup); default deny |
| Guest     | default deny (log) |
| Tunnel    | allow TCP 5000,5001 → `NAS_ADDR` from `TUNNEL_SOURCES` only (DSM + Photos) |

### Tunnel
- [ ] xray routes tunnel clients only to the ports above — no blanket LAN
      subnet rule
- [ ] Synology Photos app configured with NAS_IP:5001, QuickConnect not used

## Client (this machine)

- [ ] `cifs-utils` installed (provides `mount.cifs`)
- [ ] `FEATURES=vim,fish,starship,fzf,smb setup.sh`
- [ ] `setup.sh scaffold smb/mounts.conf && sops-edit.sh smb/mounts.conf`
- [ ] `setup.sh scaffold smb/secrets/media && sops-edit.sh smb/secrets/media`
      (extra accounts: `cp smb/secrets/media.example smb/secrets/<name>.example` first)
- [ ] Preview: `~/dotfiles/smb/smb.sh dry`
- [ ] Install: `~/dotfiles/smb/smb.sh` (safe to re-run; prunes removed shares)

## Verification

- [ ] `nmap -p 22,137,138,139,445,2049,5000,5001,5005,5006 <NAS_ADDR>` from
      Trusted: only 445, 5006, 5000/5001 open
- [ ] Same scan from Media VLAN: only 445; a write attempt with the `media`
      account fails
- [ ] Through the tunnel: only 5000/5001; Photos works; SMB/WebDAV/SSH
      unreachable
- [ ] Firewall → Log View shows logged denies from each boundary
- [ ] `mount | grep cifs` shows vers=3.1.1 and the expected ro/rw split
