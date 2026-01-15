# NixOS Integration Testing Plan

## Overview

Use NixOS's built-in VM testing framework to validate the server configuration. Tests spin up a QEMU VM with the configuration and verify services are running correctly.

## Test Framework Structure

### Directory Structure

```
tests/
├── default.nix           # Exports all tests
├── lib.nix               # Shared test helpers
└── aigis/
    ├── default.nix       # All aigis tests
    ├── services.nix      # Service health tests
    └── containers.nix    # Container tests
```

### Integration with flake.nix

```nix
{
  outputs = { self, nixpkgs, ... }@inputs:
    let
      # ... existing code ...
    in {
      # ... existing outputs ...

      # Add checks for tests
      checks.x86_64-linux = {
        aigis-services = import ./tests/aigis/services.nix {
          inherit inputs;
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        };
      };
    };
}
```

## Test Implementation

### 1. Basic Service Health Test

**`tests/aigis/services.nix`**
```nix
{ pkgs, inputs, ... }:

pkgs.nixosTest {
  name = "aigis-services";

  nodes.server = { config, pkgs, ... }: {
    imports = [
      ../../modules/server.nix
      ../../modules/services/ntfy.nix
      ../../modules/services/gatus.nix
      # Import services to test
    ];

    # Test configuration
    server = {
      ip = "192.168.1.1";
      domain = "test.local";
    };

    server.services = {
      ntfy.enable = true;
      gatus.enable = true;
    };

    # VM-specific overrides
    virtualisation = {
      memorySize = 2048;
      cores = 2;
    };
  };

  testScript = ''
    server.start()
    server.wait_for_unit("multi-user.target")

    # Test ntfy service
    server.wait_for_unit("ntfy-sh.service")
    server.succeed("systemctl is-active ntfy-sh.service")
    server.wait_for_open_port(8081)
    server.succeed("curl -sf http://localhost:8081")

    # Test gatus service
    server.wait_for_unit("gatus.service")
    server.succeed("systemctl is-active gatus.service")
    server.wait_for_open_port(8080)
    server.succeed("curl -sf http://localhost:8080")
  '';
}
```

### 2. Comprehensive Service Status Test

**`tests/aigis/all-services.nix`**
```nix
{ pkgs, inputs, ... }:

let
  # Define all services with their expected units and ports
  services = [
    { name = "ntfy"; unit = "ntfy-sh.service"; port = 8081; }
    { name = "gatus"; unit = "gatus.service"; port = 8080; }
    { name = "jellyfin"; unit = "jellyfin.service"; port = 8096; }
    { name = "sonarr"; unit = "sonarr.service"; port = 8989; }
    { name = "radarr"; unit = "radarr.service"; port = 7878; }
    { name = "prowlarr"; unit = "prowlarr.service"; port = 9696; }
    { name = "karakeep"; unit = "karakeep.service"; port = 3050; }
    { name = "immich"; unit = "immich-server.service"; port = 2283; }
    { name = "caddy"; unit = "caddy.service"; port = 80; }
  ];

  # Generate test script for all services
  mkServiceTest = svc: ''
    with subtest("${svc.name}"):
        server.wait_for_unit("${svc.unit}")
        server.succeed("systemctl is-active ${svc.unit}")
        server.wait_for_open_port(${toString svc.port})
        result = server.succeed("curl -sf -o /dev/null -w '%{http_code}' http://localhost:${toString svc.port} || true")
        # Some services return non-200 for root, just check port is responding
        server.succeed("nc -z localhost ${toString svc.port}")
  '';

  testScript = ''
    server.start()
    server.wait_for_unit("multi-user.target")

    ${builtins.concatStringsSep "\n" (map mkServiceTest services)}

    # Summary: list all failed units
    server.succeed("systemctl --failed || true")
  '';
in
pkgs.nixosTest {
  name = "aigis-all-services";

  nodes.server = { config, pkgs, ... }: {
    imports = [
      ../../hosts/aigis  # Import full aigis config
    ];

    # Override for VM testing
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      diskSize = 8192;
    };

    # Disable hardware-specific settings
    boot.loader.systemd-boot.enable = pkgs.lib.mkForce false;
    boot.loader.grub.enable = pkgs.lib.mkForce false;
    fileSystems = pkgs.lib.mkForce {
      "/" = { device = "/dev/vda"; fsType = "ext4"; };
    };

    # Mock secrets for testing
    sops.secrets = pkgs.lib.mkForce {};
  };

  inherit testScript;
}
```

