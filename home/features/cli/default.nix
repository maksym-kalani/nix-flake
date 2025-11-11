{pkgs, ...}: {
  home.packages = with pkgs; [
    coreutils
    htop
    zip
    pciutils
    jq
  ];
  
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      alias sstop='sudo systemctl stop'
      alias sstart='sudo systemctl start'
      alias srestart='sudo systemctl restart'
      alias sstatus='sudo systemctl status'
    '';
  };
}
