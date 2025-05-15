# NixOS Configuration Repository

This repository contains my personal NixOS configurations using the Nix Flakes system. It provides a modular and reproducible way to manage NixOS systems.

## Initial Setup After Fresh NixOS Installation

### Step 1: Configure Your Fresh NixOS Installation

After installing NixOS, you need to enable some essential settings before you can use this flake repository. Add the following to your `/etc/nixos/configuration.nix`:
```nix
services.openssh.enable = true;
nix.settings.experimental-features = [ "nix-command" "flakes" ];
nix.settings.trusted-users = [ "root" "maksym" ];
```

Apply these changes with:

```bash
sudo nixos-rebuild switch
```
### Step 2: Set Up SSH Access from Your Client Machine
On your client machine, generate SSH keys and set up the configuration:
``` bash
cd ~/.ssh
ssh-keygen -f maksym
ssh-copy-id -i ~/.ssh/maksym.pub maksym@192.168.1.55
nano ~/.ssh/config
```
Add this configuration to your SSH config file:
``` 
Host virtual
Hostname 192.168.1.55
User maksym
IdentityFile ~/.ssh/maksym
```
Now you can connect to your NixOS machine with:
``` bash
ssh virtual
```
### Step 3: Clone This Repository
``` bash
git clone https://github.com/yourusername/nixos-config.git
cd nixos-config
```
### Step 4: Validate the Configuration
``` bash
nix flake check --show-trace
```
### Step 5: Apply the Configuration
``` bash
nixos-rebuild switch --flake .#virtual --target-host virtual --use-remote-sudo
```