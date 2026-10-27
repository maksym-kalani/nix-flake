{
  lib,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    ./users
    ./secrets.nix
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs; };
    backupFileExtension = "bak";
  };
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "maksym"
      ];
      nix-path = [ "/etc/nix/path" ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
    registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
      (lib.filterAttrs (_: lib.isType "flake")) inputs
    );
  };

  environment.interactiveShellInit = ''
    alias sstop='sudo systemctl stop'
    alias sstart='sudo systemctl start'
    alias srestart='sudo systemctl restart'
    alias sstatus='sudo systemctl status'
  '';
}
