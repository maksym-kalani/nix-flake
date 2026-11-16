{ pkgs, prod }:
let
  fixture =
    name: text:
    pkgs.writeShellScriptBin name ''
      set -eu
      ${text}
    '';
  fixtures = pkgs.symlinkJoin {
    name = "health-monitor-fixtures";
    paths = [
      (fixture "zpool" ''
        touch "$HEALTH_MONITOR_TEST_DIR/ran"
        if [ -e "$HEALTH_MONITOR_TEST_DIR/block" ]; then
          touch "$HEALTH_MONITOR_TEST_DIR/running"
          exec sleep infinity
        fi
        case "$*" in
          "status tank2") echo "errors: No known data errors" ;;
          "list -Ho health tank2") echo ONLINE ;;
          "list -Ho frag tank2") echo '0%' ;;
          *) exit 2 ;;
        esac
      '')
      (fixture "ps" ''
        count=$(cat "$HEALTH_MONITOR_TEST_DIR/stuck")
        for ((i=0; i<count; i++)); do
          echo "root 1 0 0 0 0 ? D 00:00 0:00 fixture-stuck"
        done
      '')
      (fixture "uptime" ''
        if [ "''${1-}" = -p ]; then
          echo 'up 1 day'
        else
          echo '12:00 up 1 day, 0 users, load average: 0.00, 0.00, 0.00'
        fi
      '')
      (fixture "free" ''
        echo 'Mem: 10000 1000 9000 0 0 9000'
      '')
      (fixture "iostat" ''
        if [ "$1" = -c ]; then
          echo ' 0 0 0 0'
        else
          echo 'Device r/s w/s await util'
        fi
      '')
      (fixture "grep" ''
        if [ "''${2-}" = /proc/spl/kstat/zfs/arcstats ]; then
          case "$1" in
            '^hits ') echo 'hits 4 100' ;;
            '^misses ') echo 'misses 4 0' ;;
            *) exit 2 ;;
          esac
        else
          exec ${pkgs.gnugrep}/bin/grep "$@"
        fi
      '')
    ];
  };
  preSwitch = pkgs.writeShellScript "health-monitor-pre-switch-test" prod.system.preSwitchChecks.healthMonitor;
  activation = pkgs.writeShellScript "health-monitor-test-activation" ''
    set -eu
    touch /run/health-monitor-test/locked
    while [ ! -e /run/health-monitor-test/release ]; do sleep 0.1; done
    exit "$(cat /run/health-monitor-test/release)"
  '';
  service = prod.systemd.services.health-monitor;
