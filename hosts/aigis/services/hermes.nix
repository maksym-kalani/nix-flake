{
  config,
  pkgs,
  ...
}:
{
  services.hermes-agent = {
    enable = true;
    container.enable = true;
    container.hostUsers = [ "maksym" ];
    settings.model.default = "openrouter/auto";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    addToSystemPackages = true;
  };
}
