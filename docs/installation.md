# Installation Guide

Setup steps for deploying this flake on a fresh NixOS installation. SSH and SOPS age keys are stored in the password manager.

## 1. Prepare the Fresh NixOS Host

Add the following to `/etc/nixos/configuration.nix` on the target machine:

```nix
services.openssh.enable = true;
nix.settings.experimental-features = [ "nix-command" "flakes" ];
nix.settings.trusted-users = [ "root" "maksym" ];
```

Apply:

```bash
sudo nixos-rebuild switch
```

## 2. Place Secrets on the Target Machine

### SSH Key

Copy the private key `maksym` from the password manager to `~/.ssh/maksym` on the target machine, then fix permissions:

```bash
chmod 600 ~/.ssh/maksym
```

### SOPS Age Key

Create the directory and paste the age secret key from the password manager:

```bash
mkdir -p ~/.config/sops/age
```

Save the key to `~/.config/sops/age/keys.txt`. This is the private key  required by sops-nix to decrypt `secrets/secrets.yaml` at build time.

## 3. Configure SSH on the Client Machine

Add the host to `~/.ssh/config`:

```
Host aigis
Hostname <host-ip>
User maksym
IdentityFile ~/.ssh/maksym
```

## 4. Clone and Deploy

```bash
git clone https://github.com/yourusername/nixos-config.git
cd nixos-config
nix flake check --show-trace
```

Local rebuild:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

Remote deployment from the client:

```bash
nixos-rebuild switch --flake .#<host> --target-host <host> --use-remote-sudo
```
