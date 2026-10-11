# Use Aigis' LAN binary cache (hosts/aigis/infra/nix-cache.nix).
# Merged with the default cache.nixos.org substituter/key, which stay in place.
{
  nix.settings = {
    substituters = ["http://192.168.2.50:5757"];
    trusted-public-keys = ["aigis-cache-1:GzbUfqI4iVQwfw/bl0+zyU1Qak0GF4MnJ9PHSMKUtGs="];
  };
}
