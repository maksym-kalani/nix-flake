{
  services.samba-wsdd.enable = true;
  services.samba-wsdd.openFirewall = true;
  services.samba = {
    enable = true;
    openFirewall = true;  # open SMB ports if firewall is enabled
    # Samba server settings
    settings = {
      global = {
        workgroup = "WORKGROUP";
        security = "user";
        "server string" = "Aigis File Server";
        "map to guest" = "Bad User";    # Unauthenticated users treated as guest
        # (We will require login, so guest access is disabled on shares)
      };
      "appdata" = {
        path = "/mnt/tank/appdata";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "maksym";
        "force group" = "tankusers";
        "create mask" = "0660";
        "directory mask" = "0770";
      };
      "downloads" = {
        path = "/mnt/tank/downloads";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "maksym eklesa";
        "force group" = "tankusers";
        "create mask" = "0660";
        "directory mask" = "0770";
      };
      "media" = {
        path = "/mnt/tank/media";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "maksym";
        "force group" = "tankusers";
        "create mask" = "0660";
        "directory mask" = "0770";
      };
      "users" = {
        path = "/mnt/tank/users";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "maksym eklesa";
        "force group" = "tankusers";
        "create mask" = "0660";
        "directory mask" = "0770";
      };
      "hass-backups" = {
        path = "/mnt/tank/users/maksym/backups/hass";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "maksym";
        "force group" = "tankusers";
        "create mask" = "0660";
        "directory mask" = "0770";
      };
    };
  };
}