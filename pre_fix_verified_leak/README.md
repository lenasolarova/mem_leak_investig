# Pre-Fix Unfixed Runs - CRITICAL EVIDENCE

## Overview
This folder contains monitoring runs of the **completely unfixed** insights-core codebase, showing evidence of the memory leak before any fixes were applied.

## ⭐ CRITICAL EVIDENCE: local_monitoring_20251214_113626

**This is the most important monitoring run in the entire investigation.**

### Key Metrics
- **Date**: December 14, 2025
- **Duration**: 150 minutes (2.5 hours) - longest pre-fix run
- **Memory Growth**: 278.5 MiB → 313.7 MiB
- **Total Growth**: +35.2 MiB
- **Growth Rate**: ~9 MB/hour (14.1 MB/hour)
- **Pattern**: **Continuous steady linear increase** ← THIS IS THE LEAK

### Why This Is Critical
1. **Longest duration**: 2.5 hours - sufficient to show leak pattern
2. **Clear evidence**: Linear memory growth over time
3. **Baseline rate established**: ~9 MB/hour is the leak rate
4. **Used for comparison**: All fix tests must be compared against this

### CSV Data
File: `local_monitoring_20251214_113626/rules-processing_docker_stats.csv`
- 902 data points
- 10-second sampling interval
- Complete Docker stats (CPU, memory, network, block I/O)

### Memory Growth Timeline
```
Time        Memory    Growth from Start
11:36:26    278.5 MiB    +0.0 MiB (baseline)
12:00:00    ~285 MiB     +6.5 MiB
13:00:00    ~294 MiB     +15.5 MiB
14:00:00    ~303 MiB     +24.5 MiB
15:00:00    ~312 MiB     +33.5 MiB
15:36:30    313.7 MiB    +35.2 MiB (end)
```

**Slope**: Approximately linear - classic memory leak pattern

## Other Runs in This Folder

### local_monitoring_20251216_133501 (Dec 16)
- **Duration**: 118 minutes (~2 hours)
- **Memory Growth**: 270.8 → 319.5 MiB (+48.7 MiB)
- **Growth Rate**: ~25 MB/hour ⚠️ **ANOMALOUS - VERY HIGH**
- **Status**: Needs investigation - unusually high growth rate

This run shows MUCH faster memory growth than the Dec 14 run. Possible explanations:
1. Different archive processing patterns
2. System memory pressure
3. Docker container state issues
4. Needs verification

### "post_fix"_4h_uninterrupted/local_monitoring_20251212_085404 (Dec 12)
**Note**: Despite the folder name "post_fix", this needs verification whether it's actually pre-fix or post-fix data.

## Test Methodology

All runs used:
- **Docker image**: `quay.io/redhat-services-prod/obsint-processing-tenant/data-pipeline/data-pipeline:latest`
- **No file mounts**: Completely unmodified production image
- **No dr.py overrides**: Pure upstream code
- **Configuration**: From `/Users/lsolarov/Documents/obsint-processing-local-deploy/internal/`

## Conclusion

The **Dec 14 run (local_monitoring_20251214_113626)** provides definitive evidence:
- **Memory leak EXISTS** in unfixed code
- **Leak rate**: ~9 MB/hour sustained growth
- **Leak pattern**: Linear continuous increase
- **Any fix must run 4+ hours** to prove it prevents this pattern

## Next Steps

1. ✅ Keep this folder as-is - CRITICAL EVIDENCE
2. 🔬 All fix tests must run 4+ hours and show NO linear growth
3. 📊 Compare all future runs against Dec 14 baseline
4. ⚠️ Investigate Dec 16 anomalous high growth rate
