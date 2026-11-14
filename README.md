# NixOS Flake Configuration

Reproducible NixOS configurations for a home server, a desktop workstation, and a self-hosted CI runner, managed with Nix Flakes. Home Manager configures the user environments on the server and desktop.

## Repository Structure

```
hosts/
  aigis/          # Home server
  belial/         # Gaming/productivity desktop
  ci-runner/      # Self-hosted GitHub Actions runner
  common/         # Shared aigis/belial configuration (users, secrets, overlays)
home/
  maksym/         # Per-host Home Manager entry points
  features/       # Reusable feature modules (cli, zsh, kitty, desktop)
  common/         # Shared Home Manager settings
overlays/         # Nixpkgs overlays (custom Caddy build, stable channel access)
pkgs/             # Custom package definitions
secrets/          # SOPS-encrypted secrets (age)
tests/            # NixOS VM tests
docs/             # Documentation
.github/          # CI workflow and Aigis change-detection scripts
```

## Hosts

All hosts use `nixos-unstable`; selected packages are available through the `nixos-26.05` stable overlay on aigis and belial. Each host's `system.stateVersion` is a compatibility setting, not its current NixOS release.

### aigis - Home Server

Home server with ZFS storage, self-hosted services running as native NixOS services and Podman containers, Caddy reverse proxy, WireGuard VPN, Samba file sharing, and Restic backups. Health monitored by Gatus with ntfy alerting.

### belial - Desktop Workstation

Gaming and productivity desktop with an AMD GPU, Hyprland compositor, Steam, and OBS Studio.

### ci-runner - GitHub Actions Runner

Dedicated x86_64-linux NixOS VM for this repository's self-hosted GitHub Actions jobs. Disko defines its GPT/ext4 disk layout, with GRUB configured for BIOS and UEFI boot. The runner uses ephemeral registration with a fresh workspace per job while retaining the Nix store as a build cache. KVM support enables the nested Aigis VM test.

This host has its own configuration and SOPS file (`secrets/ci-runner.yaml`) rather than importing `hosts/common` or Home Manager. The GitHub runner token is decrypted using its SSH host key. Weekly garbage collection removes Nix store paths older than 14 days.

## Home Manager Features

Reusable feature modules under `home/features/` composed per host:

- **CLI** (both hosts) — Common shell utilities and dev tools.
- **Zsh** (belial) — Shell configuration with Oh-My-Zsh, prompt theming, and fuzzy search.
- **Desktop** (belial) — Full Hyprland desktop environment with applications for development, communication, media, and productivity. Consistent theming across all components.

## CI and Tests

The [CI workflow](.github/workflows/ci.yml) runs on the self-hosted runner for same-repository pull requests targeting `develop`, or by manual dispatch. Fork pull requests are excluded from these jobs.

- **lint** checks Nix formatting and encryption of the production Aigis and VM-test secrets.
- **eval** evaluates the aigis and belial systems and standalone Home Manager configurations, runs `nix flake check --no-build`, and compares the Aigis system and VM-test derivations with the PR base.
- **aigis-vm** builds and runs the smoke test when those Aigis derivations change. Manual dispatch always runs it.

`tests/aigis` is a smoke test that boots the aigis configuration offline in a VM, with throwaway secrets and its pinned container images. It checks local Gatus endpoints and firewall access, Caddy routes, key-only SSH, and one Restic backup. Voice servers are excluded because their models download at runtime; SMART and health-monitor failures are allowed because the VM has no physical disks or ZFS pool. It checks that services start and answer, not that they work correctly.

```bash
nix build -L .#checks.x86_64-linux.aigis-vm
```

It needs KVM and about 9 GB of RAM, and the first run downloads about 3.3 GB of container images. `nix flake check` runs it too.

## Documentation

- [Installation Guide](docs/installation.md)
- [Secrets Management](docs/secrets.md)
- [WireGuard Setup](docs/wireguard.md)
- [ZFS Configuration](docs/zfs.md)
