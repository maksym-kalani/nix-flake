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

  xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = {
      type = "auto";
      padding = {
        top = 2;
        left = 2;
        right = 3;
      };
    };
    display = {
      separator = "  ";
    };
    modules = [
      { type = "custom"; key = "╭──────────────╮"; }
      { type = "title"; key = "│ {#31}  {#keys}user    │"; format = "{user-name}"; }
      { type = "title"; key = "│ {#32}󰇅  {#keys}host    │"; format = "{host-name}"; }
      { type = "uptime"; key = "│ {#33}󰅐  {#keys}uptime  │"; }
      { type = "os"; key = "│ {#34}  {#keys}distro  │"; }
      { type = "kernel"; key = "│ {#35}  {#keys}kernel  │"; }
      { type = "wm"; key = "│ {#36}  {#keys}wm      │"; }
      { type = "terminal"; key = "│ {#31}  {#keys}term    │"; }
      { type = "shell"; key = "│ {#32}  {#keys}shell   │"; }
      { type = "cpu"; key = "│ {#33}󰍛  {#keys}cpu     │"; showPeCoreCount = true; }
      { type = "disk"; key = "│ {#34}󰉉  {#keys}disk    │"; folders = "/"; }
      { type = "memory"; key = "│ {#35}  {#keys}memory  │"; }
      { type = "custom"; key = "├──────────────┤"; }
      { type = "colors"; key = "│ {#39}  {#keys}colors  │"; symbol = "circle"; }
      { type = "custom"; key = "╰──────────────╯"; }
    ];
  };
}
