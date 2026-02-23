# =============================================================================
# Oracle DBA Task 3: Startup, Shutdown & Day-to-Day Operations - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as oracle user unless mentioned otherwise
# Assumes Task 1 & Task 2 are completed (software installed + database created)
# =============================================================================

# 1. ENVIRONMENT SETUP (Run every new session)
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL
# OR use your own SID: . oraenv <<< PRODDB

# Permanent setup (add to ~/.bash_profile)
cat >> ~/.bash_profile << 'EOF'
export ORACLE_SID=ORCL
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv
EOF

# 2. LISTENER MANAGEMENT
# Start listener
lsnrctl start

# Stop listener
lsnrctl stop

# Status
lsnrctl status

# Reload (after changes in listener.ora)
lsnrctl reload

# Check running listeners
ps -ef | grep tnslsnr

# 3. DATABASE INSTANCE STARTUP / SHUTDOWN
# Full startup (normal)
sqlplus / as sysdba << EOF
STARTUP;
EXIT;
EOF

# Startup in stages (for troubleshooting)
sqlplus / as sysdba << EOF
STARTUP NOMOUNT;          -- Only instance, no database
ALTER DATABASE MOUNT;     -- Mount control files
ALTER DATABASE OPEN;      -- Open database
EXIT;
EOF

# Startup with PFILE (if spfile corrupted)
sqlplus / as sysdba << EOF
STARTUP PFILE='$ORACLE_HOME/dbs/initORCL.ora';
EXIT;
EOF

# Shutdown options (choose one)
sqlplus / as sysdba << EOF
SHUTDOWN IMMEDIATE;       -- Recommended for production (fastest clean)
SHUTDOWN TRANSACTIONAL;   -- Waits for transactions to finish
SHUTDOWN NORMAL;          -- Waits for all users to disconnect
SHUTDOWN ABORT;           -- Immediate (like kill -9) - use only in emergency
EXIT;
EOF

# Restart in one command
sqlplus / as sysdba << EOF
SHUTDOWN IMMEDIATE;
STARTUP;
EXIT;
EOF

# 4. MULTITENANT - PDB STARTUP / SHUTDOWN
sqlplus / as sysdba << EOF
-- Show all PDBs
SHOW PDBS;

-- Open a specific PDB
ALTER PLUGGABLE DATABASE ORCLPDB1 OPEN;

-- Close a specific PDB
ALTER PLUGGABLE DATABASE ORCLPDB1 CLOSE IMMEDIATE;

-- Open ALL PDBs at once
ALTER PLUGGABLE DATABASE ALL OPEN;

-- Close ALL PDBs
ALTER PLUGGABLE DATABASE ALL CLOSE IMMEDIATE;

-- Save state so PDB opens automatically on CDB restart (23ai best practice)
ALTER PLUGGABLE DATABASE ORCLPDB1 SAVE STATE;
EXIT;
EOF

# 5. GRID INFRASTRUCTURE / RAC / ASM COMMANDS (if using Grid)
# Check cluster status
crsctl check crs
crsctl stat res -t

# Start/Stop database via srvctl (preferred in RAC/Grid)
srvctl start database -db ORCL
srvctl stop database -db ORCL -o immediate

# Start/Stop listener via srvctl
srvctl start listener
srvctl stop listener

# Start/Stop ASM
srvctl start asm
srvctl stop asm

# 6. DAY-TO-DAY OPERATIONS COMMANDS
# Check database status
sqlplus / as sysdba << EOF
SELECT name, open_mode, database_role FROM v\$database;
SELECT instance_name, status, startup_time FROM v\$instance;
SHOW PARAMETER spfile;
EXIT;
EOF

# Force log switch (manual)
sqlplus / as sysdba << EOF
ALTER SYSTEM SWITCH LOGFILE;
EXIT;
EOF

# Force checkpoint
sqlplus / as sysdba << EOF
ALTER SYSTEM CHECKPOINT;
EXIT;
EOF

# Switch to ARCHIVELOG / NOARCHIVELOG mode
sqlplus / as sysdba << EOF
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;     -- or NOARCHIVELOG
ALTER DATABASE OPEN;
ARCHIVE LOG LIST;
EXIT;
EOF

# 7. REAL-TIME MONITORING (Day-to-Day)
# Check sessions
sqlplus / as sysdba << EOF
SELECT username, sid, serial#, status, machine, program 
FROM v\$session 
WHERE username IS NOT NULL 
ORDER BY username;
EXIT;
EOF

# Check blocking sessions
sqlplus / as sysdba << EOF
SELECT blocking_session, sid, serial#, wait_class, seconds_in_wait 
FROM v\$session 
WHERE blocking_session IS NOT NULL;
EXIT;
EOF

# Alert log last 100 lines
adrci << EOF
SET HOME diag/rdbms/orcl/ORCL
SHOW ALERT -tail 100
EXIT;
EOF

# Tail alert log live (Linux)
tail -f $ORACLE_BASE/diag/rdbms/orcl/ORCL/trace/alert_ORCL.log

# Check free space
sqlplus / as sysdba << EOF
SELECT tablespace_name, round(sum(bytes)/1024/1024) AS free_mb 
FROM dba_free_space 
GROUP BY tablespace_name;
EXIT;
EOF

# 8. COMMON DAILY HEALTH-CHECK ONE-LINERS
echo "=== LISTENER ==="; lsnrctl status | grep "Service"
echo "=== DATABASE ==="; sqlplus -s / as sysdba << EOF
SET HEADING OFF
SELECT 'DB Name: '||name||'   Open Mode: '||open_mode FROM v\$database;
SELECT 'Instance: '||instance_name||'   Status: '||status FROM v\$instance;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task3_startup_shutdown_day_to_day_commands.txt
# Replace ORCL with your actual SID
# Always use SHUTDOWN IMMEDIATE in production
# For 24x7 systems, use srvctl instead of sqlplus shutdown
# =============================================================================