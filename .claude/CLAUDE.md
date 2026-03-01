# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS Flake configuration repository managing multiple hosts with Home Manager integration. It configures a home server ("aigis") running various self-hosted services via both native NixOS services and Podman containers.

## Common Commands

```bash
# Validate the flake configuration
nix flake check --show-trace

# Rebuild and switch to new configuration (from the repo directory)
sudo nixos-rebuild switch --flake .#aigis

# Remote deployment to a host
nixos-rebuild switch --flake .#virtual --target-host virtual --use-remote-sudo

# Shell aliases available on the system
rebuild    # sudo nixos-rebuild switch --flake .#aigis
sstop      # sudo systemctl stop
sstart     # sudo systemctl start
srestart   # sudo systemctl restart
sstatus    # sudo systemctl status
```

## Architecture

### Hosts
- **aigis**: Main home server with ZFS storage, Podman containers, and self-hosted services
- **virtual**: VM configuration for testing

### Key Directory Structure
- `hosts/<hostname>/` - Host-specific NixOS configuration
- `hosts/common/` - Shared configuration for all hosts (users, secrets, overlays)
- `home/maksym/` - Home Manager configurations per host
- `overlays/` - Nixpkgs overlays (custom packages, modifications, stable channel access)
- `pkgs/` - Custom package definitions
- `secrets/` - SOPS-encrypted secrets (age encryption)

### Service Patterns

**Native NixOS Services** (`hosts/aigis/services/apps/`):
- Template at `template.nix` - defines port, firewall rules, Gatus monitoring endpoint, and Caddy reverse proxy

**Container Services** (`hosts/aigis/services/containers/`):
- Template at `template.nix` - OCI container definition with port mapping, volumes, environment variables, Gatus monitoring, and Caddy reverse proxy
- Uses `virtualisation.oci-containers.containers` for Podman containers
- Container data stored at `/mnt/tank/appdata/<service-name>/`

Both patterns include:
- Firewall port configuration
- Gatus health check endpoint with ntfy alerting
- Caddy virtual host for reverse proxy on `*.laufin.xyz` domain

### Secrets Management
Uses sops-nix with age encryption. Secrets defined in `hosts/common/secrets.nix` and stored in `secrets/secrets.yaml`. Age key located at `/home/maksym/.config/sops/age/keys.txt`.

### Flake Inputs
- `nixpkgs` (unstable) and `nixpkgs-stable` (25.11)
- `home-manager` for user environment management
- `sops-nix` for secrets encryption
- `caddy-nix` for Caddy with custom plugins

### Overlays
Access stable packages via `pkgs.stable.<package>`. Custom Caddy build with namecheap DNS plugin is defined in overlays.
