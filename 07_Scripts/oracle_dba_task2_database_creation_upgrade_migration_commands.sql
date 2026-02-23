# =============================================================================
# Oracle DBA Task 2: Database Creation, Upgrade & Migration - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as oracle user unless mentioned otherwise
# Assumes Task 1 (Installation) is already completed
# =============================================================================

# 1. ENVIRONMENT SETUP (as oracle user - run every time you login)
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL
# or add to ~/.bash_profile as in Task 1

# 2. CREATE NEW DATABASE USING DBCA (Silent - Recommended for 23ai Multitenant)
# This creates a fresh CDB + 1 PDB
dbca -silent -createDatabase \
  -templateName General_Purpose.dbc \
  -gdbName PRODDB \
  -sid PRODDB \
  -responseFile NO_VALUE \
  -characterSet AL32UTF8 \
  -createAsContainerDatabase true \
  -numberOfPDBs 1 \
  -pdbName PRODPDB1 \
  -sysPassword Oracle123# \
  -systemPassword Oracle123# \
  -pdbAdminPassword Oracle123# \
  -emConfiguration NONE \
  -storageType FS \
  -datafileDestination /u01/app/oracle/oradata \
  -redoLogFileSize 100 \
  -totalMemory 4096 \
  -ignorePrereq

# 3. CREATE ADDITIONAL PLUGGABLE DATABASE (PDB) in existing CDB
dbca -silent -createPluggableDatabase \
  -pdbName PRODPDB2 \
  -pdbAdminPassword Oracle123# \
  -createPDBFrom DEFAULT \
  -pdbDatafileDestination /u01/app/oracle/oradata/PRODDB/PRODPDB2 \
  -cdbName PRODDB

# 4. MANUAL DATABASE CREATION (Advanced - for learning / custom control)
# Step-by-step commands:

# a) Create directories
mkdir -p /u01/app/oracle/oradata/TESTDB
mkdir -p /u01/app/oracle/admin/TESTDB/adump
mkdir -p /u01/app/oracle/admin/TESTDB/dpdump

# b) Create init.ora (pfile)
cat > $ORACLE_HOME/dbs/initTESTDB.ora << EOF
db_name='TESTDB'
memory_target=2G
processes=300
control_files='/u01/app/oracle/oradata/TESTDB/control01.ctl','/u01/app/oracle/oradata/TESTDB/control02.ctl'
db_block_size=8192
compatible='23.0.0'
EOF

# c) Create database manually
sqlplus / as sysdba << EOF
STARTUP NOMOUNT PFILE='$ORACLE_HOME/dbs/initTESTDB.ora';
CREATE DATABASE TESTDB
  USER SYS IDENTIFIED BY Oracle123#
  USER SYSTEM IDENTIFIED BY Oracle123#
  LOGFILE GROUP 1 ('/u01/app/oracle/oradata/TESTDB/redo01.log') SIZE 100M,
          GROUP 2 ('/u01/app/oracle/oradata/TESTDB/redo02.log') SIZE 100M
  MAXLOGFILES 5
  MAXLOGMEMBERS 5
  MAXLOGHISTORY 1
  MAXDATAFILES 100
  CHARACTER SET AL32UTF8
  NATIONAL CHARACTER SET AL16UTF16
  EXTENT MANAGEMENT LOCAL
  DATAFILE '/u01/app/oracle/oradata/TESTDB/system01.dbf' SIZE 700M REUSE AUTOEXTEND ON NEXT 1024K MAXSIZE UNLIMITED
  SYSAUX DATAFILE '/u01/app/oracle/oradata/TESTDB/sysaux01.dbf' SIZE 600M REUSE AUTOEXTEND ON NEXT 1024K MAXSIZE UNLIMITED
  DEFAULT TEMPORARY TABLESPACE temp TEMPFILE '/u01/app/oracle/oradata/TESTDB/temp01.dbf' SIZE 100M REUSE AUTOEXTEND ON NEXT 1024K MAXSIZE UNLIMITED
  UNDO TABLESPACE undotbs1 DATAFILE '/u01/app/oracle/oradata/TESTDB/undotbs01.dbf' SIZE 200M REUSE AUTOEXTEND ON NEXT 1024K MAXSIZE UNLIMITED;
EXIT;
EOF

