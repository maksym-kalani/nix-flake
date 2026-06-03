{ pkgs, ... }:
{
  # Audio - PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.pipewire.wireplumber.extraConfig = {
    "51-ssl2-profile" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "device.name" = "alsa_card.usb-Solid_State_Logic_SSL_2_Mk_II-00"; } ];
          actions.update-props = {
            "api.acp.auto-profile" = false;
            "device.profile" = "pro-audio"; # або "input:analog-stereo+output:analog-stereo"
          };
        }
      ];
    };
    "99-hdmi-tv" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "device.name" = "alsa_card.pci-0000_0d_00.1";
            }
          ];
          actions = {
            update-props = {
              "device.profile" = "pro-audio";
            };
          };
        }
        {
          matches = [
            { "node.name" = "~alsa_output.pci-0000_0d_00.1.pro-output-[378]"; }
          ];
          actions = {
            update-props = {
              "node.disabled" = true;
            };
          };
        }
      ];
    };
    "99-hide-monitor-audio" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "alsa_output.pci-0000_0f_00.4.iec958-stereo"; }
          ];
          actions = {
            update-props = {
              "node.disabled" = true;
            };
          };
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    alsa-utils
  ];
}
