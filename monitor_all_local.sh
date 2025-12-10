#!/bin/bash

# Comprehensive monitoring for all local CCX containers
# Captures docker stats, /proc/meminfo, and Python GC stats every minute

CCX_CONTAINERS=("rules-uploader" "archive-sync" "archive-sync-ols" "multiplexor" "rules-processing")
OUTPUT_DIR="local_monitoring_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$OUTPUT_DIR"

echo "Starting comprehensive monitoring for all CCX containers"
echo "Output directory: $OUTPUT_DIR"
echo "Monitoring containers: ${CCX_CONTAINERS[@]}"
echo ""

# Initialize CSV files for each container
for container in "${CCX_CONTAINERS[@]}"; do
    # Docker stats CSV
    echo "timestamp,elapsed_min,cpu_perc,mem_usage_mb,mem_limit_mb,mem_perc,net_io,block_io" > "$OUTPUT_DIR/${container}_docker_stats.csv"

    # GC stats CSV
    echo "timestamp,elapsed_min,gen0,gen1,gen2,collected,total_objects" > "$OUTPUT_DIR/${container}_gc_stats.csv"

    # Proc meminfo will be in separate files per iteration
    mkdir -p "$OUTPUT_DIR/${container}_proc_meminfo"
done

START_TIME=$(date +%s)
ITERATION=0

echo "Monitoring started at $(date)"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    ELAPSED_MIN=$((ELAPSED / 60))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    echo "=== Iteration $ITERATION - $TIMESTAMP (${ELAPSED_MIN} min) ==="

    for container in "${CCX_CONTAINERS[@]}"; do
        # Check if container is running
        if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "  [SKIP] $container - not running"
            continue
        fi

        echo "  [MONITORING] $container"

        # 1. Docker stats
        STATS=$(docker stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}}" "$container" 2>/dev/null)
        if [ $? -eq 0 ]; then
            # Parse memory usage (e.g., "123.4MiB / 7.654GiB" -> "123.4,7654")
            MEM_USAGE=$(echo "$STATS" | cut -d',' -f2 | awk '{print $1}' | sed 's/MiB//')
            MEM_LIMIT=$(echo "$STATS" | cut -d',' -f2 | awk '{print $3}' | sed 's/GiB//' | awk '{print $1 * 1024}')
            CPU_PERC=$(echo "$STATS" | cut -d',' -f1 | sed 's/%//')
            MEM_PERC=$(echo "$STATS" | cut -d',' -f3 | sed 's/%//')
            NET_IO=$(echo "$STATS" | cut -d',' -f4)
            BLOCK_IO=$(echo "$STATS" | cut -d',' -f5)

            echo "${TIMESTAMP},${ELAPSED_MIN},${CPU_PERC},${MEM_USAGE},${MEM_LIMIT},${MEM_PERC},${NET_IO},${BLOCK_IO}" >> "$OUTPUT_DIR/${container}_docker_stats.csv"
        fi

        # 2. Python GC stats
        GC_OUTPUT=$(docker exec "$container" python3 -c "
import gc
counts = gc.get_count()
collected = gc.collect()
total = sum(counts)
print(f'{counts[0]},{counts[1]},{counts[2]},{collected},{total}')
" 2>/dev/null)

        if [ $? -eq 0 ]; then
            echo "${TIMESTAMP},${ELAPSED_MIN},${GC_OUTPUT}" >> "$OUTPUT_DIR/${container}_gc_stats.csv"
        fi

        # 3. /proc/meminfo (save to individual file)
        docker exec "$container" cat /proc/meminfo > "$OUTPUT_DIR/${container}_proc_meminfo/meminfo_${ITERATION}.txt" 2>/dev/null
    done

    echo ""
    ITERATION=$((ITERATION + 1))
    sleep 5
done
