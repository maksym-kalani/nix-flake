{ inputs, ... }: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev:
    {
      # example = prev.example.overrideAttrs (oldAttrs: rec {
      # ...
      # });
      caddy = prev.caddy.overrideAttrs (oldAttrs: rec {
        version = "2.9.1";
        
        src = prev.fetchFromGitHub {
          owner = "caddyserver";
          repo = "caddy";
          tag = "v${version}";
          hash = "sha256-VOPxBx0GvgidMXmt2UvVUTIT6yqF7HxeI4FT9+vk+pk=";
        };
      });
    };

  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
