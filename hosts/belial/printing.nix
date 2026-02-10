{pkgs, ...}: {
  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
      pkgs.gutenprintBin
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
