{
  inputs,
  pkgs,
  ...
}: let
  notify = pkgs.writeShellScript "comin-ntfy" ''
    case "$COMIN_PHASE/$COMIN_STATUS" in
      deploy/done) priority=2 title="deployed" tag=white_check_mark ;;
      deploy/failed | build/failed) priority=4 title="$COMIN_PHASE failed" tag=x ;;
      *) exit 0 ;;
    esac
    ${pkgs.curl}/bin/curl -s \
      -H "Title: aigis comin $title" \
      -H "Priority: $priority" \
      -H "Tags: $tag" \
      -d "''${COMIN_GIT_SHA:0:7} $COMIN_GIT_REF: $COMIN_GIT_MSG $COMIN_ERROR_MSG" \
      http://localhost:8081/homelab || true
  '';
in {
  imports = [inputs.comin.nixosModules.comin];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/maksym-kalani/nix-flake.git";
        branches.main.name = "develop";
      }
    ];
    postDeploymentCommand = notify;
    postBuildCommand = notify;
  };
}
