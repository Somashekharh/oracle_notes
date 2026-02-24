# =============================================================================
# Oracle DBA Task 14: Automation & Scripting - All Commands
# Oracle Database 23ai
# Date: February 2026
# Run as oracle user
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL
mkdir -p /u01/scripts /u01/logs

# 2. DBMS_SCHEDULER - Database Jobs
sqlplus / as sysdba << EOF
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'DAILY_BACKUP',
    job_type        => 'EXECUTABLE',
    job_action      => '/u01/scripts/rman_full.sh',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=3',
    enabled         => TRUE,
    comments        => 'Daily RMAN backup'
  );
END;
/

-- List jobs
SELECT job_name, state, next_run_date FROM dba_scheduler_jobs;
EXIT;
EOF

# 3. SAMPLE SHELL SCRIPT - Daily RMAN Backup
cat > /u01/scripts/rman_full.sh << 'EOF'
#!/bin/bash
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL
rman target / log=/u01/logs/rman_full_$(date +%Y%m%d).log << EOR
BACKUP AS COMPRESSED BACKUPSET INCREMENTAL LEVEL 0 DATABASE PLUS ARCHIVELOG DELETE INPUT;
CROSSCHECK BACKUP;
DELETE NOPROMPT EXPIRED BACKUP;
EXIT;
EOR
EOF
chmod +x /u01/scripts/rman_full.sh

# 4. SAMPLE SHELL SCRIPT - Health Check
cat > /u01/scripts/health_check.sh << 'EOF'
#!/bin/bash
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL
sqlplus -s / as sysdba << SQL > /u01/logs/health_$(date +%Y%m%d).txt
SET PAGES 0
SELECT 'DB Status: ' || open_mode FROM v\$database;
SELECT 'Tablespace >90%: ' || tablespace_name FROM dba_tablespace_usage_metrics WHERE used_percent > 90;
SQL
echo "Health check completed - $(date)" >> /u01/logs/health.log
EOF
chmod +x /u01/scripts/health_check.sh

# 5. CRON EXAMPLE (Add to crontab -e)
# 0 2 * * * /u01/scripts/rman_full.sh >> /u01/logs/cron.log 2>&1
# 0 6 * * * /u01/scripts/health_check.sh

# 6. ADVANCED - Python + cx_Oracle Automation (optional)
cat > /u01/scripts/monitor_blocking.py << 'EOF'
import cx_Oracle
conn = cx_Oracle.connect("/ as sysdba")
cur = conn.cursor()
cur.execute("SELECT blocking_session FROM v\$session WHERE blocking_session IS NOT NULL")
for row in cur:
    print("Blocking session:", row[0])
cur.close()
conn.close()
EOF

# 7. ANSIBLE PLAYBOOK EXAMPLE (Modern Automation)
cat > backup_db.yml << 'EOF'
---
- name: Run RMAN backup
  hosts: dbservers
  become: yes
  tasks:
    - name: Execute RMAN
      shell: /u01/scripts/rman_full.sh
      register: result
    - name: Show output
      debug: var=result.stdout_lines
EOF

# 8. LIST ALL SCHEDULED JOBS
sqlplus / as sysdba << EOF
SELECT job_name, owner, state, next_run_date FROM dba_scheduler_jobs ORDER BY next_run_date;
SELECT program_name, action FROM dba_scheduler_programs;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving: chmod +x oracle_dba_task14_automation_scripting_commands.txt
# Create directories: mkdir -p /u01/scripts /u01/logs
# Add scripts to crontab for true automation
# Use DBMS_SCHEDULER for database-level jobs (better than OS cron)
# =============================================================================