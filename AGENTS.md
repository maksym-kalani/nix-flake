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

Services include: bazarr, fusion, hass-mariadb, immich, it-tools, jellyfin, jellyseerr, karakeep, kavita, kiwix, local-content-share, local-voice (piper + whisper), matrix-admin, mazanoke, ntfy, omni-tools, prowlarr, qbittorrent, radarr, searxng, sonarr, stirling-pdf, suwayomi, technitium-dns, vert, vikunja, wallos.

A shared `hosts/aigis/lib/monitored-app.nix` helper generates the Flame dashboard tile and Gatus health-check endpoint for a service from one call (see any service file's `imports` for the pattern); both templates use it too.

Common service patterns:

- Firewall port configuration
- Gatus health check endpoint with ntfy alerting
- Caddy reverse proxy configured centrally in `hosts/aigis/infra/caddy.nix` for `*.laufin.xyz` domain

### Aigis Infrastructure (`hosts/aigis/infra/`)

Caddy, Flame homepage, Gatus, Podman, Restic backup, Samba, SSH, WireGuard, ZFS, ntfy-on-ssh notifications.

### Aigis Health Monitoring (`hosts/aigis/health/`)

Health monitor, smartd, ZFS logging.

### Secrets Management

Uses sops-nix with age encryption. Global sops settings live in `hosts/common/secrets.nix`; each secret is declared (`sops.secrets.<name>`) in the module that consumes it. Values are stored in `secrets/secrets.yaml`. List all declared secrets with `nix eval .#nixosConfigurations.<host>.config.sops.secrets --apply builtins.attrNames`. Age key located at `/home/maksym/.config/sops/age/keys.txt`.

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
- Only write a local patch when those options fail, and keep it minimal.

### Always validate with eval

- After every Nix change, run a matching `nix eval` against the exact target output before claiming success.
- Preferred eval targets:
- NixOS: `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
- Home Manager: `nix eval .#homeConfigurations.<config>.activationPackage.drvPath`
- When practical, follow eval with the matching dry-run/build/test command. Eval is the minimum bar, not the whole test plan.

### Keep comments short

- Comment only what the code cannot say, usually the why, in one short line. No multi-line comments, file headers or comments that restate the code.

### Run the aigis VM test

- A change that alters the built aigis system or the test (services, ports, secrets, images, packages; not comments, formatting or docs) must pass `nix build -L .#checks.x86_64-linux.aigis-vm` before the work is called done. Report a failure with its output; do not call the work done.
- Update `tests/aigis/` in the same change when needed. A new service is usually covered automatically through its Gatus endpoint and Caddy route. A new secret needs a test value in `tests/aigis/secrets.yaml`, and a new host path needs a stand-in in the test's tmpfiles. A changed image digest needs its new hash in `tests/aigis/images.nix`.
- Fix the config, not the test. Only weaken a check or add to its allowed-failures list when the failure comes from the VM itself, and say so in a comment.
