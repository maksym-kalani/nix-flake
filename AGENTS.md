# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Overview

This is a NixOS Flake configuration repository managing multiple hosts with Home Manager integration. It configures a home server ("aigis") running various self-hosted services via Podman containers, and a desktop workstation ("belial") with Hyprland, gaming, and Stylix theming.

## Common Commands

```bash
# Validate the flake configuration
nix flake check --show-trace

# Rebuild and switch to new configuration (from the repo directory)
sudo nixos-rebuild switch --flake .#aigis
sudo nixos-rebuild switch --flake .#belial

# Shell aliases available on the system
rebuild    # sudo nixos-rebuild switch --flake .#aigis
sstop      # sudo systemctl stop
sstart     # sudo systemctl start
srestart   # sudo systemctl restart
sstatus    # sudo systemctl status
```

## Architecture

### Hosts

- **aigis**: Home server with ZFS storage, Podman containers, and self-hosted services
- **belial**: Desktop workstation with Hyprland, Stylix theming, gaming (Steam), OBS, Zen browser

### Key Directory Structure

- `hosts/<hostname>/` - Host-specific NixOS configuration
- `hosts/common/` - Shared configuration for all hosts (users, secrets, overlays)
- `home/maksym/` - Home Manager configurations per host (`aigis.nix`, `belial.nix`, `home.nix`)
- `overlays/` - Nixpkgs overlays (custom packages, modifications, stable channel access)
- `pkgs/` - Custom package definitions
- `secrets/` - SOPS-encrypted secrets (age encryption)

### Aigis Services

Services live in `hosts/aigis/services/` as individual `.nix` files. Templates are in `hosts/aigis/templates/`:

- `templates/app.nix` - Template for native NixOS services
- `templates/container.nix` - Template for OCI/Podman container services

Services include: bazarr, flame-homepage, fusion, gatus, hass-mariadb, immich, it-tools, jellyfin, jellyseerr, karakeep, kavita, kiwix, local-content-share, local-voice (piper + whisper), matrix-admin, mazanoke, morphos, ntfy, omni-tools, prowlarr, qbittorrent, radarr, recommendarr, searxng, sonarr, stirling-pdf, tachidesk, technitium-dns, vikunja, wallos.

Common service patterns:

- Firewall port configuration
- Gatus health check endpoint with ntfy alerting
- Caddy reverse proxy configured centrally in `hosts/aigis/infra/caddy.nix` for `*.laufin.xyz` domain

### Aigis Infrastructure (`hosts/aigis/infra/`)

Caddy, Podman, Restic backup, Samba, SSH, WireGuard, ZFS, ntfy-on-ssh notifications.

### Aigis Health Monitoring (`hosts/aigis/health/`)

Health monitor, smartd, ZFS logging.

### Secrets Management

Uses sops-nix with age encryption. Secrets defined in `hosts/common/secrets.nix` and stored in `secrets/secrets.yaml`. Age key located at `/home/maksym/.config/sops/age/keys.txt`.

### Flake Inputs

- `nixpkgs` (unstable) and `nixpkgs-stable` (25.11)
- `home-manager` for user environment management
- `sops-nix` for secrets encryption
- `caddy-nix` for Caddy with custom plugins
- `zen-browser` for Zen browser flake
- `stylix` for system-wide theming (belial)
- `vicinae` for vicinae integration

### Overlays

Access stable packages via `pkgs.stable.<package>`. Custom Caddy build with namecheap DNS plugin is defined in overlays.

## Workflow Rules

### Verify the target first

- Before making changes, identify the exact target config and the machine/OS required to validate it.
- Do not assume the edited path name matches the flake output or the machine that must run the verification command.
- State this explicitly before editing: `Target config: <name>. Validation host: <machine/OS>. Planned verification: <command>.`

### Prefer upstream fixes

- If an issue appears to come from upstream, first check whether it is already fixed upstream.
- Update the relevant flake input or `flake.lock` first.
- If the fix is not in the pinned version, prefer an upstream PR commit or a commit already merged upstream before writing a local patch.
- Only write a local patch when those options fail. Keep it minimal and put it in a separate file named `{package}-patch-{fix-reason}.nix`.

### Always validate with eval

- After every Nix change, run a matching `nix eval` against the exact target output before claiming success.
- Preferred eval targets:
- NixOS: `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
- Home Manager: `nix eval .#homeConfigurations.<config>.activationPackage.drvPath`
- When practical, follow eval with the matching dry-run/build/test command. Eval is the minimum bar, not the whole test plan.
