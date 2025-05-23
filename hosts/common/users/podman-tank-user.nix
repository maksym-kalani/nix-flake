{
  config,
  pkgs,
  inputs,
  ...
}: {
  users.users.podman-tank-user = {
    isNormalUser = true;
    extraGroups = [ "podman" "tankusers" ];
    description  = "Runs rootless Podman containers";
    # omit initialPassword for manual `passwd alice`
  };
}