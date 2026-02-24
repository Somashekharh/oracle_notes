# =============================================================================
# Oracle DBA Task 13: Data Movement & Integration - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as SYSDBA or schema owner
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL
mkdir -p /u01/backup/datapump

# Create directory object
sqlplus / as sysdba << EOF
CREATE OR REPLACE DIRECTORY DATA_PUMP_DIR AS '/u01/backup/datapump';
GRANT READ, WRITE ON DIRECTORY DATA_PUMP_DIR TO PUBLIC;
EXIT;
EOF

# 2. DATA PUMP - EXPORT (expdp)
expdp system/StrongPass123# directory=DATA_PUMP_DIR dumpfile=full_export_%U.dmp logfile=full_export.log full=y parallel=8 compression=ALL

expdp system/StrongPass123# directory=DATA_PUMP_DIR dumpfile=schema_hr.dmp logfile=hr.log schemas=HR parallel=4

expdp system/StrongPass123# directory=DATA_PUMP_DIR dumpfile=table_emp.dmp logfile=emp.log tables=HR.EMPLOYEES

# 3. DATA PUMP - IMPORT (impdp)
impdp system/StrongPass123# directory=DATA_PUMP_DIR dumpfile=full_export.dmp logfile=full_imp.log full=y parallel=8 remap_schema=OLD:NEW

impdp system/StrongPass123# directory=DATA_PUMP_DIR dumpfile=schema_hr.dmp logfile=hr_imp.log schemas=HR remap_tablespace=USERS:APP_DATA

# 4. TRANSPORTABLE TABLESPACES (Fastest cross-platform)
# On source:
sqlplus / as sysdba << EOF
ALTER TABLESPACE APP_DATA READ ONLY;
EXIT;
EOF
expdp system/StrongPass123# directory=DATA_PUMP_DIR dumpfile=tts_meta.dmp logfile=tts.log transport_tablespaces=APP_DATA

# Copy datafiles to target + import metadata on target
impdp system/StrongPass123# directory=DATA_PUMP_DIR dumpfile=tts_meta.dmp logfile=tts_imp.log transport_datafiles=/path/to/copied/app_data01.dbf

# 5. RMAN DUPLICATE (Live clone)
rman target sys/StrongPass123#@PROD auxiliary sys/StrongPass123#@TEST << EOF
DUPLICATE TARGET DATABASE TO TESTDB FROM ACTIVE DATABASE SPFILE NOFILENAMECHECK;
EOF

# 6. SQL*LOADER (External data load)
sqlldr system/StrongPass123# control=load_emp.ctl log=load.log bad=bad.log direct=TRUE

# Example control file load_emp.ctl
cat > load_emp.ctl << EOF
LOAD DATA
INFILE 'employees.csv'
BADFILE 'employees.bad'
APPEND INTO TABLE HR.EMPLOYEES
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
(emp_id, first_name, last_name, salary)
EOF

# 7. EXTERNAL TABLES (Read flat files directly)
sqlplus / as sysdba << EOF
CREATE TABLE ext_employees (
  emp_id NUMBER, first_name VARCHAR2(50)
)
ORGANIZATION EXTERNAL (
  TYPE ORACLE_LOADER
  DEFAULT DIRECTORY DATA_PUMP_DIR
  ACCESS PARAMETERS (
    RECORDS DELIMITED BY NEWLINE
    FIELDS TERMINATED BY ','
  )
  LOCATION ('employees.csv')
);
EXIT;
EOF

# 8. DATABASE LINKS
sqlplus / as sysdba << EOF
CREATE DATABASE LINK prod_link
CONNECT TO app_user IDENTIFIED BY AppPass123#
USING '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=prod-server)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=PROD)))';

-- Use it
SELECT * FROM employees@prod_link;
EXIT;
EOF

# 9. MATERIALIZED VIEW FOR REPLICATION
sqlplus app_user/AppPass123# << EOF
CREATE MATERIALIZED VIEW mv_emp_refresh
BUILD IMMEDIATE
REFRESH FAST ON DEMAND
AS SELECT * FROM employees@prod_link;

EXEC DBMS_MVIEW.REFRESH('MV_EMP_REFRESH');
EXIT;
EOF

# 10. GOLDENGATE BASIC COMMANDS (if installed)
# GGSCI> ADD EXTRACT ext1, TRANLOG, BEGIN NOW
# GGSCI> ADD EXTTRAIL ./dirdat/aa, EXTRACT ext1
# GGSCI> ADD REPLICAT rep1, EXTTRAIL ./dirdat/aa

# =============================================================================
# END OF FILE
# After saving: chmod +x oracle_dba_task13_data_movement_integration_commands.txt
# Always take backup before large data movement
# Use PARALLEL and COMPRESSION for large exports
# =============================================================================