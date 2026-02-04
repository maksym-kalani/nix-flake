{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    history = {
      size = 10000;
      save = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      append = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "web-search"
        "copyfile"
        "copybuffer"
        "dirhistory"
      ];
    };

    shellAliases = {
      # General
      c = "clear";
      nf = "fastfetch";
      pf = "fastfetch";
      ff = "fastfetch";
      ls = "eza -a --icons=always";
      ll = "eza -al --icons=always";
      lt = "eza -a --tree --level=1 --icons=always";
      shutdown = "systemctl poweroff";
      v = "$EDITOR";
      vim = "$EDITOR";
      wifi = "nmtui";

      # Git
      g = "git";
      gs = "git status";
      gd = "git diff";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline";

      # System
      update-grub = "sudo grub-mkconfig -o /boot/grub/grub.cfg";

      # SSH
      aigis = "kitten ssh aigis";
    };

    sessionVariables = {
      EDITOR = "nvim";
    };

    initContent = ''
      # FZF key bindings
      source <(fzf --zsh)

      # Oh-my-posh prompt
      eval "$(oh-my-posh init zsh --config ${./themes/di4am0nd.omp.json})"

      # Fastfetch on terminal start
      if [[ $(tty) == *"pts"* ]]; then
        fastfetch
      fi
    '';
  };

  # Additional PATH entries
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
  ];

  # Required packages
  home.packages = with pkgs; [
    eza
    fzf
    fastfetch
    oh-my-posh
    neovim
  ];
}
