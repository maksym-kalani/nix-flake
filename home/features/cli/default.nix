{pkgs, ...}: {
  home.packages = with pkgs; [
    coreutils
    htop
    zip
  ];
}
