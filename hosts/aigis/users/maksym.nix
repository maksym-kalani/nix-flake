{ ... }:
{
  users.users.maksym = {
    extraGroups = [
      "tankusers"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEqvyzijm/T8BlLQS8EXtZ30aZBFeK0Of4FzPlzkFS8 maksym"
    ];
  };
  environment.interactiveShellInit = ''
    alias rebuild='sudo nixos-rebuild switch --flake .#aigis'
    alias zfs-users='sudo fuser -vm /mnt/tank'
  '';
}
