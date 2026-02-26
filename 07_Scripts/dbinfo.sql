-- ================================================
-- Oracle Database Architecture Understanding Script
-- Run as SYSDBA: SQL> @oracle_arch_overview.sql
-- Output saved to oracle_architecture_report.txt
-- ================================================

SET ECHO OFF
SET PAGESIZE 9999
SET LINESIZE 250
SET HEADING ON
SET VERIFY OFF
SET FEEDBACK OFF
SPOOL oracle_architecture_report.txt REPLACE

PROMPT
PROMPT =================================================
PROMPT === ORACLE DATABASE ARCHITECTURE OVERVIEW ===
PROMPT =================================================
PROMPT

PROMPT === 1. DATABASE INFORMATION ===
SELECT name AS db_name,
       db_unique_name,
       open_mode,
       database_role,
       created,
       log_mode,
       platform_name
FROM v$database;

PROMPT
PROMPT === 2. INSTANCE INFORMATION ===
SELECT instance_name,
       host_name,
       version,
       startup_time,
       status,
       instance_role,
       thread#
FROM v$instance;

PROMPT
PROMPT === 3. IS THIS A MULTITENANT (CDB) DATABASE? ===
SELECT name, con_id, open_mode, restricted
FROM v$containers
ORDER BY con_id;

PROMPT
PROMPT === 4. MEMORY STRUCTURES – SGA COMPONENTS (MB) ===
SELECT component,
       current_size/1024/1024 AS current_mb,
       min_size/1024/1024 AS min_mb,
       max_size/1024/1024 AS max_mb
FROM v$sga_dynamic_components
ORDER BY component;

PROMPT
PROMPT === 5. BACKGROUND PROCESSES (Key ones) ===
SELECT name, description, paddr
FROM v$bgprocess
WHERE paddr <> '00'
ORDER BY name;

PROMPT
PROMPT === 6. CONTROL FILES ===
COLUMN name FORMAT A80
SELECT name, status, block_size, file_size_blks
FROM v$controlfile;

PROMPT
PROMPT === 7. REDO LOG FILES ===
COLUMN member FORMAT A80
SELECT group#, status, type, member, bytes/1024/1024 AS size_mb
FROM v$logfile
ORDER BY group#;

PROMPT
PROMPT === 8. TABLESPACES ===
SELECT tablespace_name,
       status,
       contents,
       logging,
       extent_management,
       segment_space_management
FROM dba_tablespaces
ORDER BY tablespace_name;

PROMPT
PROMPT === 9. DATAFILES (sample first 20) ===
COLUMN file_name FORMAT A100
SELECT file_id,
       tablespace_name,
       file_name,
       bytes/1024/1024 AS size_mb,
       status,
       autoextensible
FROM dba_data_files
WHERE ROWNUM <= 20
ORDER BY tablespace_name, file_id;

PROMPT
PROMPT === 10. KEY INITIALIZATION PARAMETERS ===
COLUMN name FORMAT A40
COLUMN value FORMAT A80
SELECT name, value, isdefault
FROM v$parameter
WHERE name IN ('sga_target','pga_aggregate_target','db_block_size','processes',
               'sessions','undo_tablespace','compatible','memory_target',
               'db_name','control_files','log_archive_dest_1')
ORDER BY name;

PROMPT
PROMPT === 11. OS-LEVEL INSTANCE PROCESSES (run outside SQL*Plus) ===  
PROMPT On Linux/Unix: ps -ef | grep -E 'ora_|pmon' | grep -v grep

SPOOL OFF

PROMPT
PROMPT Report generated: oracle_architecture_report.txt
PROMPT Open it in any text editor or Notepad++ for full details.