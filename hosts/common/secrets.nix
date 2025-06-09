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
      eklesa_hashed_password = {
        key = "eklesa_hashed_password";
      };
      namecheap_api_user = {
        key = "namecheap_api_user";
      };
      namecheap_api_key = {
        key = "namecheap_api_key";
      };
      openai_api_key = {
        key = "openai_api_key";
      };
      flame_homepage_password = {
        key = "flame_homepage_password";
      };
      # Add more secrets here
    };
  };
}