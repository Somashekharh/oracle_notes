# =============================================================================
# Oracle DBA Task 6: Performance Monitoring & Tuning - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as SYSDBA or with AWR/ADDM privileges
# Assumes Task 1-5 are completed (database running + AWR licensed)
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. REAL-TIME MONITORING (V$ Views) - Most Used Daily
sqlplus / as sysdba << EOF
-- Top 10 Sessions by CPU
SELECT * FROM (
  SELECT sid, serial#, username, sql_id, cpu_time/1000000 AS cpu_sec, status
  FROM v\$session
  ORDER BY cpu_time DESC
) WHERE ROWNUM <= 10;

-- Top 10 SQL by Elapsed Time (last 5 min)
SELECT * FROM (
  SELECT sql_id, executions, round(elapsed_time/1000000,2) AS elapsed_sec,
         disk_reads, buffer_gets, sql_text
  FROM v\$sql
  ORDER BY elapsed_time DESC
) WHERE ROWNUM <= 10;

-- Current Wait Events
SELECT event, total_waits, time_waited/100 AS time_sec
FROM v\$system_event
WHERE time_waited > 0
ORDER BY time_waited DESC;

-- Blocking Sessions
SELECT blocking_session, sid, serial#, wait_class, seconds_in_wait
FROM v\$session
WHERE blocking_session IS NOT NULL;
EXIT;
EOF

# 3. AUTOMATIC WORKLOAD REPOSITORY (AWR) - Best for Historical Analysis
# Enable AWR (default every hour)
sqlplus / as sysdba << EOF
EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(interval => 60, retention => 20160); -- 14 days
EXIT;
EOF

# Generate AWR Report (HTML - best format)
sqlplus / as sysdba << EOF
@?/rdbms/admin/awrrpt.sql
EOF
# When prompted: Choose HTML, enter begin/end snapshot ID, filename awr_report.html

# Generate AWR for specific PDB (23ai)
sqlplus / as sysdba << EOF
ALTER SESSION SET CONTAINER=ORCLPDB1;
@?/rdbms/admin/awrrpt.sql
EXIT;
EOF

# 4. AUTOMATIC DATABASE DIAGNOSTIC MONITOR (ADDM)
sqlplus / as sysdba << EOF
@?/rdbms/admin/addmrpt.sql
EOF
# Choose begin/end snapshot → generates addm_report.txt (follow recommendations!)

# 5. ACTIVE SESSION HISTORY (ASH) REPORT
sqlplus / as sysdba << EOF
@?/rdbms/admin/ashrpt.sql
EOF
# Choose HTML, time range → ashrpt.html

# 6. SQL TUNING ADVISOR (Best for Slow Queries)
sqlplus / as sysdba << EOF
-- Create tuning task for a SQL_ID (get SQL_ID from v\$sql above)
VARIABLE task_id NUMBER;
BEGIN
  :task_id := DBMS_SQLTUNE.CREATE_TUNING_TASK(
    sql_id => 'your_sql_id_here',
    task_name => 'TUNE_SLOW_SQL1'
  );
END;
/

-- Execute the task
EXEC DBMS_SQLTUNE.EXECUTE_TUNING_TASK(task_name => 'TUNE_SLOW_SQL1');

-- Generate report
SET LONG 999999
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK('TUNE_SLOW_SQL1') FROM DUAL;
EXIT;
EOF

# Accept SQL Profile (if recommended)
sqlplus / as sysdba << EOF
EXEC DBMS_SQLTUNE.ACCEPT_SQL_PROFILE(task_name => 'TUNE_SLOW_SQL1');
EXIT;
EOF

# 7. MEMORY TUNING COMMANDS
sqlplus / as sysdba << EOF
-- Current memory settings
SHOW PARAMETER sga_target
SHOW PARAMETER pga_aggregate_target
SHOW PARAMETER memory_target

-- Increase SGA (example)
ALTER SYSTEM SET sga_target = 6G SCOPE=BOTH;

-- Increase PGA
ALTER SYSTEM SET pga_aggregate_target = 2G SCOPE=BOTH;

-- Enable Automatic Memory Management (AMM)
ALTER SYSTEM SET memory_target = 8G SCOPE=SPFILE;
ALTER SYSTEM SET sga_target = 0 SCOPE=SPFILE;
ALTER SYSTEM SET pga_aggregate_target = 0 SCOPE=SPFILE;

-- In-Memory Column Store (23ai powerful feature)
ALTER SYSTEM SET inmemory_size = 4G SCOPE=SPFILE;
EXIT;
EOF

# Restart after memory_target change: SHUTDOWN IMMEDIATE; STARTUP;

# 8. INDEX & STATISTICS TUNING
sqlplus / as sysdba << EOF
-- Gather statistics (best practice)
EXEC DBMS_STATS.GATHER_DATABASE_STATS(auto_sample_size => TRUE);

-- Rebuild fragmented index
ALTER INDEX app_user.idx_employee REBUILD ONLINE;

-- Create invisible index (test without affecting queries)
CREATE INDEX idx_test ON app_user.employees(dept_id) INVISIBLE;
ALTER INDEX idx_test VISIBLE;
EXIT;
EOF

# 9. REAL-TIME SQL MONITORING (for long running SQL)
sqlplus / as sysdba << EOF
-- Monitor a running SQL (use SQL_ID)
SELECT sql_id, sql_text, status, elapsed_time/1000000 AS elapsed_sec
FROM v\$sql_monitor
WHERE status = 'EXECUTING';

-- Generate HTML report for a SQL
SET LONG 1000000
SELECT DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id => 'your_sql_id', type => 'HTML') FROM DUAL;
EXIT;
EOF

# 10. DAILY PERFORMANCE HEALTH CHECK SCRIPT (One command)
sqlplus / as sysdba << EOF
-- Top 5 wait events last hour
SELECT * FROM (
  SELECT wait_class, event, round(time_waited/100,2) AS time_sec
  FROM v\$system_event
  ORDER BY time_waited DESC
) WHERE ROWNUM <= 5;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task6_performance_monitoring_tuning_commands.txt
# Replace ORCL / ORCLPDB1 with your SID/PDB
# Replace 'your_sql_id_here' with actual SQL_ID from v\$sql
# AWR/ADDM/SQL Tuning requires Diagnostics + Tuning Pack license (Enterprise Edition)
# Run AWR/ADDM reports every day in production!
# =============================================================================