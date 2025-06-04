{
  config,
  lib,
  pkgs,
  ...
}:
let
  sshdLoginScript = pkgs.writeShellScriptBin "sshd-login-ntfy" 
     ''
     #!/usr/bin/env bash
     #
     # sshd-login-ntfy
     #
     # Called by PAM (pam_exec) with PAM_TYPE=open_session or close_session.
     # Posts an ntfy notification to http://localhost:8081/homelab.
     
     NTFYURL="http://localhost:8081/homelab"
     
     # Use printf to build a THEORETICAL two-line payload—
     # this way there is no risk of a stray newline ending the quote too early.
     payload=$(printf "user: %s\nip/host: %s" "''${PAM_USER:-unknown}" "''${PAM_RHOST:-unknown}")
     
     case "''${PAM_TYPE}" in
       open_session)
         # Priority 5 (warning) on login
         curl -s \
              -H "Title: ''${HOSTNAME} — ssh login" \
              -H "Priority: 5" \
              -H "X-Tags: warning" \
              -d "$payload" \
              "''${NTFYURL}"
         exit 0
         ;;
       close_session)
         # Priority 1 (info) on logout
         curl -s \
              -H "Title: ''${HOSTNAME} — ssh logout" \
              -H "Priority: 1" \
              -d "$payload" \
              "''${NTFYURL}"
         exit 0
         ;;
       *)
         # If PAM_TYPE is not “open_session” or “close_session,” do nothing
         exit 0
         ;;
     esac
   '';
in
{
  environment.systemPackages = [sshdLoginScript];
  
  security.pam.services.sshd.text = lib.mkDefault (lib.mkAfter ''
    session   optional   ${config.security.pam.package}/lib/security/pam_exec.so ${sshdLoginScript}/bin/sshd-login-ntfy
  '');
}