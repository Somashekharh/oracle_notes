# =============================================================================
# Oracle DBA Task 5: Backup & Recovery - All Commands (Core Critical Task)
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as oracle user (RMAN) or SYSDBA (SQL)
# Assumes Task 1-4 are completed (database running)
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. CONFIGURE FAST RECOVERY AREA (FRA) - MUST DO FIRST
sqlplus / as sysdba << EOF
-- Set FRA size (adjust according to your storage)
ALTER SYSTEM SET db_recovery_file_dest_size = 100G SCOPE=BOTH;

-- Set FRA location
ALTER SYSTEM SET db_recovery_file_dest = '/u01/app/oracle/fast_recovery_area' SCOPE=BOTH;

-- Enable archivelog (mandatory for recovery)
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ARCHIVE LOG LIST;
EXIT;
EOF

# 3. RMAN CONFIGURATION (Run in RMAN prompt)
rman target /
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
CONFIGURE BACKUP OPTIMIZATION ON;
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/u01/app/oracle/fast_recovery_area/%F';
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/u01/app/oracle/fast_recovery_area/%U';
SHOW ALL;

# 4. FULL BACKUP (Level 0) - Complete backup
rman target / << EOF
RUN {
   BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 0 DATABASE PLUS ARCHIVELOG DELETE INPUT;
   BACKUP CURRENT CONTROLFILE;
}
LIST BACKUP SUMMARY;
EXIT;
EOF

# 5. INCREMENTAL LEVEL 1 BACKUP (Daily)
rman target / << EOF
RUN {
   BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 1 CUMULATIVE DATABASE PLUS ARCHIVELOG DELETE INPUT;
}
EXIT;
EOF

# 6. ARCHIVELOG BACKUP ONLY
rman target / << EOF
BACKUP ARCHIVELOG ALL NOT BACKED UP DELETE INPUT;
EXIT;
EOF

# 7. VALIDATE & CROSSCHECK BACKUPS
rman target / << EOF
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;
DELETE EXPIRED BACKUP;
DELETE NOPROMPT EXPIRED ARCHIVELOG ALL;
VALIDATE DATABASE;
VALIDATE RECOVERY AREA;
LIST FAILURE;
EXIT;
EOF

# 8. RESTORE & RECOVERY EXAMPLES

# a) Complete recovery (after media failure)
rman target / << EOF
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
RESTORE DATABASE;
RECOVER DATABASE;
ALTER DATABASE OPEN;
EXIT;
EOF

# b) Point-in-Time Recovery (PITR) - to a specific time
rman target / << EOF
RUN {
   SET UNTIL TIME "TO_DATE('2026-02-24 10:00:00','YYYY-MM-DD HH24:MI:SS')";
   RESTORE DATABASE;
   RECOVER DATABASE;
}
ALTER DATABASE OPEN RESETLOGS;
EXIT;
EOF

# c) Recover single tablespace
rman target / << EOF
RESTORE TABLESPACE USERS;
RECOVER TABLESPACE USERS;
EXIT;
EOF

# 9. FLASHBACK FEATURES (Very useful for logical corruption)
sqlplus / as sysdba << EOF
-- Enable Flashback Database (needs FRA)
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE FLASHBACK ON;
ALTER DATABASE OPEN;

-- Flashback Database to 2 hours ago
FLASHBACK DATABASE TO TIMESTAMP SYSDATE-2/24;
ALTER DATABASE OPEN RESETLOGS;

-- Flashback Table (needs row movement)
ALTER TABLE app_user.employees ENABLE ROW MOVEMENT;
FLASHBACK TABLE app_user.employees TO TIMESTAMP SYSDATE-1/24;
EXIT;
EOF

# 10. AUTOMATED BACKUP SCHEDULING (Using DBMS_SCHEDULER - Recommended)
sqlplus / as sysdba << EOF
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'DAILY_RMAN_FULL',
    job_type        => 'EXECUTABLE',
    job_action      => '/u01/scripts/rman_full_backup.sh',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0',
    enabled         => TRUE,
    comments        => 'Daily Full RMAN Backup at 2 AM'
  );
END;
/
EXIT;
EOF

# Create the shell script /u01/scripts/rman_full_backup.sh
cat > /u01/scripts/rman_full_backup.sh << 'EOF'
#!/bin/bash
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL
rman target / log=/u01/app/oracle/backup_logs/full_backup_$(date +%Y%m%d).log << EOR
BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 0 DATABASE PLUS ARCHIVELOG DELETE INPUT;
EXIT;
EOR
EOF
chmod +x /u01/scripts/rman_full_backup.sh

# 11. BACKUP CONFIGURATION FILES (Always do after any change)
cp $ORACLE_HOME/dbs/spfileORCL.ora /u01/app/oracle/backup_config/
cp $ORACLE_HOME/dbs/orapwORCL /u01/app/oracle/backup_config/
cp $ORACLE_HOME/network/admin/*.ora /u01/app/oracle/backup_config/
zip -r config_backup_$(date +%Y%m%d).zip /u01/app/oracle/backup_config/

# 12. DATA GUARD - Basic Physical Standby Setup (DR)
# On Primary:
ALTER DATABASE FORCE LOGGING;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORCL,ORCL_STBY)';
# (Full setup requires separate steps - use this as starting point)

# 13. DAILY BACKUP HEALTH CHECK
rman target / << EOF
REPORT NEED BACKUP;
REPORT OBSOLETE;
LIST BACKUP SUMMARY;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task5_backup_recovery_commands.txt
# Create directory: mkdir -p /u01/app/oracle/fast_recovery_area /u01/app/oracle/backup_logs /u01/scripts /u01/app/oracle/backup_config
# Always test recovery in a non-production environment!
# Replace ORCL with your SID and adjust paths/sizes as per your environment.
# For production: Use RMAN catalog + ZDLRA or Data Guard.
# =============================================================================