{
  imports = [
    ../common
    ./configuration.nix
    ./infra
    ./services
    ./health
    ./secrets.nix
    ./users
    ./packages.nix
  ];
}
