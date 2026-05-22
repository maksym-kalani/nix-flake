{
  config,
  pkgs,
  ...
}:
{
  services.hermes-agent = {
    enable = true;
    container = {
      enable = true;
      image = "ubuntu:24.04";
      backend = "podman";
      hostUsers = [ "maksym" ];
      extraOptions = [
        "--gpus"
        "all"
      ];
    };
    settings.model.default = "openrouter/auto";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    addToSystemPackages = true;
  };
}
