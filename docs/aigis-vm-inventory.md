# Aigis: ports, dependencies and what a VM needs

Inventory collected while booting the production `aigis` config (modules from `hosts/aigis` + sops-nix) in an offline NixOS test VM, as of develop `4a191ab` (2026-10-27). "Observed" means the answer was seen in that VM; anything not marked observed was not reached before the run was stopped.

## Services, ports and expected answers

IP is `192.168.2.50`. "LAN" means probed from a second VM through the production firewall. "local" means only reachable on the host itself.

| Service | Module | Unit(s) | Port | Probe → observed answer | Health endpoint | Auth |
|---|---|---|---|---|---|---|
| Caddy | infra/caddy.nix | caddy | 443/tcp | every `*.laufin.xyz` route via `--resolve host:443:IP` → 28 routes OK | none | TLS (prod: ACME DNS-01 at Namecheap) |
| | | | 80/tcp | `Host: jellyfin.laufin.xyz` → 308 to https | | |
| | | | 443/udp | HTTP/3 from local → 200 (UDP 443 is **not** opened in the firewall) | | |
| | | | 2019/tcp local | `/config/` → 200 (admin API) | | |
| Flame | infra/flame-homepage.nix | flame, flame-seed (oneshot) | 3311/tcp | `/` 200, `/api/apps` 200 (26 apps seeded) | none | `POST /api/auth` with flame_password → 200; wrong → 401 |
| Gatus | infra/gatus.nix | gatus | 8080/tcp | `/` 200 | `/health` 200 `UP` | public |
| nix-serve | infra/nix-cache.nix | nix-serve | 5757/tcp on 192.168.2.50 only | from 192.168.1.107 `/nix-cache-info` 200; from anything else blocked; narinfo signed `aigis-cache-1` | `/nix-cache-info` | source-IP firewall rule |
| ntfy | services/ntfy.nix | ntfy-sh | 8081/tcp | `/` 200; publish+poll works | `/v1/health` `{"healthy":true}` | anonymous |
| ntfy-on-ssh | infra/ntfy-on-ssh.nix | (PAM hook) | — | ssh login posts "aigis — ssh login" to topic `homelab` | — | — |
| Podman | infra/podman.nix | podman.socket, podman.service (socket-activated), podman-prune (+timer) | unix socket | `_ping` → OK | `/_ping` | root only |
| Restic | infra/restic-backup.nix | restic-zfs-backup (+timer, weekly) | — | **fails, exit 3**: `/var/lib/bazarr does not exist` | — | repo password |
| Samba | infra/samba.nix | samba-smbd, samba-nmbd, samba-winbindd, samba-wsdd | 445/tcp, 139/tcp | share list over 139 OK with a smbpasswd user | none | valid users only, guest denied |
| | | | 137/udp, 138/udp | nmbd owns both; 137 answers name queries, 138 is fire-and-forget | | |
| | | | 5357/tcp, 3702/udp | wsdd: GET → 501 (POST only); 3702 WS-Discovery Probe | | |
| SSH | infra/ssh.nix | sshd, sshd-keygen, sshd@, sshd-vsock@, sshd-vsock.socket | 22/tcp | key auth OK; password and root refused | none | publickey, AllowUsers maksym |
| WireGuard | infra/wireguard.nix | wireguard-wg0 + 3 peer oneshots | 51820/udp | not observed (needs a throwaway test peer) | — | peer keys |
| ZFS | infra/zfs.nix, health/zfs-logging.nix | zfs-import-tank2, zfs-mount, zfs-share, zfs-sync-tank2, zfs-scrub (+timer), zpool-trim (+timer), zfs-zed, zpool-events | — | pool `tank2` ONLINE | `zpool list` | — |
| health-monitor | health/health-monitor.nix | health-monitor (oneshot at boot + hourly timer) | — | `ALL CHECKS PASSED` | exit status | — |
| smartd | health/smartd.nix | smartd | — | `/etc/smartd-ntfy.sh` posts to ntfy `homelab` | — | — |
| FlareSolverr | services/flaresolverr.nix | flaresolverr | 8191/tcp | `/` 200 "FlareSolverr is ready!" | `/health` 200 | none |
| Fusion | services/fusion.nix | podman-fusion | 8085/tcp | `/` 200; `POST /api/sessions` with an empty password works | none | empty password allowed |
| MariaDB (HA) | services/hass-mariadb.nix | podman-hass-mariadb | 3306/tcp | `hass` login OK, wrong password → ERROR 1045 | `healthcheck.sh --connect --innodb_initialized` in container | MYSQL_PASSWORD |
| Immich | services/immich.nix | immich-server, immich-machine-learning, postgresql(+setup), redis-immich | 2283/tcp (bound to 192.168.2.50) | `/` 200 | `/api/server/ping` `{"res":"pong"}` | `/api/users/me` 401 anonymous |
| | | | 3003/tcp local | ML `/ping` → pong | | |
| | | | 5432/tcp local | pg_isready OK, immich db exists | | |
| IT-Tools | services/it-tools.nix | podman-it-tools | 8384/tcp | `/` 200 | none | public |
| Jellyfin | services/jellyfin.nix | jellyfin | 8096/tcp | `/` 302 → `/web/` | `/health` 200 `Healthy` | before the setup wizard, `/System/Info` is 200 without a token |
| | | | 7359/udp | discovery "who is JellyfinServer?" → JSON (not opened in firewall) | | |
| Karakeep | services/karakeep.nix | karakeep-web, karakeep-workers, karakeep-browser, karakeep-init, meilisearch | 3050/tcp | `/` 307 → `/signin` | `/api/health` 200 | `/api/v1/bookmarks` 401 |
| | | | 7700/tcp local | meilisearch `/health` available | | |
| | | | 9222/tcp local | chromium `/json/version` | | |
| Kavita | services/kavita.nix | kavita | 5000/tcp | `/` 200 | `/api/health` 200 | 401 anonymous; first `register` gives admin token |
| Kiwix | services/kiwix.nix | kiwix-serve | 8012/tcp | `/` 200, `/catalog/v2/entries` lists both books | none | public |
| Local Content Share | services/local-content-share.nix | local-content-share | 8087/tcp | `/` 200 | none | public |
| Piper | services/local-voice/piper.nix | wyoming-piper-piper | 10200/tcp | Wyoming describe → info; synthesize → audio 22050 Hz | describe/info | none |
| Whisper | services/local-voice/whisper.nix | wyoming-faster-whisper-whisper | 10300/tcp | listening; transcription not observed | describe/info | none |
| Matrix Admin | services/matrix-admin.nix | podman-matrix-admin | 7373/tcp | `/` 200 | none | via Synapse |
| Mazanoke | services/mazanoke.nix | podman-mazanoke | 3474/tcp | `/` 200 | none | public |
| Omni-Tools | services/omni-tools.nix | podman-omni-tools | 8086/tcp | `/` 200 | none | public |
| Prowlarr / Radarr / Sonarr | services/{prowlarr,radarr,sonarr}.nix | prowlarr, radarr, sonarr | 9696 / 7878 / 8989 tcp | `/` 200 | `/ping` `{"status":"OK"}` | `/api/v{1,3}/system/status` 401 without key, 200 with `<ApiKey>` from config.xml |
| qBittorrent | services/qbittorrent.nix | podman-qbittorrent | 8082/tcp | `/` 200; API 403 without session; login returns **204** (not "Ok.") | none | temporary admin password printed in container log |
| | | | 6881/udp | DHT ping → pong | | |
| | | | 6881/tcp | accepts connections | | |
| SearXNG | services/searxng.nix | searx, searx-init | 8882/tcp | `/` 200 | `/healthz` 200 `OK` | public |
| Stirling PDF | services/stirling-pdf.nix | stirling-pdf | 7080/tcp | `/` 200 | `/api/v1/info/status` `UP` | login disabled |
| Suwayomi | services/suwayomi.nix | suwayomi-server | 4568/tcp | `/` 200 | GraphQL `{ aboutServer { version } }` → 2.4.2366 | none |
| Technitium DNS | services/technitium-dns.nix | podman-dns | 5380/tcp | `/` 200 | none | first-run default admin/admin; wrong password refused |
| | | | 53/udp, 53/tcp | `dig @IP localhost A` → 127.0.0.1 on both (53/udp works via podman DNAT, not opened in firewall) | | |
| Vert | services/vert.nix | podman-vert | 7090/tcp | `/` 200 | none | public |
| Vikunja | services/vikunja.nix | vikunja | 1337/tcp | `/` 200 | `/health` 200 | 401 anonymous; open registration + login works |
| Wallos | services/wallos.nix | podman-wallos | 8282/tcp | not observed | none | — |

