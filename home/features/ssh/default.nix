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
    };
  };
}
