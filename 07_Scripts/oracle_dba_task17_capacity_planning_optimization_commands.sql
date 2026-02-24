# =============================================================================
# Oracle DBA Task 17: Capacity Planning & Optimization - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as SYSDBA
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. DATABASE GROWTH TREND (Last 30/90/365 days)
sqlplus / as sysdba << EOF
SET PAGES 999 LINES 200
PROMPT === TABLESPACE GROWTH TREND (Last 30 Days) ===
SELECT tablespace_name,
       ROUND(AVG(used_mb),2) AS avg_used_mb,
       ROUND(MAX(used_mb),2) AS max_used_mb,
       ROUND((MAX(used_mb)-MIN(used_mb))/30,2) AS daily_growth_mb
FROM (
  SELECT snap_time, tablespace_name, used_mb
  FROM dba_hist_tbspc_space_usage
  WHERE snap_time > SYSDATE-30
)
GROUP BY tablespace_name
ORDER BY daily_growth_mb DESC;

PROMPT === DATAFILE SIZE FORECAST (Next 90 Days) ===
SELECT tablespace_name,
       ROUND(SUM(bytes)/1024/1024/1024,2) AS current_gb,
       ROUND(SUM(bytes)/1024/1024/1024 * 1.3,2) AS forecast_90days_gb
FROM dba_data_files
GROUP BY tablespace_name;
EXIT;
EOF

# 3. CPU & MEMORY USAGE TREND (AWR based)
sqlplus / as sysdba << EOF
-- Average CPU usage last 7 days
SELECT snap_id, begin_time, end_time, 
       ROUND(100 * (value / (elapsed_time/1000000)),2) AS cpu_usage_pct
FROM dba_hist_sysmetric_summary
WHERE metric_name = 'Host CPU Utilization (%)'
  AND begin_time > SYSDATE-7
ORDER BY begin_time;

-- Peak memory usage
SELECT * FROM v\$resource_limit 
WHERE resource_name IN ('processes','sessions','sessions_max','cpu_count');
EXIT;
EOF

# 4. I/O & STORAGE FORECAST
sqlplus / as sysdba << EOF
SELECT name, type, total_mb, free_mb, usable_file_mb,
       ROUND((total_mb - free_mb)/total_mb*100,2) AS used_pct
FROM v\$asm_diskgroup;   -- If using ASM

-- Physical I/O trend
SELECT snap_id, begin_time, physical_read_total_mb, physical_write_total_mb
FROM dba_hist_sysstat
WHERE stat_name LIKE '%physical%total bytes%'
  AND begin_time > SYSDATE-30;
EXIT;
EOF

# 5. OPTIMIZATION RECOMMENDATIONS
sqlplus / as sysdba << EOF
-- Check for In-Memory Column Store opportunity
SELECT segment_name, populate_status, inmemory_size/1024/1024/1024 AS gb_inmemory
FROM v\$im_segments;

-- Recommend larger SGA/PGA
SHOW PARAMETER sga_target
SHOW PARAMETER pga_aggregate_target
SHOW PARAMETER memory_target;

-- Enable Automatic Memory Management if not set
ALTER SYSTEM SET memory_target = 16G SCOPE=SPFILE;   -- Adjust based on server RAM
EXIT;
EOF

# 6. CAPACITY PLANNING REPORT (One-command HTML export)
sqlplus / as sysdba << EOF
SET PAGES 999 LINES 200
SPOOL /u01/reports/capacity_plan_$(date +%Y%m%d).html
PROMPT <h1>Oracle Capacity Planning Report - $(date)</h1>
PROMPT <h2>1. Tablespace Growth</h2>
[run growth query above]
PROMPT <h2>2. CPU/Memory Trend</h2>
[run CPU query]
PROMPT <h2>3. Recommendations</h2>
PROMPT Next hardware upgrade recommended in XX days
SPOOL OFF
EXIT;
EOF

# 7. CLOUD MIGRATION / EXADATA SIZING
# Example OCI sizing query
SELECT SUM(bytes)/1024/1024/1024 AS total_db_size_gb FROM dba_segments;

# 8. MONTHLY CAPACITY REVIEW COMMANDS
-- Archive old AWR data
EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(retention => 20160); -- 14 days

# =============================================================================
# END OF FILE
# After saving: chmod +x oracle_dba_task17_capacity_planning_optimization_commands.txt
# Run monthly
# Combine with AWR/ADDM reports for accurate forecasting
# Use Oracle Enterprise Manager Capacity Planning reports for GUI version
# =============================================================================