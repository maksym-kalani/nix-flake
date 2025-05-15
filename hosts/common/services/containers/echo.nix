{ lib, config, ... }:
let
  # Configuration options with defaults
  cfg = {
    # Container name
    name = "echo-http-service";
    
    # Container image
    image = "hashicorp/http-echo";
    
    # Container port configuration
    port = {
      internal = 5678; # Port inside the container
      external = 5678; # Port on the host
    };
    
    # Optional settings with defaults
    extraOptions = [];
    volumes = [];
    environmentVariables = {};
    
    # Run settings
    autoStart = true;
  };
in {
  # Container definition
  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = ["${toString cfg.port.external}:${toString cfg.port.internal}"];
    
    # Optional configs
    extraOptions = cfg.extraOptions;
    volumes = cfg.volumes;
    environment = cfg.environmentVariables;
    autoStart = cfg.autoStart;
  };
}