# d) Run catalog scripts
sqlplus / as sysdba << EOF
@?/rdbms/admin/catalog.sql
@?/rdbms/admin/catproc.sql
@?/rdbms/admin/catrdbms.sql
@?/rdbms/admin/catpdb.sql
EXIT;
EOF

# e) Create spfile and restart
sqlplus / as sysdba << EOF
CREATE SPFILE FROM PFILE;
SHUTDOWN IMMEDIATE;
STARTUP;
EXIT;
EOF

# 5. UPGRADE DATABASE USING AUTOUPGRADE (Oracle Recommended Tool - 19c → 23ai)
# Download AutoUpgrade from Oracle Support (autoupgrade.jar)

# a) Prepare config file (autoupgrade.cfg)
cat > /u01/upgrade/autoupgrade.cfg << EOF
global.autoupgrade_log_dir=/u01/upgrade/logs
upg1.source_home=/u01/app/oracle/product/19.0.0/dbhome_1
upg1.target_home=/u01/app/oracle/product/23.0.0/dbhome_1
upg1.sid=OLDDB
upg1.target_sid=NEWDB23
upg1.upgrade_mode=auto
upg1.action=analyze,upgrade
upg1.log_dir=/u01/upgrade/logs/OLDDB
EOF

# b) Run AutoUpgrade
java -jar /u01/stage/autoupgrade_23.0.0.jar -config /u01/upgrade/autoupgrade.cfg -mode analyze
java -jar /u01/stage/autoupgrade_23.0.0.jar -config /u01/upgrade/autoupgrade.cfg -mode upgrade

# c) Post-upgrade commands
sqlplus / as sysdba << EOF
@?/rdbms/admin/utlrp.sql
EXIT;
EOF

# 6. MIGRATION - DATA PUMP (Full Schema / Full Database)
# Export from source
expdp system/Oracle123#@sourceDB directory=DATA_PUMP_DIR dumpfile=full_export.dmp logfile=full_export.log full=y parallel=8

# Import to target
impdp system/Oracle123#@targetDB directory=DATA_PUMP_DIR dumpfile=full_export.dmp logfile=full_import.log full=y parallel=8 remap_schema=olduser:newuser

# 7. MIGRATION - RMAN DUPLICATE (Fastest for same platform)
# On target server (as oracle)
rman target sys/Oracle123#@sourceDB auxiliary sys/Oracle123#@targetDB << EOF
DUPLICATE TARGET DATABASE TO NEWDB
  FROM ACTIVE DATABASE
  SPFILE
  SET DB_NAME='NEWDB'
  NOFILENAMECHECK;
EOF

# 8. MIGRATION - TRANSPORTABLE TABLESPACES (Cross-platform)
# On source:
sqlplus / as sysdba << EOF
ALTER TABLESPACE USERS READ ONLY;
EXIT;
EOF

# Export metadata
expdp system/Oracle123# directory=DATA_PUMP_DIR dumpfile=tts_metadata.dmp logfile=tts.log transport_tablespaces=USERS

# Copy datafiles to target
# On target:
impdp system/Oracle123# directory=DATA_PUMP_DIR dumpfile=tts_metadata.dmp logfile=tts_imp.log transport_datafiles=/path/to/copied/users01.dbf

# 9. MIGRATION - PLUG UNPLUG PDB (Fastest for Multitenant)
# On source CDB:
sqlplus / as sysdba << EOF
ALTER PLUGGABLE DATABASE MYAPPDB CLOSE;
UNPLUG PLUGGABLE DATABASE MYAPPDB INTO '/u01/migrate/myappdb.xml';
EXIT;
EOF

# Copy datafiles + XML to target
# On target CDB:
sqlplus / as sysdba << EOF
CREATE PLUGGABLE DATABASE MYAPPDB USING '/u01/migrate/myappdb.xml' MOVE;
ALTER PLUGGABLE DATABASE MYAPPDB OPEN;
EXIT;
EOF

# 10. VERIFY AFTER CREATION / UPGRADE / MIGRATION
sqlplus / as sysdba << EOF
SELECT name, open_mode, database_role FROM v\$database;
SHOW PDBS;
SELECT banner FROM v\$version;
SELECT * FROM dba_registry;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task2_database_creation_upgrade_migration_commands.txt
# Replace Oracle123# with your strong password
# For Oracle Database Free (23ai), use only DBCA or manual creation
# Always take RMAN backup before upgrade/migration!
# =============================================================================