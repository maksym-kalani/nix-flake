{ inputs, ... }:
{
  additions = final: _prev: import ../pkgs { pkgs = final; };

  modifications = final: prev: {
    # Nix 2.35 removed the Perl bindings used by nix-serve.
    nix-serve = (prev.nix-serve.override { nix = prev.nixVersions.nix_2_34; }).overrideAttrs (_old: {
      version = "0.2-a7e046d";
      src = prev.fetchFromGitHub {
        owner = "edolstra";
        repo = "nix-serve";
        rev = "a7e046db4b29d422fc9aac60ea6b82b31399951a";
        hash = "sha256-6ZQ0OLijq6UtOtUqRdFC19+helhU0Av6MvGCZf6XmcQ=";
      };
    });

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

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
