{
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
      searxng_secret_key = {
        key = "searxng_secret_key";
        owner = "searx";
      };
      flame_homepage_password = {
        key = "flame_homepage_password";
      };
      kavita_token_key = {
        key = "kavita_token_key";
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
      hermes-env = {
        key = "hermes-env";
      };
      trek_encryption_key = {
        key = "trek_encryption_key";
      };
    };
  };
}
