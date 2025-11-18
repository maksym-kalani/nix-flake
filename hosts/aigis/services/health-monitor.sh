#!/usr/bin/env bash

# Enforce C locale to avoid commas as decimal separators, etc.
export LC_ALL=C
export LANG=C

# ZFS System Health Monitor with ntfy Alerts
# Configuration
NTFY_URL="http://localhost:8081/homelab"  # Change this to your ntfy topic
POOL_NAME="tank2"
CPU_CORES=12
ALERT_THRESHOLD_LOAD=10
ALERT_THRESHOLD_FRAG=50
ALERT_THRESHOLD_ARC_HIT=80
ALERT_THRESHOLD_IOWAIT=30
ALERT_THRESHOLD_UTIL=95
ALERT_THRESHOLD_AWAIT=50

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to send ntfy notification
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

# Function to check and report metric
check_metric() {
    local name=$1
    local value=$2        # may include units like % or ms
    local threshold=$3    # numeric (unitless)
    local comparison=$4   # "less" or "greater"
    local status="OK"
    local color=$GREEN

    # Normalize number: replace comma with dot, strip non-numeric except dot and minus
    local num
    num=$(printf "%s" "$value" | tr ',' '.' | sed 's/[^0-9.\-]//g')
    # Fallback to 0 if empty after sanitization
    if [ -z "$num" ]; then num=0; fi

    if [ "$comparison" = "greater" ]; then
        if (( $(echo "$num > $threshold" | bc -l) )); then
            status="ALERT"
            color=$RED
            echo -e "${color}${name}: ${value} [${status}]${NC}"
            return 1
        elif (( $(echo "$num > $threshold * 0.8" | bc -l) )); then
            status="WARNING"
            color=$YELLOW
        fi
    elif [ "$comparison" = "less" ]; then
        if (( $(echo "$num < $threshold" | bc -l) )); then
            status="ALERT"
            color=$RED
            echo -e "${color}${name}: ${value} [${status}]${NC}"
            return 1
        elif (( $(echo "$num < $threshold * 1.2" | bc -l) )); then
            status="WARNING"
            color=$YELLOW
        fi
    fi

    echo -e "${color}${name}: ${value} [${status}]${NC}"
    return 0
}

echo "=== ZFS SYSTEM HEALTH CHECK ==="
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

ALERTS=()

# 1. Load Average
echo "--- Load Average ---"
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
LOAD_5MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | tr -d ' ')
LOAD_15MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $3}' | tr -d ' ')

if ! check_metric "Load (1min)" "$LOAD_1MIN" "$ALERT_THRESHOLD_LOAD" "greater"; then
    ALERTS+=("High load average: $LOAD_1MIN (threshold: $ALERT_THRESHOLD_LOAD)")
fi
echo "Load (5min): $LOAD_5MIN"
echo "Load (15min): $LOAD_15MIN"
echo ""

# 2. Stuck Processes
echo "--- Stuck Processes ---"
STUCK_COUNT=$(ps aux | awk '$8 ~ /D/' | wc -l)
if ! check_metric "D-state processes" "$STUCK_COUNT" "0" "greater"; then
    STUCK_PROCS=$(ps aux | awk '$8 ~ /D/ {print $11}' | tr '\n' ', ')
    ALERTS+=("$STUCK_COUNT processes stuck in D state: $STUCK_PROCS")
fi
echo ""

# 3. ZFS Pool Health
echo "--- ZFS Pool Health ---"
POOL_HEALTH=$(zpool list -Ho health "$POOL_NAME" 2>/dev/null)
if [ "$POOL_HEALTH" != "ONLINE" ]; then
    echo -e "${RED}Pool Health: $POOL_HEALTH [ALERT]${NC}"
    ALERTS+=("ZFS pool $POOL_NAME is $POOL_HEALTH (not ONLINE)")
else
    echo -e "${GREEN}Pool Health: $POOL_HEALTH [OK]${NC}"
fi

# Check for errors
ERRORS=$(zpool status "$POOL_NAME" | grep -E "errors:" | awk '{print $2}')
if [ "$ERRORS" != "No" ]; then
    echo -e "${RED}Pool Errors: $ERRORS [ALERT]${NC}"
    ALERTS+=("ZFS pool has errors: $ERRORS")
else
    echo -e "${GREEN}Pool Errors: None [OK]${NC}"
fi
echo ""

# 4. Fragmentation
echo "--- Fragmentation ---"
FRAG=$(zpool list -Ho frag "$POOL_NAME" | tr -d '%')
if ! check_metric "Fragmentation" "${FRAG}%" "$ALERT_THRESHOLD_FRAG" "greater"; then
    ALERTS+=("High fragmentation: ${FRAG}% (threshold: ${ALERT_THRESHOLD_FRAG}%)")
