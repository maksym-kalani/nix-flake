{ inputs, ... }:
{
  additions = final: _prev: import ../pkgs { pkgs = final; };

  modifications = _final: prev: {
    caddy = prev.caddy.overrideAttrs (_oldAttrs: rec {
      version = "2.9.1";
      vendorHash = "sha256-qrlpuqTnFn/9oMTMovswpS1eAI7P9gvesoMpsIWKcY8=";
      src = prev.fetchFromGitHub {
        owner = "caddyserver";
        repo = "caddy";
        tag = "v${version}";
        hash = "sha256-XW1cBW7mk/aO/3IPQK29s4a6ArSKjo7/64koJuzp07I=";
      };
      doCheck = false;
    });

    # nixpkgs bundles H2 1.4, which cannot read our H2 v2 database; drop once nixpkgs catches up.
    suwayomi-server = prev.suwayomi-server.overrideAttrs (_oldAttrs: rec {
      version = "2.4.2366";
      src = prev.fetchurl {
        url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v${version}/Suwayomi-Server-v${version}.jar";
        hash = "sha256-r5/rIK+dfr6eMHaebG68f8erHERziNQuAoCx2l/ge/0=";
      };
    });
  };

  # Opt-in pin for https://github.com/youwen5/zen-browser-flake/issues/22; drop once upstream releases download again.
  zen-browser-release-pin = _final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
      upstream = inputs.zen-browser.packages.${system};
      sources = {
        x86_64-linux = {
          url = "https://github.com/zen-browser/desktop/releases/download/1.23.2b/zen.linux-x86_64.tar.xz";
          hash = "sha256-Xmf0+ggbG0NyQ8RkRJ6hvSo7Fbb5Mkh6iqDCWqhRRgA=";
        };
        aarch64-linux = {
          url = "https://github.com/zen-browser/desktop/releases/download/1.23.2b/zen.linux-aarch64.tar.xz";
          hash = "sha256-lpcfCZwK3q5qLttOEoWW0HBt+XSsJ5tezeKqk7B2Idg=";
        };
      };
      unwrapped = upstream.zen-browser-unwrapped.override (sources.${system} // {
        version = "1.23.2b";
        firefoxVersion = "157.0.1";
      });
    in
    {
      zen-browser = upstream.default.override { zen-browser-unwrapped = unwrapped; };
    };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
