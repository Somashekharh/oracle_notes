# =============================================================================
# Oracle DBA Task 16: Troubleshooting & Incident Management - All Commands
# Oracle Database 23ai
# Date: February 2026
# Run as SYSDBA or oracle user
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. QUICK INCIDENT CHECKS
sqlplus / as sysdba << EOF
-- Blocking / Deadlocks
SELECT sid, serial#, blocking_session, event, seconds_in_wait 
FROM v\$session WHERE blocking_session IS NOT NULL;

-- Long running SQL
SELECT sql_id, elapsed_time/1000000 sec, executions, sql_text 
FROM v\$sql WHERE elapsed_time > 10000000 ORDER BY elapsed_time DESC;

-- Top waits
SELECT event, total_waits, time_waited/100 sec FROM v\$system_event 
WHERE wait_class <> 'Idle' ORDER BY time_waited DESC FETCH FIRST 10 ROWS ONLY;
EXIT;
EOF

# 3. ALERT LOG & TRACE ANALYSIS
adrci << EOF
SHOW ALERT -tail 300
SET HOME diag/rdbms/orcl/ORCL
SHOW PROBLEM
SHOW INCIDENT -mode DETAIL
EXIT;
EOF

# Live tail
tail -f $ORACLE_BASE/diag/rdbms/orcl/ORCL/trace/alert_ORCL.log

# 4. ENABLE SQL TRACE / TKPROF
sqlplus / as sysdba << EOF
-- For a specific session
EXEC DBMS_MONITOR.SESSION_TRACE_ENABLE(session_id => 123, serial_num => 456, waits => TRUE, binds => TRUE);

-- Disable
EXEC DBMS_MONITOR.SESSION_TRACE_DISABLE(session_id => 123, serial_num => 456);
EXIT;
EOF

# Generate report
tkprof ORCL_ora_12345.trc report.txt sys=no sort=prsela,exeela,fchela

# 5. ORA-600 / INTERNAL ERRORS
# Collect diagnostic
alter session set events '600 trace name errorstack level 3';

# Create SR package
@?/rdbms/admin/orasrp.sql   -- or use ADRCI: CREATE INCIDENT PACKAGE

# 6. DATA BLOCK CORRUPTION CHECK
rman target / << EOF
BACKUP VALIDATE DATABASE;
VALIDATE DATABASE;
EXIT;
EOF

dbv file=/u01/app/oracle/oradata/ORCL/users01.dbf blocksize=8192

# 7. DEADLOCK DETECTION
# Trace file will be generated automatically
# Search alert log for "Deadlock detected"
# Or query:
sqlplus / as sysdba << EOF
SELECT * FROM v\$deadlock;
EXIT;
EOF

# 8. COMMON QUICK FIX COMMANDS
-- Kill session
ALTER SYSTEM KILL SESSION '123,456' IMMEDIATE;

-- Flush shared pool (last resort)
ALTER SYSTEM FLUSH SHARED_POOL;

-- Clear buffer cache (last resort)
ALTER SYSTEM FLUSH BUFFER_CACHE;

# 9. OPEN SERVICE REQUEST (MOS)
# Collect RDA
rda.sh -v -p OracleDB -e

# Upload to SR

# =============================================================================
# END OF FILE
# After saving: chmod +x oracle_dba_task16_troubleshooting_incident_management_commands.txt
# Always collect 10053 trace for SQL issues
# Use ADRCI for all diagnostics in 23ai
# Document every incident in your runbook
# =============================================================================