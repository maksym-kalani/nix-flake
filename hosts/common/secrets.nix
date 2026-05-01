{
  ...
}: {
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/maksym/.config/sops/age/keys.txt";

    secrets = {
      maksym_hashed_password = {
        key = "maksym_hashed_password";
      };
    };
  };
}
