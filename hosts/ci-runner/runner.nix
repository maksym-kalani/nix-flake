{ config, ... }:
{
  # own secrets file, so this host cannot decrypt aigis secrets
  sops = {
    defaultSopsFile = ../../secrets/ci-runner.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets.github_runner_token = { };
  };

  services.github-runners.ci-runner = {
    enable = true;
    url = "https://github.com/maksym-kalani/nix-flake";
    tokenFile = config.sops.secrets.github_runner_token.path;
    ephemeral = true; # fresh workspace per job; the nix store stays as the cache
    replace = true;
  };

  nix = {
    settings = {
      system-features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      min-free = 10 * 1024 * 1024 * 1024;
      max-free = 40 * 1024 * 1024 * 1024;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
