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
    };
    settings.model.default = "openrouter/auto";
    environmentFiles = [ config.sops.secrets."hermes-env".path ];
    addToSystemPackages = true;
  };

  security.sudo.extraRules = [
    {
      users = [ "maksym" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/podman";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