fi
echo ""

# 5. Memory Usage
echo "--- Memory ---"
MEM_TOTAL=$(free -h | grep Mem | awk '{print $2}')
MEM_USED=$(free -h | grep Mem | awk '{print $3}')
MEM_PERCENT=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100}')
echo "Memory: $MEM_USED / $MEM_TOTAL (${MEM_PERCENT}%)"
echo ""

# 6. ARC Statistics
echo "--- ZFS ARC ---"
ARC_HITS=$(grep "^hits " /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
ARC_MISSES=$(grep "^misses " /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
ARC_TOTAL=$((ARC_HITS + ARC_MISSES))
if [ $ARC_TOTAL -gt 0 ]; then
    ARC_HIT_RATIO=$(echo "scale=1; ($ARC_HITS * 100) / $ARC_TOTAL" | bc)
    if ! check_metric "ARC Hit Ratio" "${ARC_HIT_RATIO}%" "$ALERT_THRESHOLD_ARC_HIT" "less"; then
        ALERTS+=("Low ARC hit ratio: ${ARC_HIT_RATIO}% (threshold: ${ALERT_THRESHOLD_ARC_HIT}%)")
    fi
fi
echo ""

# 7. Disk I/O Statistics
echo "--- Disk I/O ---"
# Get 2 samples 1 second apart to calculate rates
IOSTAT_OUTPUT=$(iostat -x sda sdb 1 2 2>/dev/null)

# Parse the last sample lines for the listed devices without using a pipe (to preserve ALERTS)
while read -r line; do
    if [[ $line == sda* ]] || [[ $line == sdb* ]]; then
        DEVICE=$(echo "$line" | awk '{print $1}')
        # %util is last column; await is typically column 10 under LC_ALL=C for Linux iostat
        UTIL_RAW=$(echo "$line" | awk '{print $NF}')
        AWAIT_RAW=$(echo "$line" | awk '{print $10}')

        # Sanitize and convert to integers for threshold comparisons
        UTIL_INT=$(printf "%s" "$UTIL_RAW" | tr ',' '.' | awk '{printf("%d", $1)}')
        AWAIT_INT=$(printf "%s" "$AWAIT_RAW" | tr ',' '.' | awk '{printf("%d", $1)}')

        echo -n "Device $DEVICE: "
        check_metric "util" "${UTIL_RAW}%" "$ALERT_THRESHOLD_UTIL" "greater" 2>/dev/null
        if [ -n "$UTIL_INT" ] && [ "$UTIL_INT" -gt "$ALERT_THRESHOLD_UTIL" ]; then
            ALERTS+=("High disk utilization on $DEVICE: ${UTIL_INT}%")
        fi

        echo -n "  "
        check_metric "await" "${AWAIT_RAW}ms" "$ALERT_THRESHOLD_AWAIT" "greater" 2>/dev/null
        if [ -n "$AWAIT_INT" ] && [ "$AWAIT_INT" -gt "$ALERT_THRESHOLD_AWAIT" ]; then
            ALERTS+=("High disk latency on $DEVICE: ${AWAIT_INT}ms")
        fi
    fi
done < <(echo "$IOSTAT_OUTPUT" | awk 'BEGIN{p=0} /^Device/ {p=1; next} p==1{last[$1]=$0} END{for(k in last) print last[k]}' )
echo ""

# 8. I/O Wait
echo "--- CPU I/O Wait ---"
IOWAIT_RAW=$(iostat -c 1 2 2>/dev/null | awk '/^ /{val=$4} END{print val}')
IOWAIT_INT=$(printf "%s" "$IOWAIT_RAW" | tr ',' '.' | awk '{printf("%d", $1)}')
if ! check_metric "I/O Wait" "${IOWAIT_RAW}%" "$ALERT_THRESHOLD_IOWAIT" "greater"; then
    ALERTS+=("High I/O wait: ${IOWAIT_INT}% (threshold: ${ALERT_THRESHOLD_IOWAIT}%)")
fi
echo ""

# 9. Uptime
echo "--- System Info ---"
UPTIME=$(uptime -p 2>/dev/null || true)
echo "Uptime: ${UPTIME#up }"
echo ""

# Summary and Alerts
echo "==================================="
if [ ${#ALERTS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
    echo "System is healthy!"
else
    echo -e "${RED}⚠️  ${#ALERTS[@]} ALERT(S) DETECTED${NC}"
    echo ""
    for alert in "${ALERTS[@]}"; do
        echo -e "${RED}  • $alert${NC}"
    done
    
    # Send ntfy notification
    ALERT_MESSAGE=$(printf '%s\n' "${ALERTS[@]}")
    send_alert "default" "ZFS System Alert - $POOL_NAME" "$ALERT_MESSAGE"
    
    exit 1
fi

exit 0