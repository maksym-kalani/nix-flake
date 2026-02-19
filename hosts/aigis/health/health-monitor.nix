{
  pkgs,
  ...
}:
let
  health-monitor = pkgs.writeShellScriptBin "health-monitor" ''
    set -euo pipefail

    # Enforce C locale to avoid commas as decimal separators
    export LC_ALL=C
    export LANG=C

    # Configuration
    NTFY_URL="http://localhost:8081/homelab"
    POOL_NAME="tank2"
    ALERT_THRESHOLD_LOAD=10
    ALERT_THRESHOLD_FRAG=50
    ALERT_THRESHOLD_ARC_HIT=80
    ALERT_THRESHOLD_IOWAIT=30
    ALERT_THRESHOLD_UTIL=95
    ALERT_THRESHOLD_AWAIT=50
    ALERT_THRESHOLD_DSTATE=5

    ALERTS=()

    send_alert() {
      local priority=$1
      local title=$2
      local message=$3
      curl -H "Title: $title" \
           -H "Priority: $priority" \
           -H "Tags: warning" \
           -d "$message" \
           "$NTFY_URL" 2>/dev/null
    }

    # Check if a ZFS scrub is currently running
    is_scrub_running() {
      zpool status "$POOL_NAME" 2>/dev/null | grep -q "scrub in progress"
    }

    SCRUB_RUNNING=false
    if is_scrub_running; then
      SCRUB_RUNNING=true
      echo "NOTE: ZFS scrub is in progress — skipping disk I/O and load alerts"
    fi

    check_metric() {
      local name=$1
      local value=$2
      local threshold=$3
      local comparison=$4

      local num
      num=$(printf "%s" "$value" | tr ',' '.' | sed 's/[^0-9.\-]//g')
      if [ -z "$num" ]; then num=0; fi

      if [ "$comparison" = "greater" ]; then
        if (( $(echo "$num > $threshold" | bc -l) )); then
          echo "$name: $value [ALERT]"
          return 1
        fi
      elif [ "$comparison" = "less" ]; then
        if (( $(echo "$num < $threshold" | bc -l) )); then
          echo "$name: $value [ALERT]"
          return 1
        fi
      fi

      echo "$name: $value [OK]"
      return 0
    }

    echo "=== ZFS SYSTEM HEALTH CHECK ==="
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # 1. Load Average (skip during scrub — scrubs cause high load)
    echo "--- Load Average ---"
    LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
    LOAD_5MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | tr -d ' ')
    LOAD_15MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $3}' | tr -d ' ')

    if [ "$SCRUB_RUNNING" = false ]; then
      if ! check_metric "Load (1min)" "$LOAD_1MIN" "$ALERT_THRESHOLD_LOAD" "greater"; then
        ALERTS+=("High load average: $LOAD_1MIN (threshold: $ALERT_THRESHOLD_LOAD)")
      fi
    else
      echo "Load (1min): $LOAD_1MIN [SKIPPED — scrub running]"
    fi
    echo "Load (5min): $LOAD_5MIN"
    echo "Load (15min): $LOAD_15MIN"
    echo ""

    # 2. Stuck Processes (skip during scrub — scrubs cause D-state processes)
    echo "--- Stuck Processes ---"
    STUCK_COUNT=$(ps aux | awk '$8 ~ /D/' | wc -l)
    if [ "$SCRUB_RUNNING" = false ]; then
      if ! check_metric "D-state processes" "$STUCK_COUNT" "$ALERT_THRESHOLD_DSTATE" "greater"; then
        STUCK_PROCS=$(ps aux | awk '$8 ~ /D/ {print $11}' | tr '\n' ', ')
        ALERTS+=("$STUCK_COUNT processes stuck in D state: $STUCK_PROCS")
      fi
    else
      echo "D-state processes: $STUCK_COUNT [SKIPPED — scrub running]"
    fi
    echo ""

    # 3. ZFS Pool Health (always check)
    echo "--- ZFS Pool Health ---"
    POOL_HEALTH=$(zpool list -Ho health "$POOL_NAME" 2>/dev/null)
    if [ "$POOL_HEALTH" != "ONLINE" ]; then
      echo "Pool Health: $POOL_HEALTH [ALERT]"
      ALERTS+=("ZFS pool $POOL_NAME is $POOL_HEALTH (not ONLINE)")
    else
      echo "Pool Health: $POOL_HEALTH [OK]"
    fi

    ERRORS=$(zpool status "$POOL_NAME" | grep -E "errors:" | awk '{print $2}')
    if [ "$ERRORS" != "No" ]; then
      echo "Pool Errors: $ERRORS [ALERT]"
      ALERTS+=("ZFS pool has errors: $ERRORS")
    else
      echo "Pool Errors: None [OK]"
    fi
    echo ""

    # 4. Fragmentation (always check)
    echo "--- Fragmentation ---"
    FRAG=$(zpool list -Ho frag "$POOL_NAME" | tr -d '%')
    if ! check_metric "Fragmentation" "''${FRAG}%" "$ALERT_THRESHOLD_FRAG" "greater"; then
      ALERTS+=("High fragmentation: ''${FRAG}% (threshold: ''${ALERT_THRESHOLD_FRAG}%)")
    fi
    echo ""

    # 5. Memory Usage (always check)
    echo "--- Memory ---"
    MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
    MEM_USED=$(free -h | grep Mem | awk '{print $3}')
    MEM_PERCENT=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')
    echo "Memory: $MEM_USED / $MEM_TOTAL (''${MEM_PERCENT}%)"
    echo ""

    # 6. ARC Statistics (always check)
    echo "--- ZFS ARC ---"
    ARC_HITS=$(grep "^hits " /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
    ARC_MISSES=$(grep "^misses " /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
    ARC_TOTAL=$((ARC_HITS + ARC_MISSES))
    if [ $ARC_TOTAL -gt 0 ]; then
      ARC_HIT_RATIO=$(echo "scale=1; ($ARC_HITS * 100) / $ARC_TOTAL" | bc)
      if ! check_metric "ARC Hit Ratio" "''${ARC_HIT_RATIO}%" "$ALERT_THRESHOLD_ARC_HIT" "less"; then
        ALERTS+=("Low ARC hit ratio: ''${ARC_HIT_RATIO}% (threshold: ''${ALERT_THRESHOLD_ARC_HIT}%)")
      fi
    fi
    echo ""

    # 7. Disk I/O Statistics (skip during scrub — scrubs saturate disks)
    echo "--- Disk I/O ---"
    if [ "$SCRUB_RUNNING" = false ]; then
      IOSTAT_OUTPUT=$(iostat -x sda sdb 1 2 2>/dev/null)
      while read -r line; do
        if [[ $line == sda* ]] || [[ $line == sdb* ]]; then
          DEVICE=$(echo "$line" | awk '{print $1}')
          UTIL_RAW=$(echo "$line" | awk '{print $NF}')
          AWAIT_RAW=$(echo "$line" | awk '{print $10}')
          UTIL_INT=$(printf "%s" "$UTIL_RAW" | tr ',' '.' | awk '{printf("%d", $1)}')
          AWAIT_INT=$(printf "%s" "$AWAIT_RAW" | tr ',' '.' | awk '{printf("%d", $1)}')

          check_metric "Device $DEVICE util" "''${UTIL_RAW}%" "$ALERT_THRESHOLD_UTIL" "greater" 2>/dev/null
          if [ -n "$UTIL_INT" ] && [ "$UTIL_INT" -gt "$ALERT_THRESHOLD_UTIL" ]; then
            ALERTS+=("High disk utilization on $DEVICE: ''${UTIL_INT}%")
          fi

          check_metric "Device $DEVICE await" "''${AWAIT_RAW}ms" "$ALERT_THRESHOLD_AWAIT" "greater" 2>/dev/null
          if [ -n "$AWAIT_INT" ] && [ "$AWAIT_INT" -gt "$ALERT_THRESHOLD_AWAIT" ]; then
            ALERTS+=("High disk latency on $DEVICE: ''${AWAIT_INT}ms")
          fi
        fi
      done < <(echo "$IOSTAT_OUTPUT" | awk 'BEGIN{p=0} /^Device/ {p=1; next} p==1{last[$1]=$0} END{for(k in last) print last[k]}')
    else
      echo "Disk I/O checks [SKIPPED — scrub running]"
    fi
    echo ""

    # 8. I/O Wait (skip during scrub)
    echo "--- CPU I/O Wait ---"
    if [ "$SCRUB_RUNNING" = false ]; then
      IOWAIT_RAW=$(iostat -c 1 2 2>/dev/null | awk '/^ /{val=$4} END{print val}')
      IOWAIT_INT=$(printf "%s" "$IOWAIT_RAW" | tr ',' '.' | awk '{printf("%d", $1)}')
      if ! check_metric "I/O Wait" "''${IOWAIT_RAW}%" "$ALERT_THRESHOLD_IOWAIT" "greater"; then
        ALERTS+=("High I/O wait: ''${IOWAIT_INT}% (threshold: ''${ALERT_THRESHOLD_IOWAIT}%)")
      fi
    else
      echo "I/O Wait [SKIPPED — scrub running]"
    fi
    echo ""

    # 9. Uptime
    echo "--- System Info ---"
    UPTIME=$(uptime -p 2>/dev/null || true)
    echo "Uptime: ''${UPTIME#up }"
    echo ""

    # Summary and Alerts
    echo "==================================="
    if [ ''${#ALERTS[@]} -eq 0 ]; then
      echo "ALL CHECKS PASSED"
      echo "System is healthy!"
    else
      echo "''${#ALERTS[@]} ALERT(S) DETECTED"
      echo ""
      for alert in "''${ALERTS[@]}"; do
        echo "  - $alert"
      done

      ALERT_MESSAGE=$(printf '%s\n' "''${ALERTS[@]}")
      send_alert "default" "ZFS System Alert - $POOL_NAME" "$ALERT_MESSAGE"
      exit 1
    fi

    exit 0
  '';
in
{
  environment.systemPackages = [ health-monitor ];

  systemd.services."health-monitor" = {
    description = "System Health Monitor with ntfy Alerts";
    path = with pkgs; [
      coreutils
      procps
      bc
      gnugrep
      gawk
      curl
      sysstat
      zfs
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${health-monitor}/bin/health-monitor";
    };
    wantedBy = [ "multi-user.target" ];
  };

  systemd.timers."health-monitor" = {
    description = "Run health monitor periodically";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      Unit = "health-monitor.service";
    };
  };
}
