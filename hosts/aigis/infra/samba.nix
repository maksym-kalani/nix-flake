{
  services.samba-wsdd.enable = true;
  services.samba-wsdd.openFirewall = true;
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        security = "user";
        "server string" = "Aigis File Server";
        "map to guest" = "Bad User"; # shares set valid users, so guests still get nothing
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
