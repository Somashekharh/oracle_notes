# =============================================================================
# Oracle DBA Task 11: Multitenant (CDB/PDB) Specific Tasks - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant Architecture
# Date: February 2026
# Run as SYSDBA
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. CHECK CURRENT MULTITENANT STATUS
sqlplus / as sysdba << EOF
SHOW PDBS;
SELECT name, con_id, open_mode, restricted, total_size/1024/1024/1024 AS size_gb
FROM v\$containers ORDER BY con_id;
SELECT banner FROM v\$version WHERE banner LIKE '%Multitenant%';
EXIT;
EOF

# 3. CREATE NEW PDB FROM SEED (Fastest)
sqlplus / as sysdba << EOF
CREATE PLUGGABLE DATABASE SALES_PDB ADMIN USER sales_admin IDENTIFIED BY StrongPass123#
  FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/ORCL/pdbseed/', '/u01/app/oracle/oradata/ORCL/sales_pdb/');
ALTER PLUGGABLE DATABASE SALES_PDB OPEN;
ALTER PLUGGABLE DATABASE SALES_PDB SAVE STATE;   -- Auto-open on CDB restart
EXIT;
EOF

# 4. CLONE EXISTING PDB (Local Clone)
sqlplus / as sysdba << EOF
ALTER PLUGGABLE DATABASE SALES_PDB CLOSE IMMEDIATE;
CREATE PLUGGABLE DATABASE SALES_PDB_TEST FROM SALES_PDB
  FILE_NAME_CONVERT = ('/u01/app/oracle/oradata/ORCL/sales_pdb/', '/u01/app/oracle/oradata/ORCL/sales_pdb_test/');
ALTER PLUGGABLE DATABASE SALES_PDB_TEST OPEN;
EXIT;
EOF

# 5. PLUG / UNPLUG PDB (For migration)
# Unplug from source CDB
sqlplus / as sysdba << EOF
ALTER PLUGGABLE DATABASE SALES_PDB CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE SALES_PDB UNPLUG INTO '/u01/migrate/sales_pdb.xml';
EXIT;
EOF

# Plug into target CDB
sqlplus / as sysdba << EOF
CREATE PLUGGABLE DATABASE SALES_PDB USING '/u01/migrate/sales_pdb.xml' MOVE;
ALTER PLUGGABLE DATABASE SALES_PDB OPEN;
EXIT;
EOF

# 6. PDB RESOURCE MANAGEMENT (CPU, I/O, Sessions)
sqlplus / as sysdba << EOF
ALTER PLUGGABLE DATABASE SALES_PDB
  CPU_COUNT = 4,
  PARALLEL_SERVER_LIMIT = 50,
  SESSIONS = 200;

-- Share model (default)
ALTER SYSTEM SET pdb_memory_limit = '4G' CONTAINER=CURRENT;  -- Per PDB
EXIT;
EOF

# 7. APPLICATION CONTAINERS (23ai Advanced)
sqlplus / as sysdba << EOF
CREATE PLUGGABLE DATABASE APP_ROOT AS APPLICATION CONTAINER ADMIN USER app_root_admin IDENTIFIED BY StrongPass123#;
ALTER PLUGGABLE DATABASE APP_ROOT OPEN;
CREATE PLUGGABLE DATABASE APP_PDB1 FROM APP_ROOT;
EXIT;
EOF

# 8. REFRESHABLE PDB (Copy-on-Write clone)
sqlplus / as sysdba << EOF
CREATE PLUGGABLE DATABASE DEV_PDB FROM PROD_PDB REFRESH MODE EVERY 60 MINUTES;
ALTER PLUGGABLE DATABASE DEV_PDB OPEN READ ONLY;
EXIT;
EOF

# 9. DROP PDB
sqlplus / as sysdba << EOF
ALTER PLUGGABLE DATABASE SALES_PDB_TEST CLOSE IMMEDIATE;
DROP PLUGGABLE DATABASE SALES_PDB_TEST INCLUDING DATAFILES;
EXIT;
EOF

# 10. COMMON vs LOCAL USERS / ROLES
sqlplus / as sysdba << EOF
-- Common user
CREATE USER c##global_dba IDENTIFIED BY StrongPass123# CONTAINER=ALL;
GRANT DBA TO c##global_dba CONTAINER=ALL;

-- Local user in specific PDB
ALTER SESSION SET CONTAINER=SALES_PDB;
CREATE USER local_app IDENTIFIED BY StrongPass123# CONTAINER=CURRENT;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving: chmod +x oracle_dba_task11_multitenant_cdb_pdb_commands.txt
# All 23ai features included (refreshable PDB, Application Containers, etc.)
# Always take RMAN backup before plugging/unplugging PDBs
# =============================================================================