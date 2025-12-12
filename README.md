# CCX Memory Leak Investigation

## Overview
 
Investigation of memory leaks in CCX messaging services, specifically focusing on the insights-core Broker component.                 
 
## Suspected Root Cause        
 
### Circular References in Exception Handling         
 
Objects reference each other in a cycle that prevents garbage collection: 
 
**The Problem:**               
- Python's GC can usually handle circular references  
- Exception tracebacks create circular refs that prevent GC               
- Specific issue: `Broker → exception → __traceback__ → frame → Broker`   
 
This circular reference chain keeps objects alive indefinitely, causing the memory leak pattern observed in production.               
 
---        
 
## Testing Methodology         
 
### 1. Baseline Testing        
 
Run locally in Podman to:      
- Send large volumes of data without ephemeral environment costs          
- Benchmark the performance    
 
### 2. Local Testing Setup     
 
#### Prerequisites             
 
**Local Deployment:**          
 
1. **Optional**:                  
   ```bash 
   # Inside ingress clone directory                   
   docker build . -t ingress:latest                   
   docker-compose -f development/local-dev-start.yml up                   
   ```     
 
2. **Start local environment:**
   ```bash 
   # Inside local deploy repo  
   docker compose up -d        
   ```     
 
3. **Setup archive sending script:**                  
   ```bash 
   # Inside the script-sending repo                   
   python3 -m venv venv        
   source venv/bin/activate    
   export PIP_INDEX_URL=https://repository.engineering.redhat.com/nexus/repository/insights-qe/simple             
   pip install -r requirements.txt
   ```     
 
---        
 
## Running Tests               
 
### Monitoring Memory Usage    
 
Start monitoring **before** sending archives:         
 
```bash    
./monitor_all_local.sh         
```        
 
This monitors all 5 ccx-messaging based containers every 5 seconds, capturing:            
- Docker stats (CPU, memory, network I/O)             
- Python GC statistics         
- /proc/meminfo snapshots      
 
### Sending Test Archives      
 
1. **Continuous Mode (4 hours, no breaks):**          
```bash    
python send_archives.py upload 
```                   
 
2. **Burst Mode (with 5-minute breaks):**                
```bash    
python send_archives.py upload --breaks               
```              
 
---        
 
## Containers Monitored        
 
1. **rules-uploader**   
2. **archive-sync**            
3. **archive-sync-ols** 
4. **multiplexor** 
5. **rules-processing**          
 
---        
 
## Expected Results            
 
### Healthy System             
- Stable memory at load
 
### Memory Leak (Current Behavior)
- Memory continuously climbs over time                         
 
---        
 
## Data Analysis               
 
Monitoring data is saved to timestamped directories:  
```        
local_monitoring_YYYYMMDD_HHMMSS/ 
├── <container>_docker_stats.csv  
├── <container>_gc_stats.csv   
└── <container>_proc_meminfo/  
```        
 
Key metrics to watch:          
- `mem_usage_mb` - Should stabilize or decrease after processing          
 
 
---        
 
## Files in This Repository    
 
- `send_archives.py` - Archive upload script with continuous/burst modes  
- `monitor_all_local.sh` - Comprehensive monitoring for all CCX containers
- `monitor_local.sh` - Single container monitoring script                 
- `local_monitoring_*/` - Monitoring data output directories              
- `README.md` - This file      
