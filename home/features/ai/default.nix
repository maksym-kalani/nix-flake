{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rtk
    nodejs
    pi-coding-agent
  ];

  programs.claude-code = {
    enable = true;

    plugins = [
      (pkgs.fetchFromGitHub {
        owner = "affaan-m";
        repo = "ECC";
        rev = "1e8c7e7994223e0ff337d1626cd08e04a1ae67ed";
        sha256 = "0fpj9rb8yhmqqfnz9qan6p2hxdg3rmx1ja3sy8pxv63c5bfi7icr";
      })
      (pkgs.fetchFromGitHub {
        owner = "Aaronontheweb";
        repo = "dotnet-skills";
        rev = "316756fb309b9ee42d86d5db0d70504d62f3b0c3";
        sha256 = "00vgspf1p7kl5wp5jbk014kcakhm1ykibihvg7l5wy1bps1cligh";
      })
      (pkgs.fetchFromGitHub {
        owner = "multica-ai";
        repo = "andrej-karpathy-skills";
        rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
        sha256 = "0xljnr058v7y0v1gwnq13nkmpk635i6ja4azrk8lbv87sr2z0gz3";
      })
    ];

    settings = {
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
            }
          ];
        }
      ];
    };
  };
}
