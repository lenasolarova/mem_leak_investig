#!/bin/bash

# Monitor local Docker containers for memory usage
# Similar to monitor_baseline.sh but for local containers

CONTAINER_NAME="${1:-rules-uploader}"
OUTPUT_FILE="baseline_${CONTAINER_NAME}_LOCAL.csv"

echo "Starting memory monitoring for local container: ${CONTAINER_NAME}"
echo "Output will be saved to: ${OUTPUT_FILE}"
echo ""

# Initialize CSV with headers
echo "timestamp,elapsed_min,memory_mi,gen0,gen1,gen2,collected,total_objects" > "$OUTPUT_FILE"

START_TIME=$(date +%s)
ITERATION=0

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    ELAPSED_MIN=$((ELAPSED / 60))

    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Get memory usage from docker stats
    MEMORY_MB=$(docker stats --no-stream --format "{{.MemUsage}}" "$CONTAINER_NAME" | awk '{print $1}' | sed 's/MiB//')

    # Get GC stats from inside the container
    GC_OUTPUT=$(docker exec "$CONTAINER_NAME" python3 -c "
import gc
counts = gc.get_count()
collected = gc.collect()
total = sum(counts)
print(f'{counts[0]},{counts[1]},{counts[2]},{collected},{total}')
" 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo "${TIMESTAMP},${ELAPSED_MIN},${MEMORY_MB},${GC_OUTPUT}" >> "$OUTPUT_FILE"
        echo "[${ITERATION}] ${TIMESTAMP} - Memory: ${MEMORY_MB}MiB, Elapsed: ${ELAPSED_MIN}min"
    else
        echo "[${ITERATION}] ${TIMESTAMP} - Failed to get GC stats from container"
    fi

    ITERATION=$((ITERATION + 1))
    sleep 60
done
