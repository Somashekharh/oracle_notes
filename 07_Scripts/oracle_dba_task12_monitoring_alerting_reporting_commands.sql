# =============================================================================
# Oracle DBA Task 12: Monitoring, Alerting & Reporting - All Commands
# Oracle Database 23ai (Enterprise Edition)
# Date: February 2026
# Run as SYSDBA or with OEM access
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. ALERT LOG MONITORING
adrci << EOF
SHOW ALERT -tail 200
SET HOME diag/rdbms/orcl/ORCL
SHOW ALERT -tail -f   -- Live tail
EXIT;
EOF

# Tail alert log from shell
tail -f $ORACLE_BASE/diag/rdbms/orcl/ORCL/trace/alert_ORCL.log

# 3. ENTERPRISE MANAGER (OEM) 24c - Quick Setup Commands
# Start OMS (if installed)
emctl start oms
emctl status oms

# Create Blackout
emctl start blackout PROD_DB_BLACKOUT ORCL -d 60

# 4. SET UP METRIC ALERTS (via SQL)
sqlplus / as sysdba << EOF
-- Tablespace >90% alert (example)
BEGIN
  DBMS_SERVER_ALERT.SET_THRESHOLD(
    metrics_id              => DBMS_SERVER_ALERT.TABLESPACE_PCT_FULL,
    warning_operator        => DBMS_SERVER_ALERT.OPERATOR_GE,
    warning_value           => '90',
    critical_operator       => DBMS_SERVER_ALERT.OPERATOR_GE,
    critical_value          => '95',
    observation_period      => 1,
    consecutive_occurrences => 1,
    object_type             => DBMS_SERVER_ALERT.OBJECT_TYPE_TABLESPACE,
    object_name             => 'USERS');
END;
/
EXIT;
EOF

# 5. DAILY HEALTH CHECK REPORT (Copy-paste ready)
sqlplus / as sysdba << EOF
SET PAGES 999 LINES 200
PROMPT === DATABASE STATUS ===
SELECT name, open_mode, database_role, created FROM v\$database;

PROMPT === INSTANCE STATUS ===
SELECT instance_name, status, startup_time FROM v\$instance;

PROMPT === PDB STATUS ===
SHOW PDBS;

PROMPT === TABLESPACE USAGE ===
SELECT tablespace_name, ROUND(used_percent,2) pct_used FROM dba_tablespace_usage_metrics;

PROMPT === TOP 5 WAIT EVENTS ===
SELECT * FROM (SELECT event, total_waits, time_waited/100 sec FROM v\$system_event ORDER BY time_waited DESC) WHERE ROWNUM<=5;

PROMPT === BLOCKING SESSIONS ===
SELECT blocking_session, sid, serial#, seconds_in_wait FROM v\$session WHERE blocking_session IS NOT NULL;
EXIT;
EOF

# 6. AUTOMATED DAILY REPORT (Shell + SQL)
cat > /u01/scripts/daily_health_check.sh << 'EOF'
#!/bin/bash
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL
sqlplus -s / as sysdba @/u01/scripts/daily_report.sql > /u01/reports/daily_$(date +%Y%m%d).html
EOF
chmod +x /u01/scripts/daily_health_check.sh

# 7. LISTENER & NETWORK MONITORING
lsnrctl status
tnsping ORCL

# 8. OEM METRIC ALERT HISTORY
sqlplus / as sysdba << EOF
SELECT target_name, metric_column, value, critical_value, occurrence_date
FROM mgmt$alert_history
ORDER BY occurrence_date DESC
FETCH FIRST 20 ROWS ONLY;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving: chmod +x oracle_dba_task12_monitoring_alerting_reporting_commands.txt
# Create directories: mkdir -p /u01/scripts /u01/reports
# For full GUI monitoring use Oracle Enterprise Manager Cloud Control 24c
# =============================================================================