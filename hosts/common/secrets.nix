{ config, pkgs, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/maksym/.config/sops/age/keys.txt";

    secrets = {
      maksym_hashed_password = {
        key = "maksym_hashed_password";
      };

      # SSH key for aigis connection
      ssh_private_key_aigis = {
        owner = "maksym";
        group = "users";
        mode = "0600";
        path = "/home/maksym/.ssh/maksym-aigis";
      };
      ssh_public_key_aigis = {
        owner = "maksym";
        group = "users";
        mode = "0644";
        path = "/home/maksym/.ssh/maksym-aigis.pub";
      };
    };
  };
}