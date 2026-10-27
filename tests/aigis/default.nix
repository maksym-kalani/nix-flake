# VM test for aigis (https://nix.dev/tutorials/nixos/integration-testing-using-virtual-machines.html).
# Boots the production modules offline and checks that Gatus sees every local service up, that a LAN
# client gets through the firewall, and that Caddy serves *.laufin.xyz. See docs/aigis-vm-inventory.md.
# Run: nix build -L .#checks.x86_64-linux.aigis-vm
{
  pkgs,
  inputs,
  outputs,
}:
let
  inherit (pkgs) lib;
  ip = "192.168.2.50";
  prod = inputs.self.nixosConfigurations.aigis.config;

  # shortcut: containers need pinned images (pullImage + pull = "never") and the voice servers download
  # models at runtime, so both are off and their Gatus endpoints skipped; upgrade by pinning them.
  skipped =
    lib.attrNames prod.virtualisation.oci-containers.containers
    ++ lib.attrNames prod.services.wyoming.piper.servers
    ++ lib.attrNames prod.services.wyoming.faster-whisper.servers;
  endpoints = map (e: { inherit (e) name url; }) (
    lib.filter (
      e: lib.hasInfix "//${ip}:" e.url && !lib.elem e.name skipped
    ) prod.services.gatus.settings.endpoints
  );

  zim =
    name:
    pkgs.runCommand "${name}.zim"
      {
        nativeBuildInputs = [
          pkgs.zim-tools
          pkgs.imagemagick
        ];
      }
      ''
        mkdir html
        echo '<html><head><title>${name}</title></head><body>${name}</body></html>' > html/index.html
        magick -size 48x48 xc:white html/icon.png
        zimwriterfs --welcome=index.html --illustration=icon.png --language=eng --title=${name} \
          --description=test --creator=test --publisher=test --name=${name} html $out
      '';

  caddyfile = builtins.split "tls \\{[^}]*}[^}]*}" prod.sops.templates."Caddyfile".content;
in
assert lib.length caddyfile == 3; # exactly one namecheap tls block replaced below
pkgs.testers.runNixOSTest {
  name = "aigis";
  node.specialArgs = { inherit inputs outputs; };
  node.pkgsReadOnly = false; # hosts/common sets nixpkgs.overlays and nixpkgs.config

  nodes.aigis =
    { config, lib, ... }:
    let
      immich = config.services.immich;
    in
    {
      imports = [
        ../../hosts/aigis
        inputs.sops-nix.nixosModules.sops
      ];

      virtualisation = {
        memorySize = 8192;
        cores = 4;
        diskSize = 8192;
        oci-containers.containers = lib.mkForce { };
      };
      services.wyoming.piper.servers = lib.mkForce { };
      services.wyoming.faster-whisper.servers = lib.mkForce { };

      sops = {
        defaultSopsFile = lib.mkForce ./secrets.yaml;
        age.keyFile = lib.mkForce "/run/aigis-test-age-key"; # sops-nix refuses store paths
        age.sshKeyPaths = [ ];
        templates."Caddyfile".content = lib.mkForce (
          lib.concatMapStrings (s: if lib.isList s then "tls internal" else s) caddyfile
        );
      };
      system.activationScripts = {
        aigisTestAgeKey = lib.stringAfter [ "specialfs" ] "install -m 600 ${./age-key.txt} /run/aigis-test-age-key";
        setupSecrets.deps = [ "aigisTestAgeKey" ];
        setupSecretsForUsers.deps = [ "aigisTestAgeKey" ];
      };

      networking.networkmanager.enable = lib.mkForce false;
      networking.interfaces.eth1 = {
        ipv4.addresses = lib.mkForce [
          {
            address = ip;
            prefixLength = 24;
          }
        ];
        # belial's subnet, on-link so the client below can also speak from 192.168.1.107
        ipv4.routes = [
          {
            address = "192.168.1.0";
            prefixLength = 24;
          }
        ];
      };

      # shortcut: no ZFS pool, /mnt/tank lives on the VM root disk; upgrade by adding a scratch disk.
      boot.zfs.extraPools = lib.mkForce [ ];
      systemd.tmpfiles.rules = [
        # the immich module only fixes this dir's mode ("e"); on aigis it pre-exists on the pool
        "d ${immich.mediaLocation} 0700 ${immich.user} ${immich.group} -"
      ]
      ++ lib.mapAttrsToList (name: path: "L+ ${path} - - - - ${zim name}") prod.services.kiwix-serve.library;

      environment.systemPackages = [ pkgs.curl ];
    };

  nodes.client =
    { lib, ... }:
    {
      networking.interfaces.eth1.ipv4.addresses = lib.mkForce [
        {
          address = "192.168.2.10";
          prefixLength = 24;
        }
        {
          address = "192.168.1.107"; # belial, the only nix-serve client
          prefixLength = 24;
        }
      ];
      environment.systemPackages = [ pkgs.curl ];
    };

  testScript = ''
    import json

    endpoints = json.loads('${builtins.toJSON endpoints}')

    start_all()
    aigis.wait_for_unit("multi-user.target")
    aigis.wait_for_open_port(8080)

    def gatus_down():
        statuses = json.loads(aigis.succeed("curl -sf http://localhost:8080/api/v1/endpoints/statuses"))
        up = {s["name"] for s in statuses if s.get("results") and s["results"][-1]["success"]}
        return [e["name"] for e in endpoints if e["name"] not in up]

    def gatus_all_up(last_try):
        down = gatus_down()
        if down and last_try:
            aigis.log(f"down in Gatus: {down}")
        return not down

    with subtest("Gatus sees every local service up"):
        retry(gatus_all_up, timeout_seconds=900)

    with subtest("LAN client reaches every local service through the firewall"):
        for e in endpoints:
            if e["name"] != "nix-cache":
                client.succeed(f"curl -sf --max-time 10 {e['url']}")

    with subtest("nix-serve only answers belial"):
        client.succeed("curl -sf --max-time 10 --interface 192.168.1.107 http://${ip}:5757/nix-cache-info")
        client.fail("curl -sf --max-time 5 http://${ip}:5757/nix-cache-info")

    with subtest("Caddy serves *.laufin.xyz"):
        client.succeed("curl -sfk --resolve jellyfin.laufin.xyz:443:${ip} https://jellyfin.laufin.xyz/health")
        client.succeed("curl -s -o /dev/null -w '%{http_code}' -H 'Host: jellyfin.laufin.xyz' http://${ip}/ | grep -qx 308")
  '';
}
