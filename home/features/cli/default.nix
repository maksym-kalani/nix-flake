{pkgs, ...}: {
  home.packages = with pkgs; [
    coreutils
    htop
    zip
    pciutils
    jq
    btop
    git
    gh
    fastfetch
  ];
}
