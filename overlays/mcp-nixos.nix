{ stable }:
let
  pythonPackages = stable.python3Packages.overrideScope (
    _pythonFinal: pythonPrev: {
      fastmcp = pythonPrev.fastmcp.overridePythonAttrs (oldAttrs: {
        # Backport nixpkgs #580411 until it reaches the tracked stable input.
        patches = (oldAttrs.patches or [ ]) ++ [
          (stable.fetchpatch {
            url = "https://github.com/PrefectHQ/fastmcp/commit/ddcdf648131b51d605f133d13e5c942ea008ab28.patch";
            stripLen = 2;
            extraPrefix = "src/";
            hash = "sha256-A4dPqgneJRZ/TBbiZOzJTpmMFMQbS6HOaxgmtXkPJe0=";
          })
        ];
        postPatch = (oldAttrs.postPatch or "") + ''
          substituteInPlace src/fastmcp/server/providers/proxy.py \
            --replace-fail 'import base64' $'import anyio\nimport base64'
        '';
      });
    }
  );
in
(stable.mcp-nixos.override { python3Packages = pythonPackages; }).overridePythonAttrs
  (_oldAttrs: rec {
    version = "2.4.3";
    src = stable.fetchFromGitHub {
      owner = "utensils";
      repo = "mcp-nixos";
      tag = "v${version}";
      hash = "sha256-mWq9nnL4IGhUFkXJr8+t6BresOTDFS1caG8NuFqjrJg=";
    };
  })
