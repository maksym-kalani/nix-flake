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
    (pkgs.writeScriptBin "ex"
      /*
      bash
      */
      ''
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

  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "small",
        "padding": {
          "top": 4
        }
      },
      "display": {
        "separator": " "
      },
      "modules": [
        {
            "key": "╭───────────╮",
            "type": "custom"
        },
        {
            "key": "│ {#31} user    {#keys}│",
            "type": "title",
            "format": "{user-name}"
        },
        {
            "key": "│ {#32}󰇅 hname   {#keys}│",
            "type": "title",
            "format": "{host-name}"
        },
        {
            "key": "│ {#33}󰅐 uptime  {#keys}│",
            "type": "uptime"
        },
        {
            "key": "│ {#34}{icon} distro  {#keys}│",
            "type": "os"
        },
        {
            "key": "│ {#35} kernel  {#keys}│",
            "type": "kernel"
        },
        {
            "key": "│ {#36} wm      {#keys}│",
            "type": "wm"
        },
        {
            "key": "│ {#36}󰇄 desktop {#keys}│",
            "type": "de"
        },
        {
            "key": "│ {#31} term    {#keys}│",
            "type": "terminal"
        },
        {
            "key": "│ {#32} shell   {#keys}│",
            "type": "shell"
        },
        {
            "key": "│ {#33}󰍛 cpu     {#keys}│",
            "type": "cpu",
            "showPeCoreCount": true
        },
        {
            "key": "│ {#34}󰉉 disk    {#keys}│",
            "type": "disk",
            "folders": "/"
        },
        {
            "key": "│ {#36} memory  {#keys}│",
            "type": "memory"
        },
        {
            "key": "├───────────┤",
            "type": "custom"
        },
        {
            "key": "│ {#39} colors  {#keys}│",
            "type": "colors",
            "symbol": "circle"
        },
        {
            "key": "╰───────────╯",
            "type": "custom"
        }
      ]
    }
  '';
}
