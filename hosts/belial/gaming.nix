{
  inputs,
  pkgs,
  ...
}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["amdgpu"];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [pkgs.proton-ge-bin];
    gamescopeSession.enable = true;
  };

  environment.systemPackages = with pkgs; [
    mangohud
    heroic
  ];

  programs.gamemode.enable = true;
}
