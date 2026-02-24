# =============================================================================
# Oracle DBA Task 7: Space & Storage Management - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as SYSDBA (sys / as sysdba) unless mentioned otherwise
# Assumes Task 1-6 are completed (database running)
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. MONITOR SPACE USAGE (Most Important Daily Check)
sqlplus / as sysdba << EOF
-- Overall Tablespace Usage (with % free)
COLUMN tablespace_name FORMAT A25
COLUMN size_gb FORMAT 999999.99
COLUMN used_gb FORMAT 999999.99
COLUMN free_gb FORMAT 999999.99
COLUMN pct_free FORMAT 999.99
SELECT t.tablespace_name,
       ROUND(SUM(d.bytes)/1024/1024/1024,2) AS size_gb,
       ROUND(SUM(d.bytes - nvl(f.bytes,0))/1024/1024/1024,2) AS used_gb,
       ROUND(SUM(nvl(f.bytes,0))/1024/1024/1024,2) AS free_gb,
       ROUND(SUM(nvl(f.bytes,0))/SUM(d.bytes)*100,2) AS pct_free
FROM dba_data_files d
LEFT JOIN (SELECT file_id, SUM(bytes) bytes FROM dba_free_space GROUP BY file_id) f
  ON d.file_id = f.file_id
JOIN dba_tablespaces t ON d.tablespace_name = t.tablespace_name
GROUP BY t.tablespace_name
ORDER BY pct_free;

-- Datafiles Details
SELECT file_name, tablespace_name, bytes/1024/1024/1024 AS size_gb, autoextensible, maxbytes/1024/1024/1024 AS max_gb
FROM dba_data_files
ORDER BY tablespace_name;

-- Temp & Undo Usage
SELECT tablespace_name, status, contents, extent_management, segment_space_management
FROM dba_tablespaces
WHERE contents IN ('TEMPORARY','UNDO');
EXIT;
EOF

# 3. CREATE NEW TABLESPACES
sqlplus / as sysdba << EOF
-- Permanent Tablespace
CREATE TABLESPACE APP_DATA
  DATAFILE '/u01/app/oracle/oradata/ORCL/app_data01.dbf' SIZE 5G AUTOEXTEND ON NEXT 500M MAXSIZE 50G
  EXTENT MANAGEMENT LOCAL
  SEGMENT SPACE MANAGEMENT AUTO;

-- Bigfile Tablespace (recommended for large DBs)
CREATE BIGFILE TABLESPACE APP_BIGDATA
  DATAFILE '/u01/app/oracle/oradata/ORCL/app_bigdata.dbf' SIZE 100G AUTOEXTEND ON;

-- Temporary Tablespace
CREATE TEMPORARY TABLESPACE TEMP_NEW
  TEMPFILE '/u01/app/oracle/oradata/ORCL/temp_new01.dbf' SIZE 2G AUTOEXTEND ON NEXT 500M MAXSIZE 20G;

-- Undo Tablespace (if you need extra)
CREATE UNDO TABLESPACE UNDO_NEW
  DATAFILE '/u01/app/oracle/oradata/ORCL/undo_new01.dbf' SIZE 4G AUTOEXTEND ON;
EXIT;
EOF

# 4. ALTER / RESIZE / ADD DATAFILES
sqlplus / as sysdba << EOF
-- Add new datafile
ALTER TABLESPACE APP_DATA
  ADD DATAFILE '/u01/app/oracle/oradata/ORCL/app_data02.dbf' SIZE 10G AUTOEXTEND ON NEXT 1G MAXSIZE 100G;

-- Resize datafile
ALTER DATABASE DATAFILE '/u01/app/oracle/oradata/ORCL/app_data01.dbf' RESIZE 15G;

-- Enable Autoextend (if not already)
ALTER DATABASE DATAFILE '/u01/app/oracle/oradata/ORCL/app_data01.dbf' AUTOEXTEND ON NEXT 500M MAXSIZE 50G;

-- Make tablespace Read Only / Offline
ALTER TABLESPACE APP_DATA READ ONLY;
ALTER TABLESPACE APP_DATA OFFLINE;
ALTER TABLESPACE APP_DATA ONLINE;
EXIT;
EOF

# 5. RECLAIM SPACE & SHRINK SEGMENTS
sqlplus / as sysdba << EOF
-- Shrink a table (reclaim space)
ALTER TABLE app_user.employees SHRINK SPACE CASCADE;

-- Shrink index
ALTER INDEX app_user.pk_employees SHRINK SPACE;

-- Coalesce free space in tablespace
ALTER TABLESPACE APP_DATA COALESCE;

-- Rebuild index online to reclaim space
ALTER INDEX app_user.idx_salary REBUILD ONLINE;
EXIT;
EOF

# 6. ONLINE TABLE REDEFINITION (Zero Downtime Reorg)
sqlplus / as sysdba << EOF
-- Example: Reorganize large table into new tablespace
BEGIN
  DBMS_REDEFINITION.REDEF_TABLE(
    uname        => 'APP_USER',
    tname        => 'BIG_TABLE',
    table_type   => DBMS_REDEFINITION.CONS_ORIG_PARAMS,
    options_flag => DBMS_REDEFINITION.CONS_USE_PK);
END;
/

-- Finish redefinition
BEGIN
  DBMS_REDEFINITION.FINISH_REDEF_TABLE('APP_USER', 'BIG_TABLE', 'BIG_TABLE_INT');
END;
/
DROP TABLE BIG_TABLE_INT;
EXIT;
EOF

# 7. MANAGE TEMP & UNDO TABLESPACES
sqlplus / as sysdba << EOF
-- Switch default TEMP tablespace
ALTER DATABASE DEFAULT TEMPORARY TABLESPACE TEMP_NEW;

-- Switch default UNDO tablespace
ALTER SYSTEM SET undo_tablespace = 'UNDO_NEW' SCOPE=BOTH;

-- Drop old temp/undo (after switching)
DROP TABLESPACE TEMP_OLD INCLUDING CONTENTS AND DATAFILES;
DROP TABLESPACE UNDO_OLD INCLUDING CONTENTS AND DATAFILES;
EXIT;
EOF

# 8. ASM MANAGEMENT (Only if using Automatic Storage Management)
# asmcmd commands (run as grid user usually)
# asmcmd
# lsdg               # list diskgroups
# ls -l +DATA        # list files
# alter diskgroup DATA add disk '/dev/oracleasm/disks/DISK5' rebalance power 4;

# SQL commands for ASM
sqlplus / as sysdba << EOF
SELECT name, state, total_mb, free_mb, usable_file_mb FROM v\$asm_diskgroup;
EXIT;
EOF

# 9. SPACE GROWTH TREND REPORT (Last 7 days)
sqlplus / as sysdba << EOF
SELECT tablespace_name,
       MAX(used_mb) KEEP (DENSE_RANK LAST ORDER BY snap_time) AS used_mb_today,
       MIN(used_mb) KEEP (DENSE_RANK FIRST ORDER BY snap_time) AS used_mb_7days_ago
FROM (
  SELECT tablespace_name, snap_time, used_mb
  FROM dba_hist_tbspc_space_usage
  WHERE snap_time > SYSDATE-7
)
GROUP BY tablespace_name
ORDER BY tablespace_name;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task7_space_storage_management_commands.txt
# Replace ORCL with your SID
# Always monitor tablespaces >85% full - set OEM alerts
# Use Bigfile tablespaces for databases > 100GB
# Never shrink SYSTEM or SYSAUX tablespaces
# Test all changes in non-production first!
# =============================================================================