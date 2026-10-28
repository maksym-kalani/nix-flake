{
  sops.secrets.maksym_ssh_key = {
    sopsFile = ../../secrets/belial.yaml;
    owner = "maksym";
    path = "/home/maksym/.ssh/maksym";
  };

  programs.ssh.knownHosts = {
    aigis = {
      hostNames = [
        "aigis"
        "192.168.2.50"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBLSPdGpCDK5iEXdNlX0IlQOjbJnMknpefrh2AIapvic";
    };
    ci-runner = {
      hostNames = [
        "ci-runner"
        "192.168.2.51"
      ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII9mAwUUF35GHy8mRwdKqHONlQ4e3ZQr92YHHrZhqNKe";
    };
    "github.com".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    storagebox = {
      hostNames = [ "[u470428.your-storagebox.de]:23" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    };
  };
}
