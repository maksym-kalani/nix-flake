{pkgs, ...}: {
  home.packages = with pkgs; [
    coreutils
    htop
    zip
    pciutils
    jq
    btop
    git
  ];
  users.defaultUserShell = pkgs.zsh;
}