Gatus defines 35 endpoints. Once the external stand-ins below were up, all were green except `Cloudflare Tunnel` (`matrix.laufin.online`, needs internet). After 3 failures it alerted to ntfy topic `health`, so Gatus → ntfy works.

External hosts that Aigis proxies to or monitors (the VM needs stand-ins answering 200):

| Name | Address | Used by |
|---|---|---|
| Hermes | 192.168.2.205:9119 (`/api/status`) | Caddy `hermes.`, Gatus |
| Portainer (Morgana) | https 192.168.2.201:9443 | Caddy `portainer.` |
| Kavita on Morgana | 192.168.2.201:5066 | Gatus |
| Synapse on Morgana | 192.168.2.201:8008 | Gatus |
| DNS 2 | 192.168.2.207:5380 | Caddy `dns2.`, Gatus |
| Proxmox (Morgana) | tcp 192.168.2.20:8006 | Gatus |
| Home Assistant | 192.168.2.5:8123 | Gatus |
| belial | 192.168.1.107 | only allowed nix-serve client |

## What the VM needs to boot production aigis offline

- **Secrets:** all 15 `sops.secrets` must exist in a test sops file (`neededForUsers`: maksym/eklesa hashed passwords). Formats: `openai_api_key` = `OPENAI_API_KEY=…`, `hass_mariadb_password` = `MYSQL_PASSWORD=…`, `hass_mariadb_root_password` = `MYSQL_ROOT_PASSWORD=…`, `restic_repo` = `RESTIC_REPOSITORY=…`, `restic_password` = `RESTIC_PASSWORD=…`, `nix_cache_private_key` = `aigis-cache-1:<base64>` (`nix-store --generate-binary-cache-key`), `kavita_token_key` = 64 random bytes base64, the rest plain strings. Owners: `namecheap_*` → caddy, `searxng_secret_key` → searx; templates `Caddyfile` (caddy) and `searxng-env` (searx).
- **sops key:** `sops.age.keyFile` must not be a store path. Copy the test key to `/run/...` in an activation script, and make `setupSecrets` and `setupSecretsForUsers` depend on it. Set `sops.age.sshKeyPaths = []`.
- **Addresses:** `eth1` = 192.168.2.50/24 (Immich and nix-serve bind to it), plus an on-link route for 192.168.1.0/24. Mark `eth0`/`eth1` NetworkManager-unmanaged.
- **ZFS:** a pool named `tank2` (mountpoint `/mnt/tank`) on a scratch disk, created before `zfs-import-tank2`.
- **Directories:** `/mnt/tank/media/{photos/immich,downloads,ttrpgs}`, `/mnt/tank/users/maksym/backups/hass`, `/mnt/incomplete`, `/srv/kiwix/*.zim` (two tiny ZIMs built with `zimwriterfs` work), and `/var/lib/containers/{dns,fusion,hass-mariadb,qbittorrent,wallos/db,wallos/logos}`.
- **WireGuard:** `/etc/wireguard/server.key` must exist.
- **Caddy:** replace the `tls { dns namecheap … }` block with `tls internal`. The CA is at `/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`.
- **smartd:** exits when there are no SMART disks (QEMU has none), so it needs `-q never`.
- **Offline runtime downloads:**
  - Piper voice `en_US-lessac-medium.onnx(.json)`, from HF `rhasspy/piper-voices` rev `5041a7a49ae5b3a0f30e6837769eb03fdbb231bd` (`sha256-Xv4J5pkCGHgnr2RuGm6dJp3udp+Yd9F7FrG0buqvAZ8=` / `sha256-7+GcQXvtBV8taZCCSMa6ZQ+hNbyGiw5quz2hgdq2kKA=`). Copy into `/var/lib/private/wyoming/piper/`.
  - Whisper `small` = HF `Systran/faster-whisper-small` rev `536b0662742c02347bc0e980a01041f333bce120`. Files and hashes:
    - `config.json` `sha256-tVSWrHlAp65H0sAeq0Dt/YcB/uwSKdnM47QAFDg/uCg=`
    - `model.bin` `sha256-PjBZIVBtiHKBYCPkwnPnXSQZ+4myTal7T+e84UFw1nE=`
    - `tokenizer.json` `sha256-+3tjGR6bsEUILHn9dCoxBqEsmVE6sw30oNR/pstv0Ks=`
    - `vocabulary.txt` `sha256-NM4/4cUEECez+NQpEicJk/mG28S7NM8n+VHjSh5FORM=`

    Lay them out as an HF cache (`models--Systran--faster-whisper-small/{refs/main,snapshots/<rev>/…}`) in `/var/lib/private/wyoming/faster-whisper/`.