in
{
  inherit fixtures;
  testScript = ''
    with subtest("health-monitor skips activation and resumes without masking alerts"):
        import shlex

        def write_fixture(path, text):
            aigis.succeed(f"printf %s {shlex.quote(text)} > {shlex.quote(path)}")

        def health_alerts():
            lines = aigis.succeed("curl -sf 'http://localhost:8081/homelab/json?poll=1&since=all'").splitlines()
            return [json.loads(line) for line in lines if json.loads(line).get("title") == "ZFS System Alert - tank2"]

        def start_activation():
            aigis.succeed("rm -f /run/health-monitor-test/locked /run/health-monitor-test/release")
            aigis.succeed("systemd-run --unit=health-monitor-test-activation --property=Type=exec --property=RemainAfterExit=yes ${pkgs.util-linux}/bin/flock --exclusive /run/nixos/switch-to-configuration.lock ${activation}")
            aigis.wait_until_succeeds("test -e /run/health-monitor-test/locked")

        def finish_activation(code):
            write_fixture("/run/health-monitor-test/release", str(code))
            state = "exited" if code == 0 else "failed"
            aigis.wait_until_succeeds(f"test \"$(systemctl show health-monitor-test-activation.service -p SubState --value)\" = {state}")
            result = aigis.succeed("systemctl show health-monitor-test-activation.service -p Result --value").strip()
            assert result == ("success" if code == 0 else "exit-code"), result
            aigis.succeed("systemctl stop health-monitor-test-activation.service; systemctl reset-failed health-monitor-test-activation.service")

        def assert_skipped():
            aigis.succeed("test ! -e /run/health-monitor-test/ran")
            aigis.wait_until_succeeds("test \"$(systemctl show health-monitor.service -p ActiveState --value)\" = inactive")
            aigis.fail("systemctl is-failed --quiet health-monitor.service")
            assert health_alerts() == before

        aigis.succeed("systemctl stop health-monitor.timer health-monitor.service")
        aigis.succeed("systemctl reset-failed health-monitor.service")
        aigis.succeed("mkdir -p /run/health-monitor-test /run/nixos /run/systemd/system/health-monitor.service.d /run/systemd/system/health-monitor.timer.d")
        write_fixture("/run/health-monitor-test/stuck", "0")
        write_fixture("/run/systemd/system/health-monitor.service.d/fixture.conf", "[Service]\nEnvironment=HEALTH_MONITOR_TEST_DIR=/run/health-monitor-test\nEnvironment=PATH=${fixtures}/bin:${service.environment.PATH}\n")
        write_fixture("/run/systemd/system/health-monitor.timer.d/fixture.conf", "[Timer]\nOnCalendar=\nOnActiveSec=1ms\nPersistent=false\n")
        aigis.succeed("systemctl daemon-reload")
        before = health_alerts()

        # No activation, including the first boot before any lock file exists.
        aigis.succeed("rm -f /run/nixos/switch-to-configuration.lock; systemctl start health-monitor.service")
        aigis.succeed("test -e /run/health-monitor-test/ran")
        assert health_alerts() == before

        # Quiesce a check that began before the switch acquired its lock.
        aigis.succeed("touch /run/health-monitor-test/block; systemctl start --no-block health-monitor.service")
        aigis.wait_until_succeeds("test -e /run/health-monitor-test/running")
        start_activation()
        aigis.succeed("${preSwitch} /run/current-system switch")
        aigis.fail("systemctl is-active --quiet health-monitor.service")
        aigis.succeed("rm -f /run/health-monitor-test/block /run/health-monitor-test/ran")
        aigis.succeed("systemctl start health-monitor.service")
        assert_skipped()

        # Trigger the real timer while the same activation lock remains held.
        last_trigger = aigis.succeed("systemctl show health-monitor.timer -p LastTriggerUSecMonotonic --value").strip()
        last_inactive = aigis.succeed("systemctl show health-monitor.service -p InactiveEnterTimestampMonotonic --value").strip()
        aigis.succeed("systemctl start health-monitor.timer")
        aigis.wait_until_succeeds(f"test \"$(systemctl show health-monitor.timer -p LastTriggerUSecMonotonic --value)\" != {shlex.quote(last_trigger)}")
        aigis.wait_until_succeeds(f"test \"$(systemctl show health-monitor.service -p InactiveEnterTimestampMonotonic --value)\" != {shlex.quote(last_inactive)}")
        aigis.wait_until_succeeds("test \"$(systemctl show health-monitor.service -p ActiveState --value)\" = inactive")
        assert_skipped()
        aigis.succeed("systemctl stop health-monitor.timer")
        finish_activation(0)
        aigis.succeed("systemctl start health-monitor.service; test -e /run/health-monitor-test/ran")

        # A failed activation releases its kernel lock just like a successful one.
        aigis.succeed("rm /run/health-monitor-test/ran")
        start_activation()
        aigis.succeed("systemctl start health-monitor.service")
        assert_skipped()
        finish_activation(1)
        aigis.succeed("systemctl start health-monitor.service; test -e /run/health-monitor-test/ran")
        assert health_alerts() == before

        # Run the unchanged monitor with deterministic unhealthy metric inputs.
        write_fixture("/run/health-monitor-test/stuck", "6")
        aigis.fail("systemctl start health-monitor.service")
        assert aigis.succeed("systemctl show health-monitor.service -p Result --value").strip() == "exit-code"
        after = health_alerts()
        assert len(after) == len(before) + 1, after
        assert "6 processes stuck in D state" in after[-1]["message"], after[-1]

        aigis.succeed("systemctl reset-failed health-monitor.service; rm /run/systemd/system/health-monitor.service.d/fixture.conf /run/systemd/system/health-monitor.timer.d/fixture.conf; systemctl daemon-reload; systemctl start health-monitor.timer")
  '';
}
