{
  config,
  ...
}:
{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/maksym/.config/sops/age/keys.txt";

    secrets = {
      eklesa_hashed_password = {
        key = "eklesa_hashed_password";
      };
      namecheap_api_user = {
        key = "namecheap_api_user";
        owner = "caddy";
      };
      namecheap_api_key = {
        key = "namecheap_api_key";
        owner = "caddy";
      };
      openai_api_key = {
        key = "openai_api_key";
      };
      flame_homepage_password = {
        key = "flame_homepage_password";
      };
      hass_mariadb_root_password = {
        key = "hass_mariadb_root_password";
      };
      hass_mariadb_password = {
        key = "hass_mariadb_password";
      };
      restic_repo = {
        key = "restic_repo";
      };
      restic_password = {
        key = "restic_password";
      };
      minio = {
        key = "minio";
      };
    };
  };
}