- **Container images:** without `imageFile` + `pull = "never"`, podman pulls at start and fails offline. With `dockerTools.pullImage` they load from the closure (proven on it-tools: the running image ID equals the archive config). Missing or wrong refs fail in about 2 s (`image not known`, `start-limit-hit`). Current `latest` digests (linux/amd64, `pullImage` hash):

| Container | Image | Digest | Version | Hash |
|---|---|---|---|---|
| dns | docker.io/technitium/dns-server | sha256:eb48ac5c135f4ab936b536f74f853d53e15ab39ef37fdbc9598a089b90d9f245 | 15.6.2 | sha256-JW8SmjVf60Hcr/KuD2f+MRIXvjPVOCJRTUEzjgzuIZ8= |
| fusion | ghcr.io/0x2e/fusion | sha256:67e39cd0023f1ff638be2ec5f601571fde63177d98cb55a9969cd7ed6704c686 | 1.3.0 | sha256-WauNOw0iJFmrgVUFkwfLRKM0AxFMCow75OFhHYjYmGM= |
| hass-mariadb | docker.io/library/mariadb | sha256:4844586367ef1b639ae699953e00a6a18f460f700e52df00401e1101a6ef2450 | 13.0.2 | sha256-Dn43oRWITQQx7n42I7eFk0uNgyT+OSLGcwg/9auWJOo= |
| it-tools | docker.io/corentinth/it-tools | sha256:8b8128748339583ca951af03dfe02a9a4d7363f61a216226fc28030731a5a61f | — | sha256-gcxH23woMw/uEXMVcXN+dJt6T7CKIu57NYmOZ+kZ7dU= |
| matrix-admin | docker.io/awesometechnologies/synapse-admin | sha256:a1c1f4662875f51ff1ca556a9eb7c802d9bc40ef58747b9efc163b42da3ad416 | 0.11.4 | sha256-WUt6WAtBRYqaaWu8Gg1CCUnSFO6kc+8ZXBGOzABM0GE= |
| mazanoke | ghcr.io/civilblur/mazanoke | sha256:ca83cddd90cd1e4b43102884bf39025731a1c7569f3bbda9d6530de72528cbab | v1.1.7 | sha256-hEx8DkflR50RIz1PrMvRCjq66uNu0imM6LR7fnS7ryo= |
| omni-tools | docker.io/iib0011/omni-tools | sha256:99e21d937dbe5ff86f00ac06ce17b5507a81911fa8d781f9b244b4067350e1a7 | — | sha256-EPOY72V3xXoQAH7RyRqJ03Xj5+J4rh2Ujj91E2UGjKw= |
| qbittorrent | lscr.io/linuxserver/qbittorrent | sha256:75ecbb1c89ab7b0a21c4bde40b4820e4f1649d2d56d83b91913422155e8d2a5f | 5.3.0_v2.1.2-ls485 | sha256-T/55dn3GNvc6IB2/6XKcLOdPhYsU/VVx0lQHNdTkgMM= |
| vert | ghcr.io/vert-sh/vert | sha256:51edb89e7c57197b0281ba8427fb27eea63730a3683b10d422061afab2708a49 | main | sha256-MFUuI68h7QaIAW6lYqY47WxCEhQLyh7okzXOkN37htU= |
| wallos | docker.io/bellamy/wallos | sha256:8873c2328e745c7ca8ff0e0f5508215219ec5c02a3469c0d8049602be2a2bca3 | 5.10.2 | sha256-FqA6pM7/nQQTrpiXXaD/O/50p8mswnlFSWcgtfM31KM= |

