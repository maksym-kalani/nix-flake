{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        IdentityFile = "~/.ssh/maksym";
        IdentitiesOnly = true;
      };
      aigis = {
        HostName = "192.168.2.50";
        User = "maksym";
      };
      ci-runner = {
        HostName = "192.168.2.51";
        User = "maksym";
      };
      "github.com".User = "git";
      hetzner = {
        HostName = "u470428.your-storagebox.de";
        Port = 23;
        User = "u470428";
      };
      morgana = {
        HostName = "192.168.2.20";
        User = "root";
      };
      pve = {
        HostName = "192.168.2.20";
        User = "root";
      };
      alpine-docker = {
        HostName = "192.168.2.201";
        User = "root";
      };
      tailscale = {
        HostName = "192.168.2.203";
        User = "maksym";
      };
      hermes = {
        HostName = "192.168.2.205";
        User = "maksym";
      };
      technitium-dns = {
        HostName = "192.168.2.207";
        User = "root";
      };
      banana = {
        HostName = "192.168.5.5";
        User = "maksym";
      };
      fish = {
        HostName = "192.168.3.5";
        User = "maksym";
      };
      hass = {
        HostName = "192.168.2.5";
        User = "maksym";
      };
      printer = {
        HostName = "192.168.2.204";
        User = "root";
      };
    };
  };
}
