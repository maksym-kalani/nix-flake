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
    settings = {
      user = {
        email = "kalanimaxim@gmail.com";
        name = "Maksym Kalani";
        init.defaultBranch = "main";
      };
    };
  };
}
