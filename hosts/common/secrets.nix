{ config, pkgs, ... }:

{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  
  sops.age.keyFile = "/home/maksym/.config/sops/age/keys.txt";
  
  sops.secrets.maksym_hashed_password = {
    sopsFile = ../../secrets/secrets.yaml;
    key = "maksym_hashed_password";
  };
}