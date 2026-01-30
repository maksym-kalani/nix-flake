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
    bat
  ];
  
  programs.git = {
    enable = true;
    userName = "maksym-kalani";
    userEmail = "kalanimaxim@gmail.com";
    extraConfig = {
        init.defaultBranch = "main";
    };
  };
}
