# =============================================================================
# Oracle DBA Task 10: High Availability (HA) & Replication - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as oracle user (srvctl) or SYSDBA (SQL)
# Assumes Task 1-9 are completed + Grid Infrastructure installed for RAC/Data Guard
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. ORACLE RAC (Real Application Clusters) - Basic Commands
# Check cluster status
crsctl check crs
crsctl stat res -t
srvctl status database -db ORCL
srvctl status asm
srvctl status listener

# Start/Stop RAC database (rolling - zero downtime)
srvctl start database -db ORCL -startoption open
srvctl stop database -db ORCL -stopoption immediate -force

# Add new instance/node
srvctl add instance -db ORCL -instance ORCL3 -node racnode3
srvctl start instance -db ORCL -instance ORCL3

# Remove instance
srvctl remove instance -db ORCL -instance ORCL3

# 3. ORACLE DATA GUARD (Physical Standby) - DR Setup
# On PRIMARY:
sqlplus / as sysdba << EOF
ALTER DATABASE FORCE LOGGING;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ALTER SYSTEM SET log_archive_config='DG_CONFIG=(ORCL,ORCLSTBY)';
ALTER SYSTEM SET log_archive_dest_2='SERVICE=ORCLSTBY ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=ORCLSTBY';
EXIT;
EOF

# On STANDBY (after duplicating with RMAN):
sqlplus / as sysdba << EOF
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE;  -- Real-time apply
EXIT;
EOF

# Switchover (zero data loss)
# On PRIMARY:
srvctl stop database -db ORCL
sqlplus / as sysdba << EOF
ALTER DATABASE COMMIT TO SWITCHOVER TO PHYSICAL STANDBY;
EXIT;
EOF

# On STANDBY:
sqlplus / as sysdba << EOF
ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY;
ALTER DATABASE OPEN;
EXIT;
EOF

# Failover (if primary down)
# On STANDBY:
sqlplus / as sysdba << EOF
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH;
ALTER DATABASE ACTIVATE STANDBY DATABASE;
ALTER DATABASE OPEN;
EXIT;
EOF

# 4. ACTIVE DATA GUARD (Read-Only Standby)
# On STANDBY:
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
ALTER DATABASE OPEN READ ONLY;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;

# 5. GOLDENGATE REPLICATION (Logical - for zero downtime migration)
# Basic setup commands (after GG installed)
# On source:
GGSCI> ADD EXTRACT ext1, TRANLOG, BEGIN NOW
GGSCI> ADD EXTTRAIL /u01/ggs/dirdat/aa, EXTRACT ext1

# On target:
GGSCI> ADD REPLICAT rep1, EXTTRAIL /u01/ggs/dirdat/aa

# 6. RAC ONE NODE (Light HA)
srvctl config database -db ORCL | grep -i "One Node"
srvctl convert database -db ORCL -to raconenode

# 7. FLASHBACK & REINSTATE AFTER FAILOVER
# After failover, reinstate old primary as new standby
# On old primary:
sqlplus / as sysdba << EOF
FLASHBACK DATABASE TO SCN <scn_from_alert>;
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE CONVERT TO PHYSICAL STANDBY;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT;
EXIT;
EOF

# 8. GLOBAL DATA SERVICES (GDS) - Multi-region HA
# gdsctl commands
gdsctl start gsm
gdsctl add database -database ORCL -region REGION1 -connect_identifier ORCL
gdsctl add service -service prod_svc -database ORCL -preferred ORCL

# 9. HA HEALTH CHECK COMMANDS
srvctl status database -db ORCL -verbose
dgmgrl << EOF
CONNECT / 
SHOW CONFIGURATION;
SHOW DATABASE ORCLSTBY;
EOF

# 10. AUTOMATED HA MONITORING
# Script to check Data Guard lag
sqlplus -s / as sysdba << EOF
SELECT name, value FROM v\$dataguard_stats WHERE name = 'apply lag';
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task10_high_availability_ha_replication_commands.txt
# Replace ORCL / ORCLSTBY with your DB names
# Data Guard & RAC require separate licensing (Active Data Guard, RAC)
# Always test switchover/failover in non-production first!
# For Exadata/OCI use Autonomous Data Guard (fully managed)
# =============================================================================