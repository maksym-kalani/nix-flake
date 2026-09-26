{
  ...
}: {
  # Global sops-nix settings only. Declare each secret in the module that uses it.
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/maksym/.config/sops/age/keys.txt";
  };
}