- **Size:** with everything up, the guest used about 5.5 GB RAM plus page cache, so `memorySize = 8192` and 4 cores are enough. The image archives total 3.3 GB. Boot until there are no pending jobs: about 2 minutes.

## Production problems found on the way

1. **Containers fail on a fresh host:** `/var/lib/containers/{dns,fusion,hass-mariadb,qbittorrent,wallos/*}` are bind-mount sources that nothing creates (`statfs …: no such file or directory`). Fix: add `systemd.tmpfiles.rules = [ "d <dir> :0755 :root :root -" ]` in each module (the `:` keeps existing dirs' owner and mode; plain `-` would reset them to root 0755 every boot).
2. **Dead Caddy route:** `jellyseer.laufin.xyz` → `192.168.2.50:5055` returns 502. Jellyseerr is no longer an Aigis service.
3. **Backup fails:** `restic-zfs-backup` lists `/var/lib/bazarr`. Bazarr was removed, so on a host without that dir, restic exits 3 and the unit fails.
4. **Images are unpinned (`latest`):** pinning means choosing digests. Check what Aigis actually runs first (`sudo podman images --digests`), especially MariaDB: `latest` is now 13.0.2.
5. **Open ports outside the firewall:** 443/udp (Caddy HTTP/3) and 7359/udp (Jellyfin discovery) listen but aren't opened. 53/udp and 6881/udp work only because podman DNAT bypasses the INPUT chain.
6. **Standalone `homeConfigurations."maksym@belial"` does not evaluate** (stylix options missing outside NixOS).
7. **Leaked secrets in this session:** `kavita_token_key` and `nix_cache_private_key` were printed during the investigation. Rotate both.
