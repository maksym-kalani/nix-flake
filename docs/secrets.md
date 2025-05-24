## Editing Secrets
To edit the encrypted secrets file (), you can use the following command: `secrets.yaml`
``` bash
nix shell nixpkgs#sops -c sops secrets.yaml
```
This command:
1. Creates a temporary shell with SOPS installed from nixpkgs
2. Opens the file in the SOPS editor `secrets.yaml`
3. Automatically encrypts the file when you save and exit
