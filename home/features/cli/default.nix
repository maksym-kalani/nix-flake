{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    initExtra = ''
      ns() { nix shell "''${@/#/nixpkgs#}"; }
    '';
  };

  home.shellAliases = {
    # General
    c = "clear";
    shutdown = "systemctl poweroff";
    v = "$EDITOR";
    vim = "$EDITOR";

    # Git
    g = "git";
    gs = "git status";
    gd = "git diff";
    gc = "git commit";
    gp = "git push";
    gl = "git log --oneline";

    # System
    update-grub = "sudo grub-mkconfig -o /boot/grub/grub.cfg";
  };

  home.packages = with pkgs; [
    coreutils
    htop
    zip
    pciutils
    jq
    btop
    git
    gh
    bat
    (pkgs.writeScriptBin "ex" /* bash */ ''
      #!/usr/bin/env bash
      if [ -f "$1" ] ; then
         case "$1" in
           *.tar.bz2)   ${pkgs.gnutar}/bin/tar xjf "$1"   ;;
           *.tar.gz)    ${pkgs.gnutar}/bin/tar xzf "$1"   ;;
           *.bz2)       ${pkgs.bzip2}/bin/bunzip2 "$1"   ;;
           *.rar)       ${pkgs.unrar}/bin/unrar x "$1"     ;;
           *.gz)        ${pkgs.gzip}/bin/gunzip "$1"    ;;
           *.tar)       ${pkgs.gnutar}/bin/tar xf "$1"    ;;
           *.tbz2)      ${pkgs.gnutar}/bin/tar xjf "$1"   ;;
           *.tgz)       ${pkgs.gnutar}/bin/tar xzf "$1"   ;;
           *.zip)       ${pkgs.unzip}/bin/unzip "$1"     ;;
           *.Z)         uncompress "$1";;
           *.7z)        ${pkgs.p7zip}/bin/7z x "$1"      ;;
           *.tar.xz)    ${pkgs.gnutar}/bin/tar -xf "$1"   ;;
           *)           printf "\033[1;31m[✗] \033[1;33m'$1' \033[0mcannot be extracted via ex()\033[0m" ;;
         esac
           else
             echo "'$1' is not a valid file"
      fi
    '')
  ];

  programs.git = {
    enable = true;
    signing.format = "openpgp";
    settings = {
      user = {
        email = "kalanimaxim@gmail.com";
        name = "Maksym Kalani";
        init.defaultBranch = "main";
        credential.helper = "!gh auth git-credential";
      };
    };
  };

}
