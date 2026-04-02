{
  pkgs,
  ...
}:
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    gamescopeSession.enable = true;
    package = pkgs.steam.override {
      extraEnv = {
        # Toggle: R_Shift+F12
        MANGOHUD = "1";
        MANGOHUD_CONFIG = "read_cfg,no_display";
        GAMEMODERUN = "1";
        AMD_VULKAN_ICD = "RADV";
        PROTON_ADD_CONFIG = "fsr4";
        PROTON_LOCAL_SHADER_CACHE = "1";
        MESA_SHADER_CACHE_MAX_SIZE = "16G";
        MESA_GLSL_CACHE_MAX_SIZE = "16G";
        WINEDLLOVERRIDES = "dinput8,dxgi,dsound=n,b";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    mangohud
    heroic
    jemalloc
  ];

  programs.gamemode.enable = true;

  boot.kernelModules = [ "ntsync" ];
}
