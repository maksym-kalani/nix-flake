{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = _final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
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

    # nixpkgs 2.1.1867 bundles H2 1.4.200, which cannot read the database
    # already migrated to the H2 v2 format by the previously-run upstream
    # stable container (>= v2.3). Track upstream stable until nixpkgs catches up.
    suwayomi-server = prev.suwayomi-server.overrideAttrs (_oldAttrs: rec {
      version = "2.3.2243";
      src = prev.fetchurl {
        url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v${version}/Suwayomi-Server-v${version}.jar";
        hash = "sha256-ghFBsy4XDUoC08vf7Vd+2PB70iOD/19BMuu1rkDpjdU=";
      };
    });
  };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
