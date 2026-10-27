{
  nix.settings = {
    substituters = [ "http://192.168.2.50:5757" ]; # merged with the default cache.nixos.org substituter
    trusted-public-keys = [ "aigis-cache-1:GzbUfqI4iVQwfw/bl0+zyU1Qak0GF4MnJ9PHSMKUtGs=" ];
  };
}
