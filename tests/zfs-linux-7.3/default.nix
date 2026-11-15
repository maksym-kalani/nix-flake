{ pkgs }:
let
  expectedModule = pkgs.callPackage ../../pkgs/zfs-linux-7.3 {
    zfs = pkgs.linuxPackages_7_3.${pkgs.zfs.kernelModuleAttribute};
  };
in
pkgs.testers.runNixOSTest {
  name = "zfs-linux-7-3";

  nodes.machine =
    { config, ... }:
    {
      imports = [ ../../hosts/aigis/infra/zfs-kernel.nix ];

      assertions = [
        {
          assertion = config.boot.kernelPackages.kernel.drvPath == pkgs.linuxPackages_7_3.kernel.drvPath;
          message = "The ZFS VM must exercise the production Linux 7.3 kernel.";
        }
        {
          assertion = config.boot.zfs.package.drvPath == pkgs.zfs.drvPath && pkgs.zfs.version == "2.4.4";
          message = "The ZFS VM must use stable ZFS 2.4.4 userspace.";
        }
        {
          assertion = config.boot.zfs.modulePackage.drvPath == expectedModule.drvPath;
          message = "The ZFS VM must use the production backported module package.";
        }
      ];

      system.stateVersion = "26.11";
      networking.hostId = "deadbeef";
      boot = {
        supportedFilesystems = [ "zfs" ];
        kernelParams = [
          "trace_event=module:module_load,module:module_free"
          "trace_buf_size=8M"
        ];
        initrd = {
          supportedFilesystems = [ "zfs" ];
          kernelModules = [ "zfs" ];
          # Scripted initrd/postDeviceCommands was removed in the pinned nixpkgs.
          systemd.services.zfs-initrd-evidence = {
            description = "Record the live ZFS module before switch_root";
            requiredBy = [ "initrd.target" ];
            requires = [ "systemd-modules-load.service" ];
            after = [ "systemd-modules-load.service" ];
            before = [ "initrd-switch-root.target" ];
            unitConfig.DefaultDependencies = false;
            serviceConfig.Type = "oneshot";
            path = [ pkgs.coreutils ];
            script = ''
              test -d /sys/module/zfs
              test "$(cat /sys/module/zfs/initstate)" = live
              {
                cat /proc/sys/kernel/random/boot_id
                cat /sys/module/zfs/version
                cat /sys/module/zfs/sections/.text
              } > /run/zfs-initrd-evidence
              echo ZFS_INITRD_LOADED_BEFORE_SWITCH_ROOT > /dev/kmsg
            '';
          };
        };
        zfs = {
          devNodes = "/dev";
          extraPools = [ ];
          forceImportRoot = false;
          requestEncryptionCredentials = false;
        };
      };
      virtualisation = {
        emptyDiskImages = [ 2048 ];
        memorySize = 2048;
        cores = 2;
      };
    };

  testScript = ''
    import re
    import shlex

    key_file = "/run/zfs-test-key"
    key_material = "disposable-vm-only-passphrase"
    expected = ""
    kernel_errors = re.compile(
        r"BUG:|Oops:|WARNING: CPU:|scheduling while atomic|"
        r"general protection fault|kernel panic|KASAN:|UBSAN:",
        re.IGNORECASE,
    )

    def bash(script):
        return machine.succeed("bash -euo pipefail -c " + shlex.quote(script))

    def checksum(path):
        digest = machine.succeed("sha256sum " + shlex.quote(path)).split()[0]
        assert re.fullmatch(r"[0-9a-f]{64}", digest), digest
        return digest

    def assert_module_continuity():
        machine.succeed("test -d /sys/module/zfs", "test -d /sys/module/spl")
        machine.succeed(
            "mountpoint -q /sys/kernel/tracing || "
            "mount -t tracefs tracefs /sys/kernel/tracing"
        )
        trace = machine.succeed("cat /sys/kernel/tracing/trace")
        loads = re.findall(r"\bmodule_load:\s+zfs\s", trace)
        frees = re.findall(r"\bmodule_free:\s+zfs\s", trace)
        assert len(loads) == 1, f"Expected one ZFS load since kernel boot:\n{trace}"
        assert not frees, f"ZFS was unloaded after its initrd load:\n{trace}"
        marker = machine.succeed("cat /run/zfs-initrd-evidence").splitlines()
        assert len(marker) == 3, marker
        assert marker[0] == machine.succeed("cat /proc/sys/kernel/random/boot_id").strip()
        assert marker[1].startswith("2.4.4"), marker
        assert marker[2] == machine.succeed("cat /sys/module/zfs/sections/.text").strip()
        return marker[0]

    def assert_boot():
        machine.wait_for_unit("multi-user.target")
        machine.succeed("uname -r | grep -E '^7[.]3[.]'", "test -b /dev/vdb")
        machine.succeed(
            "journalctl -k -b --no-pager -o cat | "
            "grep -Fx ZFS_INITRD_LOADED_BEFORE_SWITCH_ROOT",
            "test $(modinfo -F version zfs | cut -d- -f1) = 2.4.4",
            "case $(readlink -f $(modinfo -n zfs)) in "
            "${expectedModule}/*) true ;; *) false ;; esac",
            "case $(readlink -f $(command -v zfs)) in "
            "${pkgs.zfs}/*) true ;; *) false ;; esac",
            "zfs version | grep -E '^zfs-2[.]4[.]4(-|$)'",
        )
        return assert_module_continuity()

    def assert_kernel_clean():
        for command in (
            "dmesg --color=never",
            "journalctl -k -b --no-pager -o cat",
        ):
            output = machine.succeed(command)
            errors = [line for line in output.splitlines() if kernel_errors.search(line)]
            assert not errors, f"Kernel diagnostics from {command}:\n" + "\n".join(errors)

    def assert_shutdown_clean():
        machine.shutdown()
        errors = [
            line for line in machine.get_console_log().splitlines()
            if kernel_errors.search(line)
        ]
        assert not errors, "Kernel diagnostics through shutdown:\n" + "\n".join(errors)

    def assert_inodes(root):
        bash(
            f"test -d {root}/dir; "
            f"test -f {root}/dir/payload; "
            f"test -f {root}/payload; "
            f"test -L {root}/link; "
            f"test $(readlink {root}/link) = dir/payload; "
            f"test $(stat -c %i {root}/payload) = $(stat -c %i {root}/dir/payload); "
            f"test $(stat -c %h {root}/payload) -eq 2; "
            f"cmp {root}/payload {root}/link; "
            f"test ! -e {root}/removed; "
            f"test ! -e {root}/temporary; "
            f"test ! -e {root}/after-snapshot; "
            f"test ! -e {root}/renamed"
        )
        assert checksum(f"{root}/payload") == expected, f"Corrupt {root}/payload"

    def assert_all_copies():
        for dataset in ("data", "copy", "encrypted"):
            machine.succeed(f"mountpoint -q /pool/{dataset}")
            assert_inodes(f"/pool/{dataset}")
        machine.succeed("zfs list -H -t snapshot testpool/data@verified testpool/copy@verified")

    def write_key():
        bash(f"umask 077; printf '%s' {shlex.quote(key_material)} > {key_file}")

    def assert_locked():
        machine.succeed(
            "test $(zfs get -H -o value keystatus testpool/encrypted) = unavailable",
            "test $(zfs get -H -o value mounted testpool/encrypted) = no",
            f"test ! -e {key_file}",
        )
        machine.fail(
            "mountpoint -q /pool/encrypted",
            "test -e /pool/encrypted/payload",
            "zfs load-key testpool/encrypted",
            "zfs mount testpool/encrypted",
            "cat /pool/encrypted/payload",
        )

    def unlock():
        write_key()
        machine.succeed(
            "zfs load-key testpool/encrypted",
            f"rm {key_file}",
            "zfs mount testpool/encrypted",
            "test $(zfs get -H -o value keystatus testpool/encrypted) = available",
        )

    def assert_healthy():
        machine.succeed(
            "test $(zpool list -H -o health testpool) = ONLINE",
            "zpool status -x testpool | grep -Fx \"pool 'testpool' is healthy\"",
            "zpool status -v testpool | grep -Fx 'errors: No known data errors'",
        )

    def scrub():
        machine.succeed("zpool scrub testpool", "zpool wait -t scrub testpool", timeout=180)
        machine.succeed("zpool status testpool | grep -E 'scrub repaired 0B .* with 0 errors'")
        assert_healthy()

    def export():
        machine.succeed("zpool sync testpool", "zpool export testpool")
        machine.fail("zpool list testpool", "mountpoint -q /pool/data")

    def import_pool():
        machine.succeed("zpool import -d /dev testpool")
        assert_locked()
        for dataset in ("data", "copy"):
            assert_inodes(f"/pool/{dataset}")
        unlock()
        assert_all_copies()
        assert_healthy()

    machine.start()
    with subtest("production packages and live initrd-to-stage-2 module continuity"):
        first_boot = assert_boot()
        machine.succeed("test -z \"$(zpool list -H -o name)\"")
        assert_kernel_clean()

    with subtest("disposable pool, verified payload and inode operations"):
        bash(
            "test $(lsblk -dn -o TYPE /dev/vdb) = disk; "
            "test $(blockdev --getsize64 /dev/vdb) -eq 2147483648; "
            "zpool create -o cachefile=none -O mountpoint=/pool testpool /dev/vdb; "
            "zfs create testpool/data; "
            "dd if=/dev/urandom of=/pool/data/payload bs=1M count=32 conv=fsync; "
            "mkdir /pool/data/dir; "
            "mv /pool/data/payload /pool/data/dir/payload; "
            "ln /pool/data/dir/payload /pool/data/payload; "
            "ln -s dir/payload /pool/data/link; "
            "mkdir /pool/data/temporary; "
            "touch /pool/data/temporary/created; "
            "mv /pool/data/temporary/created /pool/data/removed; "
            "rm /pool/data/removed; "
            "rmdir /pool/data/temporary"
        )
        expected = checksum("/pool/data/payload")
        assert_inodes("/pool/data")

    with subtest("snapshot, actual mutation and rollback of data and inodes"):
        machine.succeed("zfs snapshot testpool/data@verified")
        bash(
            "dd if=/dev/zero of=/pool/data/payload bs=1M count=1 conv=fsync; "
            "rm /pool/data/link; "
            "mv /pool/data/dir /pool/data/renamed; "
            "touch /pool/data/after-snapshot"
        )
        assert checksum("/pool/data/payload") != expected
        machine.succeed("test -f /pool/data/after-snapshot", "test -d /pool/data/renamed")
        machine.fail("test -L /pool/data/link")
        machine.succeed("zfs rollback testpool/data@verified")
        assert_inodes("/pool/data")

    with subtest("pipefail-protected snapshot send and receive"):
        bash("zfs send testpool/data@verified | zfs receive testpool/copy")
        assert_inodes("/pool/copy")
        machine.succeed("zfs list -H -t snapshot testpool/copy@verified")

    with subtest("encrypted data, unavailable key and explicit unload/reload"):
        write_key()
        machine.succeed(
            "zfs create -o encryption=aes-256-gcm -o keyformat=passphrase "
            f"-o keylocation=file://{key_file} testpool/encrypted",
            f"rm {key_file}",
        )
        bash("cp -a /pool/data/. /pool/encrypted/; sync")
        machine.succeed("test $(zfs get -H -o value encryption testpool/encrypted) = aes-256-gcm")
        assert_all_copies()
        machine.succeed("zfs unmount testpool/encrypted", "zfs unload-key testpool/encrypted")
        assert_locked()
        unlock()
        assert_all_copies()

    with subtest("scrub, same-boot export/import and independently retained checksums"):
        scrub()
        export()
        import_pool()
        assert_module_continuity()
        assert_kernel_clean()
        export()
        assert_kernel_clean()

    with subtest("cold QEMU shutdown/start, import and integrity of every copy"):
        assert_shutdown_clean()
        machine.start()
        second_boot = assert_boot()
        assert second_boot != first_boot, "Expected a fresh kernel boot, not a reused marker"
        machine.fail("zpool list testpool")
        import_pool()
        scrub()
        assert_all_copies()
        export()
        assert_module_continuity()
        assert_kernel_clean()
        assert_shutdown_clean()
  '';
}
