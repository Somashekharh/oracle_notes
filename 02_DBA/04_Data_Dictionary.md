# 04_Data_Dictionary.md
## Oracle Data Dictionary & Dynamic Performance Views

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Data Dictionary is a collection of tables and views
that store metadata about the database.

Metadata means:
- Information about tables
- Users
- Privileges
- Tablespaces
- Datafiles
- Database configuration

Important:
Data Dictionary is automatically maintained by Oracle.

------------------------------------------------------------
2. Types of Dictionary Views
------------------------------------------------------------

Oracle provides three main types:

1. USER_ views
2. ALL_ views
3. DBA_ views

------------------------------------------------------------
2.1 USER_ Views
------------------------------------------------------------

- Show objects owned by current user.
- No special privilege required.

Example:
SELECT * FROM user_tables;

------------------------------------------------------------
2.2 ALL_ Views
------------------------------------------------------------

- Show objects accessible to current user.
- Includes own + granted objects.

Example:
SELECT * FROM all_tables;

------------------------------------------------------------
2.3 DBA_ Views
------------------------------------------------------------

- Show all objects in database.
- Requires DBA privilege.

Example:
SELECT * FROM dba_tables;

------------------------------------------------------------
3. Important Data Dictionary Views
------------------------------------------------------------

------------------------------------------------------------
3.1 DBA_USERS
------------------------------------------------------------

Shows all database users.

Example:
SELECT username, account_status, default_tablespace
FROM dba_users;

Used to:
- Check user status
- Check profile
- Check default tablespace

------------------------------------------------------------
3.2 DBA_TABLES
------------------------------------------------------------

Shows all tables in database.

Example:
SELECT table_name, owner
FROM dba_tables
WHERE owner='HR';

------------------------------------------------------------
3.3 DBA_DATA_FILES
------------------------------------------------------------

Shows datafile information.

Example:
SELECT file_name, tablespace_name, bytes/1024/1024 MB
FROM dba_data_files;

------------------------------------------------------------
3.4 DBA_FREE_SPACE
------------------------------------------------------------

Shows free space inside tablespaces.

Example:
SELECT tablespace_name,
       SUM(bytes)/1024/1024 FREE_MB
FROM dba_free_space
GROUP BY tablespace_name;

------------------------------------------------------------
3.5 DBA_SEGMENTS
------------------------------------------------------------

Shows segment size (tables, indexes).

Example:
SELECT segment_name,
       segment_type,
       bytes/1024/1024 MB
FROM dba_segments
WHERE owner='HR';

------------------------------------------------------------
3.6 DBA_ROLE_PRIVS
------------------------------------------------------------

Shows roles granted to users.

Example:
SELECT * FROM dba_role_privs
WHERE grantee='HR_USER';

------------------------------------------------------------
3.7 DBA_SYS_PRIVS
------------------------------------------------------------

Shows system privileges granted.

Example:
SELECT * FROM dba_sys_privs
WHERE grantee='HR_USER';

------------------------------------------------------------
3.8 DBA_TAB_PRIVS
------------------------------------------------------------

Shows object privileges.

Example:
SELECT * FROM dba_tab_privs
WHERE grantee='HR_USER';

------------------------------------------------------------
4. Dynamic Performance Views (V$ Views)
------------------------------------------------------------

Also called:
Dynamic Performance Views.

Prefix:
V$

Used for monitoring live database performance.

------------------------------------------------------------
4.1 V$DATABASE
------------------------------------------------------------

Shows database information.

Example:
SELECT name, open_mode, log_mode
FROM v$database;

------------------------------------------------------------
4.2 V$INSTANCE
------------------------------------------------------------

Shows instance status.

Example:
SELECT instance_name, status
FROM v$instance;

------------------------------------------------------------
4.3 V$SESSION
------------------------------------------------------------

Shows active sessions.

Example:
SELECT sid, serial#, username, status
FROM v$session;

Used for:
- Checking active users
- Killing sessions

------------------------------------------------------------
4.4 V$PROCESS
------------------------------------------------------------

Shows OS process info.

Example:
SELECT spid, program
FROM v$process;

------------------------------------------------------------
4.5 V$SQL
------------------------------------------------------------

Shows SQL statements in memory.

Example:
SELECT sql_id, executions, sql_text
FROM v$sql
WHERE executions > 100;

Used for:
- Finding high execution queries
- Performance tuning

------------------------------------------------------------
4.6 V$TABLESPACE
------------------------------------------------------------

Shows tablespace details.

Example:
SELECT name FROM v$tablespace;

------------------------------------------------------------
5. Real-Time DBA Scenarios
------------------------------------------------------------

Scenario 1:
User account locked.
→ Check DBA_USERS.

Scenario 2:
Tablespace full.
→ Check DBA_DATA_FILES + DBA_FREE_SPACE.

Scenario 3:
Database not opening.
→ Check V$INSTANCE and V$DATABASE.

Scenario 4:
Find long running session.
→ Query V$SESSION.

Scenario 5:
Find heavy SQL.
→ Query V$SQL.

------------------------------------------------------------
6. Difference Between Dictionary & V$ Views
------------------------------------------------------------

Data Dictionary:
- Metadata
- Static information
- Stored in SYSTEM tablespace

V$ Views:
- Dynamic
- Performance-related
- Real-time data
- Based on memory structures

------------------------------------------------------------
7. Important Monitoring Queries (Practical)
------------------------------------------------------------

Check Database Status:
SELECT name, open_mode FROM v$database;

Check Instance Status:
SELECT instance_name, status FROM v$instance;

Check Logged In Users:
SELECT username FROM v$session
WHERE username IS NOT NULL;

Check Top Memory Sessions:
SELECT s.username,
       p.spid,
       p.pga_used_mem/1024/1024 MB
FROM v$process p, v$session s
WHERE p.addr = s.paddr
ORDER BY p.pga_used_mem DESC;

------------------------------------------------------------
8. Interview Questions
------------------------------------------------------------

- Difference between USER_, ALL_, DBA_ views?
- What is V$SESSION used for?
- How to check tablespace free space?
- Difference between V$DATABASE and V$INSTANCE?
- Where is data dictionary stored?

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
