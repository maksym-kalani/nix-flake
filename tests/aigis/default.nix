{
  pkgs,
  inputs,
  outputs,
}:
let
  inherit (pkgs) lib;
  ip = "192.168.2.50";
  prod = inputs.self.nixosConfigurations.aigis.config;

  # shortcut: voice servers download models at runtime, so they are off; prefetch the models to test them.
  skipped =
    lib.attrNames prod.services.wyoming.piper.servers
    ++ lib.attrNames prod.services.wyoming.faster-whisper.servers;

  imageHashes = import ./images.nix;
  containers = lib.mapAttrs (
    name: c:
    let
      ref = lib.splitString "@" c.image;
    in
    {
      image = lib.mkForce "${lib.head ref}:vm-test"; # an archive keeps the tag, not the digest
      imageFile = pkgs.dockerTools.pullImage {
        imageName = lib.head ref;
        imageDigest = lib.last ref;
        hash = imageHashes.${name};
        finalImageTag = "vm-test";
        # digest in the name, so a stale hash fails instead of reusing the old archive
        name = "docker-image-${name}-${lib.removePrefix "sha256:" (lib.last ref)}.tar";
      };
      pull = "never";
    }
  ) prod.virtualisation.oci-containers.containers;
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
  caddyContent = lib.concatMapStrings (s: if lib.isList s then "tls internal" else s) caddyfile;
  caddyRoutes = lib.filter (r: lib.elemAt r 1 == ip) (
    lib.filter lib.isList (
      builtins.split "@[a-z0-9-]+ host ([a-z0-9.-]+)[^}]*reverse_proxy https?://([0-9.]+):([0-9]+)" caddyContent
    )
  );

  ssh-keys = import (pkgs.path + "/nixos/tests/ssh-keys.nix") pkgs;
in
assert lib.length caddyfile == 3; # exactly one tls block replaced
pkgs.testers.runNixOSTest {
  name = "aigis-smoke";
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
        diskSize = 20480;
        oci-containers = { inherit containers; };
      };
      services.wyoming.piper.servers = lib.mkForce { };
      services.wyoming.faster-whisper.servers = lib.mkForce { };

      sops = {
        defaultSopsFile = lib.mkForce ./secrets.yaml;
        age.keyFile = lib.mkForce "/run/aigis-test-age-key"; # sops-nix refuses store paths
        age.sshKeyPaths = [ ];
        templates."Caddyfile".content = lib.mkForce caddyContent;
      };
      system.activationScripts = {
        aigisTestAgeKey = lib.stringAfter [
          "specialfs"
        ] "install -m 600 ${./age-key.txt} /run/aigis-test-age-key";
        setupSecrets.deps = [ "aigisTestAgeKey" ];
        setupSecretsForUsers.deps = [ "aigisTestAgeKey" ];
      };

      networking.networkmanager.unmanaged = [
        "eth0"
        "eth1"
      ];
      networking.interfaces.eth1 = {
        ipv4.addresses = lib.mkForce [
          {
            address = ip;
            prefixLength = 24;
          }
        ];
        # on-link route to belial's subnet
        ipv4.routes = [
          {
            address = "192.168.1.0";
            prefixLength = 24;
          }
        ];
      };

      # shortcut: no ZFS pool, so /mnt/tank is on the VM disk.
      boot.zfs.extraPools = lib.mkForce [ ];
      systemd.tmpfiles.rules = [
        # the immich module doesn't create it
        "d ${immich.mediaLocation} 0700 ${immich.user} ${immich.group} -"
        "d /mnt/tank/media/ttrpgs"
        "d /mnt/tank/media/downloads"
        "d /mnt/tank/users"
        "d /mnt/incomplete"
        "f /etc/wireguard/server.key 0600 root root - IJo86x/3mTmK+bA4yiYZwaBb2Ts8/FhmKlShbHslamM="
      ]
      ++ lib.mapAttrsToList (
        name: path: "L+ ${path} - - - - ${zim name}"
      ) prod.services.kiwix-serve.library;

      # root gets the key too, so only AllowUsers keeps it out
      users.users.maksym.openssh.authorizedKeys.keys = [ ssh-keys.snakeOilEd25519PublicKey ];
      users.users.root.openssh.authorizedKeys.keys = [ ssh-keys.snakeOilEd25519PublicKey ];

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
    caddy_routes = json.loads('${builtins.toJSON caddyRoutes}')
    # no SMART disks or ZFS pool in the VM
    vm_only_failures = {"smartd.service", "health-monitor.service"}

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

    with subtest("Gatus health conditions pass for every local endpoint"):
        retry(gatus_all_up, timeout_seconds=900)

    with subtest("LAN client reaches every local service through the firewall"):
        for e in endpoints:
            if e["name"] != "nix-cache":
                client.succeed(f"curl -sf --max-time 10 {e['url']}")

    with subtest("nix-serve only answers belial"):
        client.succeed("curl -sf --max-time 10 --interface 192.168.1.107 http://${ip}:5757/nix-cache-info")
        client.fail("curl -sf --max-time 5 http://${ip}:5757/nix-cache-info")

    with subtest("Every *.laufin.xyz route on aigis answers below 500"):
        broken = {}
        for host, _, _ in caddy_routes:
            code = client.succeed(f"curl -sk -o /dev/null -w '%{{http_code}}' --max-time 10 --resolve {host}:443:${ip} https://{host}/")
            if not code.startswith(("2", "3", "4")):
                broken[host] = code
        assert not broken, f"broken Caddy routes: {broken}"
        client.succeed("curl -s -o /dev/null -w '%{http_code}' -H 'Host: jellyfin.laufin.xyz' http://${ip}/ | grep -qx 308")

    with subtest("SSH takes keys for maksym only"):
        client.succeed("install -Dm600 ${ssh-keys.snakeOilEd25519PrivateKey} /root/.ssh/id_ed25519")
        ssh = "ssh -n -o StrictHostKeyChecking=no -o BatchMode=yes"  # -n: ssh must not read the driver's command channel
        client.succeed(f"{ssh} maksym@${ip} true")
        client.fail(f"{ssh} root@${ip} true")
        out = client.fail(f"{ssh} -o PubkeyAuthentication=no maksym@${ip} true 2>&1")
        assert "Permission denied (publickey)." in out, f"SSH offers more than publickey: {out.strip()!r}"

    with subtest("SSH login posts to ntfy"):
        aigis.wait_until_succeeds("curl -sf 'http://localhost:8081/homelab/json?poll=1&since=all' | grep -q 'ssh login'", timeout=30)

    with subtest("One restic backup completes"):
        aigis.succeed("RESTIC_REPOSITORY=/tmp/restic-test RESTIC_PASSWORD=test restic init")
        aigis.succeed("systemctl start restic-zfs-backup")

    with subtest("No unit in failed state (VM-only ones excepted)"):
        failed = set(aigis.succeed("systemctl list-units --failed --no-legend --plain | cut -d' ' -f1").split())
        assert failed <= vm_only_failures, f"failed units: {failed - vm_only_failures}"
  '';
}
