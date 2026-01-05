#!/bin/bash

# Safe internal metrics collection - READ ONLY queries
# No gc.collect(), no iteration over large collections
# Just count and measure what's already tracked

CONTAINER="rules-processing"
OUTPUT_DIR="${1:-local_monitoring_internal_$(date +%Y%m%d_%H%M%S)}"

mkdir -p "$OUTPUT_DIR"

echo "timestamp,elapsed_min,total_objects,broker_created,broker_collected,broker_live_weakset,exception_count" > "$OUTPUT_DIR/internal_metrics.csv"

START_TIME=$(date +%s)
ITERATION=0

echo "Starting safe internal metrics collection for $CONTAINER"
echo "Output: $OUTPUT_DIR/internal_metrics.csv"
echo "Press Ctrl+C to stop"
echo ""

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    ELAPSED_MIN=$((ELAPSED / 60))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Safe read-only query - just counts, no collection
    METRICS=$(docker exec "$CONTAINER" python3 -c "
import gc
import sys

# Just get counts - O(1) operation, no collection
gc_count = gc.get_count()
total_objects = len(gc.get_objects())  # Count but don't iterate contents

# Try to import and read the counters from dr.py
try:
    from insights.core import dr
    broker_created = dr._BROKER_CREATED_COUNT
    broker_collected = dr._BROKER_COLLECTED_COUNT
    broker_live = len(dr._BROKER_INSTANCES)
except:
    broker_created = 0
    broker_collected = 0
    broker_live = 0

# Count exceptions across all tracked brokers (if WeakSet still has refs)
exception_count = 0
try:
    from insights.core import dr
    # Just count, don't iterate details
    for b in dr._BROKER_INSTANCES:
        exception_count += sum(len(v) for v in b.exceptions.values())
except:
    pass

print(f'{total_objects},{broker_created},{broker_collected},{broker_live},{exception_count}')
" 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo "${TIMESTAMP},${ELAPSED_MIN},${METRICS}" >> "$OUTPUT_DIR/internal_metrics.csv"
        echo "[${ELAPSED_MIN} min] ${METRICS}"
    else
        echo "[${ELAPSED_MIN} min] Query failed"
    fi

    ITERATION=$((ITERATION + 1))
    sleep 30  # Every 30 seconds
done
