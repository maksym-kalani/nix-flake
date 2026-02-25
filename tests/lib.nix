# Test helper library
{ pkgs }:

{
  # Helper to create standard service test
  mkServiceTest = { name, unit, port, healthEndpoint ? "/" }: ''
    with subtest("${name}"):
        machine.wait_for_unit("${unit}", timeout=60)
        status = machine.succeed("systemctl is-active ${unit}")
        assert status.strip() == "active", f"${unit} is not active: {status}"
        machine.wait_for_open_port(${toString port}, timeout=30)
        machine.succeed("curl -sf http://localhost:${toString port}${healthEndpoint}")
  '';

  # Helper to check systemd unit status
  mkUnitCheck = unit: ''
    machine.succeed("systemctl is-active ${unit}")
  '';

  # Helper for container health check
  mkContainerCheck = { name, port }: ''
    machine.succeed("podman ps --format '{{.Names}}' | grep -q ${name}")
    machine.wait_for_open_port(${toString port})
  '';

  # Common VM configuration overrides for testing
  vmOverrides = { lib, ... }: {
    # Disable hardware-specific settings for VM testing
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.grub.enable = lib.mkForce false;
    boot.supportedFilesystems = lib.mkForce [ "ext4" ];
    boot.zfs.extraPools = lib.mkForce [ ];

    # Use simple filesystem for VM
    fileSystems = lib.mkForce {
      "/" = { device = "/dev/vda"; fsType = "ext4"; };
    };

    # Disable SOPS secrets (no key file in VM)
    sops.secrets = lib.mkForce { };
    sops.age.keyFile = lib.mkForce "/dev/null";

    # Disable ZFS-related services
    services.zfs.autoScrub.enable = lib.mkForce false;

    # Disable system auto-upgrade in tests
    system.autoUpgrade.enable = lib.mkForce false;

    # Disable restic backup in tests
    services.restic.backups = lib.mkForce { };

    # Mock user passwords (disable hashed password from secrets)
    users.users.maksym.hashedPasswordFile = lib.mkForce null;
    users.users.maksym.password = lib.mkForce "test";
  };
}
