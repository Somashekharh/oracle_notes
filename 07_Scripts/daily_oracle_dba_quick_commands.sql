# =============================================================================
# DAILY ORACLE DBA QUICK COMMAND BIBLE - 2026 (23ai)
# Most frequently used commands by Oracle DBAs (daily/hourly)
# Save this file and keep it open every day!
# =============================================================================

# ====================== 1. LINUX / UNIX SHELL (Most Used) ======================
ps -ef | grep -E 'ora_|pmon|tnslsnr'          # All Oracle processes
ps -ef | grep pmon                            # Only database instances
top -c -u oracle                              # CPU/Memory usage (oracle user)
df -h                                         # Disk space
df -h /u01                                    # Oracle home disk
free -g                                       # RAM usage
tail -f $ORACLE_BASE/diag/rdbms/*/trace/alert*.log   # Live alert log
ls -ltr $ORACLE_BASE/diag/rdbms/*/trace/alert*.log   # Latest alert logs
du -sh /u01/app/oracle/fast_recovery_area     # FRA size
lsnrctl status                                # Listener status

# ====================== 2. LISTENER & BASIC INSTANCE ===========================
lsnrctl start
lsnrctl stop
lsnrctl status
lsnrctl services
tnsping ORCL                                  # Test connectivity

. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL   # Set environment

# ====================== 3. DATABASE & PDB STATUS (Run every morning) ===========
sqlplus / as sysdba << EOF
SELECT name, open_mode, database_role FROM v\$database;
SELECT instance_name, status, startup_time FROM v\$instance;
SHOW PDBS;
EXIT;
EOF

# ====================== 4. SESSION & PERFORMANCE (Most Frequent) ===============
sqlplus / as sysdba << EOF
-- Blocking sessions (Critical!)
SELECT blocking_session, sid, serial#, username, event, seconds_in_wait 
FROM v\$session WHERE blocking_session IS NOT NULL;

-- Top 10 CPU consuming sessions
SELECT * FROM (SELECT sid, serial#, username, cpu_time/1000000 cpu_sec 
FROM v\$session ORDER BY cpu_time DESC) WHERE ROWNUM <= 10;

-- Top 10 long running SQL
SELECT sql_id, elapsed_time/1000000 sec, sql_text 
FROM v\$sql WHERE elapsed_time > 5000000 ORDER BY elapsed_time DESC FETCH FIRST 10 ROWS ONLY;

-- Current wait events
SELECT event, total_waits, time_waited/100 sec FROM v\$system_event 
WHERE time_waited > 0 ORDER BY time_waited DESC FETCH FIRST 10 ROWS ONLY;
EXIT;
EOF

# ====================== 5. SPACE & TABLESPACE (Daily Check) ====================
sqlplus / as sysdba << EOF
-- Tablespace usage %
SELECT tablespace_name, round(used_percent,2) pct_used 
FROM dba_tablespace_usage_metrics WHERE used_percent > 85;

-- Free space summary
SELECT tablespace_name, round(sum(bytes)/1024/1024) free_mb 
FROM dba_free_space GROUP BY tablespace_name;
EXIT;
EOF

# ====================== 6. BACKUP & RECOVERY QUICK CHECK ======================
rman target / << EOF
LIST BACKUP SUMMARY;
REPORT NEED BACKUP;
CROSSCHECK BACKUP;
EXIT;
EOF

# Last backup status
sqlplus / as sysdba << EOF
SELECT start_time, end_time, status, input_type 
FROM v\$rman_backup_job_details ORDER BY start_time DESC FETCH FIRST 5 ROWS ONLY;
EXIT;
EOF

# ====================== 7. MULTITENANT (CDB/PDB) DAILY ========================
sqlplus / as sysdba << EOF
SHOW PDBS;
SELECT name, open_mode FROM v\$pdbs;
ALTER PLUGGABLE DATABASE ALL OPEN;   -- Open all PDBs if needed
EXIT;
EOF

# ====================== 8. ALERT LOG & DIAGNOSTICS (ADRCI) ====================
adrci << EOF
SET HOME diag/rdbms/orcl/ORCL
SHOW ALERT -tail 100
SHOW PROBLEM
EXIT;
EOF

tail -200 $ORACLE_BASE/diag/rdbms/orcl/ORCL/trace/alert_ORCL.log | tail -100

# ====================== 9. USEFUL ONE-LINERS & TRICKS =========================
# Kill blocking session
sqlplus / as sysdba << EOF
ALTER SYSTEM KILL SESSION '123,456' IMMEDIATE;
EOF

# Force log switch
sqlplus / as sysdba << EOF
ALTER SYSTEM SWITCH LOGFILE;
EOF

# Quick health check (copy-paste)
sqlplus -s / as sysdba << EOF
SET HEADING OFF
SELECT 'DB: '||name||'  Mode: '||open_mode FROM v\$database;
SELECT 'Blocking: '||count(*) FROM v\$session WHERE blocking_session IS NOT NULL;
SELECT 'Tablespace >90%: '||count(*) FROM dba_tablespace_usage_metrics WHERE used_percent > 90;
EXIT;
EOF

# Find large objects
sqlplus / as sysdba << EOF
SELECT owner, segment_name, bytes/1024/1024 mb 
FROM dba_segments ORDER BY bytes DESC FETCH FIRST 10 ROWS ONLY;
EXIT;
EOF

# =============================================================================
# DAILY ROUTINE CHECKLIST (Do this every morning)
# 1. ps -ef | grep pmon
# 2. lsnrctl status
# 3. Alert log tail
# 4. Blocking sessions check
# 5. Tablespace usage
# 6. RMAN backup status
# 7. PDB status
# =============================================================================

# Pro Tips from Senior DBAs:
# - Keep this file open in Notepad++/VS Code
# - Create alias in .bash_profile: alias ora='sqlplus / as sysdba'
# - Use screen/tmux for long sessions
# - Always run as oracle user (not root)
# =============================================================================