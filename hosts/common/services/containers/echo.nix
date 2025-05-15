{lib, ...}: {
  virtualisation.oci-containers.containers."echo-http-service" = {
    image = "hashicorp/http-echo";
    extraOptions = ["-text='Hello, World!'"];
    ports = ["5678:5678"];
  };
}