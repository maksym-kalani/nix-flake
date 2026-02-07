## Editing Secrets
To edit the encrypted secrets file (), you can use the following command:
``` bash
nix shell nixpkgs#sops -c sops secrets.yaml
```
This command:
1. Creates a temporary shell with SOPS installed from nixpkgs
2. Opens the file in the SOPS editor `secrets.yaml`
3. Automatically encrypts the file when you save and exit

It requires the key to be placed in the `~/.config/sops/age/keys.txt` file.
