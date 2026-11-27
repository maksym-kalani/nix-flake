{ inputs, ... }:
{
  additions = final: _prev: import ../pkgs { pkgs = final; };

  modifications = final: prev: {
    # nixpkgs bundles H2 1.4; drop once nixpkgs catches up.
    suwayomi-server = prev.suwayomi-server.overrideAttrs (_oldAttrs: rec {
      version = "2.4.2373";
      src = prev.fetchurl {
        url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v${version}/Suwayomi-Server-v${version}.jar";
        hash = "sha256-3QXVI8x4W3rPkMn+rAvITFPV+zr1qyozZTZG4gduUhc=";
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
