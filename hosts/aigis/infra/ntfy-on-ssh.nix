{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshdLoginScript = pkgs.writeShellScriptBin "sshd-login-ntfy" ''
    #!/usr/bin/env bash
    NTFYURL="http://localhost:8081/homelab"

    # printf so no stray newline can end the quote early
    payload=$(printf "user: %s\nip/host: %s" "''${PAM_USER:-unknown}" "''${PAM_RHOST:-unknown}")

    case "''${PAM_TYPE}" in
      open_session)
        curl -s \
             -H "Title: ''${HOSTNAME} — ssh login" \
             -H "Priority: 3" \
             -H "X-Tags: warning" \
             -d "$payload" \
             "''${NTFYURL}"
        exit 0
        ;;
      close_session)
        curl -s \
             -H "Title: ''${HOSTNAME} — ssh logout" \
             -H "Priority: 1" \
             -d "$payload" \
             "''${NTFYURL}"
        exit 0
        ;;
      *)
        exit 0
        ;;
    esac
  '';
in
{
  environment.systemPackages = [ sshdLoginScript ];

  security.pam.services.sshd.text = lib.mkDefault (
    lib.mkAfter ''
      session   optional   ${config.security.pam.package}/lib/security/pam_exec.so ${sshdLoginScript}/bin/sshd-login-ntfy
    ''
  );
}
