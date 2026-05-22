{
  config,
  ...
}:
{
  services.hermes-agent = {
    enable = true;
    settings.model.default = "openrouter/auto";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    addToSystemPackages = true;
  };
}
