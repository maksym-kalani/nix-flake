{
  config,
  pkgs,
  inputs,
  ...
}: {
  users.users.eklesa = {
    isNormalUser = true;
    description = "Eklesa (SMB user)";
    hashedPasswordFile = config.sops.secrets.eklesa_hashed_password.path;
    extraGroups = ["wheel" "tankusers"];
  };
}
