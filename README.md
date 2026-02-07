# NixOS Flake Configuration

Reproducible NixOS configurations for a home server and a desktop workstation, managed with Nix Flakes and Home Manager.

## Repository Structure

```
hosts/
  aigis/          # Home server
  belial/         # Gaming/productivity desktop
  common/         # Shared configuration (users, secrets, overlays)
home/
  maksym/         # Per-host Home Manager entry points
  features/       # Reusable feature modules (cli, zsh, kitty, desktop)
  common/         # Shared Home Manager settings
overlays/         # Nixpkgs overlays (custom Caddy build, stable channel access)
pkgs/             # Custom package definitions
secrets/          # SOPS-encrypted secrets (age)
docs/             # Documentation
```

## Hosts

### aigis - Home Server

NixOS 24.11 home server with ZFS storage, self-hosted services running as native NixOS services and Podman containers, Caddy reverse proxy, WireGuard VPN, Samba file sharing, and Restic backups. Health monitored by Gatus with ntfy alerting.

### belial - Desktop Workstation

NixOS 25.11 gaming and productivity desktop with an AMD GPU, Hyprland compositor, Steam, and OBS Studio.

## Home Manager Features

Reusable feature modules under `home/features/` composed per host:

- **CLI** (both hosts) — Common shell utilities and dev tools.
- **Zsh** (belial) — Shell configuration with Oh-My-Zsh, prompt theming, and fuzzy search.
- **Desktop** (belial) — Full Hyprland desktop environment with applications for development, communication, media, and productivity. Consistent theming across all components.

## Documentation

- [Installation Guide](docs/installation.md)
- [Secrets Management](docs/secrets.md)
- [WireGuard Setup](docs/wireguard.md)
- [ZFS Configuration](docs/zfs.md)