### 3. Container Service Tests

**`tests/aigis/containers.nix`**
```nix
{ pkgs, inputs, ... }:

let
  containers = [
    { name = "kavita"; port = 5000; }
    { name = "searxng"; port = 8082; }
    { name = "it-tools"; port = 8083; }
    { name = "stirling-pdf"; port = 8084; }
  ];

  mkContainerTest = ctr: ''
    with subtest("container-${ctr.name}"):
        server.wait_for_unit("podman-${ctr.name}.service")
        server.succeed("podman ps | grep ${ctr.name}")
        server.wait_for_open_port(${toString ctr.port})
        server.succeed("curl -sf http://localhost:${toString ctr.port} || true")
  '';
in
pkgs.nixosTest {
  name = "aigis-containers";

  nodes.server = { config, pkgs, ... }: {
    imports = [ /* container modules */ ];

    virtualisation = {
      memorySize = 4096;
      cores = 4;
      podman.enable = true;
    };

    server = {
      ip = "192.168.1.1";
      domain = "test.local";
    };

    # Enable container services
    server.services = {
      kavita.enable = true;
      searxng.enable = true;
    };
  };

  testScript = ''
    server.start()
    server.wait_for_unit("multi-user.target")
    server.wait_for_unit("podman.service")

    ${builtins.concatStringsSep "\n" (map mkContainerTest containers)}
  '';
}
```

### 4. Test Helper Library

**`tests/lib.nix`**
```nix
{ pkgs }:

{
  # Helper to create standard service test
  mkServiceTest = { name, unit, port, healthEndpoint ? "/" }: ''
    with subtest("${name}"):
        server.wait_for_unit("${unit}", timeout=60)
        status = server.succeed("systemctl is-active ${unit}")
        assert status.strip() == "active", f"${unit} is not active: {status}"
        server.wait_for_open_port(${toString port}, timeout=30)
        server.succeed("curl -sf http://localhost:${toString port}${healthEndpoint}")
  '';

  # Helper to check systemd unit status
  mkUnitCheck = unit: ''
    server.succeed("systemctl is-active ${unit}")
  '';

  # Helper for container health check
  mkContainerCheck = { name, port }: ''
    server.succeed("podman ps --format '{{.Names}}' | grep -q ${name}")
    server.wait_for_open_port(${toString port})
  '';
}
```

## Running Tests

### Commands

```bash
# Run all checks
nix flake check

# Run specific test
nix build .#checks.x86_64-linux.aigis-services

# Run test interactively (for debugging)
nix build .#checks.x86_64-linux.aigis-services.driverInteractive
./result/bin/nixos-test-driver
>>> server.start()
>>> server.wait_for_unit("multi-user.target")
>>> server.succeed("systemctl status")

# Run with verbose output
nix build .#checks.x86_64-linux.aigis-services --print-build-logs
```

### Interactive Debugging

```python
# Inside the interactive driver
>>> server.shell_interact()  # Get a shell in the VM
>>> server.screenshot("debug")  # Take screenshot
>>> server.succeed("journalctl -u myservice")  # Check logs
```

## Test Categories

| Test | Purpose | Services Tested |
|------|---------|-----------------|
| `services` | Core native services | ntfy, gatus, caddy |
| `media` | Media stack | jellyfin, sonarr, radarr, prowlarr |
| `containers` | Podman containers | kavita, searxng, etc. |
| `networking` | Caddy reverse proxy | All virtualHosts |
| `full` | Complete integration | Everything |

## Considerations

### VM Limitations
- No ZFS support in test VMs - mock filesystems
- No real hardware - skip hardware-configuration.nix
- Secrets must be mocked or use test values
- Container images need network access or pre-pulling

### Test Isolation
- Each test runs in isolated VM
- No state persists between test runs
- Network is isolated (use `nodes.client` for multi-node tests)

### Resource Requirements
- Tests require significant RAM (2-4GB per VM)
- Container tests need more disk space
- Full integration tests may take 5-10 minutes

## Implementation Priority

1. **Phase 1**: Basic infrastructure tests (caddy, gatus, ntfy)
2. **Phase 2**: Native service tests (jellyfin, *arr stack)
3. **Phase 3**: Container service tests
4. **Phase 4**: Full integration test with multi-node setup