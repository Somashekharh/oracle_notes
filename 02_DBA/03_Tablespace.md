# 03_Tablespace.md
## Oracle Tablespace & Storage Management

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Tablespace is a logical storage unit in Oracle.

It contains:
- Datafiles (physical files)
- Database objects (tables, indexes, etc.)

Hierarchy:

Database
  → Tablespace
      → Datafile
          → Segment
              → Extent
                  → Block

Very Important Interview Question:
"What is difference between Tablespace and Datafile?"

Tablespace → Logical
Datafile → Physical


------------------------------------------------------------
2. Types of Tablespaces
------------------------------------------------------------

1. Permanent Tablespace
   - Stores tables, indexes, objects

2. Temporary Tablespace
   - Used for sorting operations

3. Undo Tablespace
   - Stores undo data for rollback

------------------------------------------------------------
3. Create Tablespace
------------------------------------------------------------

Basic Syntax:

CREATE TABLESPACE users
DATAFILE '/u01/app/oracle/oradata/users01.dbf'
SIZE 100M;

Example with Autoextend:

CREATE TABLESPACE app_data
DATAFILE '/u01/app/oracle/oradata/app01.dbf'
SIZE 200M
AUTOEXTEND ON
NEXT 50M
MAXSIZE 2G;

Explanation:
SIZE → Initial size
AUTOEXTEND → Automatically grow
NEXT → Growth size
MAXSIZE → Maximum limit

------------------------------------------------------------
4. Add Datafile to Tablespace
------------------------------------------------------------

ALTER TABLESPACE app_data
ADD DATAFILE '/u01/app/oracle/oradata/app02.dbf'
SIZE 100M;

------------------------------------------------------------
5. Resize Datafile
------------------------------------------------------------

Increase size:

ALTER DATABASE DATAFILE
'/u01/app/oracle/oradata/app01.dbf'
RESIZE 500M;

------------------------------------------------------------
6. Drop Tablespace
------------------------------------------------------------

DROP TABLESPACE app_data;

If contains objects:

DROP TABLESPACE app_data
INCLUDING CONTENTS
AND DATAFILES;

------------------------------------------------------------
7. Temporary Tablespace
------------------------------------------------------------

Create Temporary Tablespace:

CREATE TEMPORARY TABLESPACE temp2
TEMPFILE '/u01/app/oracle/oradata/temp02.dbf'
SIZE 100M
AUTOEXTEND ON;

Assign to User:

ALTER USER hr_user
TEMPORARY TABLESPACE temp2;

------------------------------------------------------------
8. Undo Tablespace
------------------------------------------------------------

Used for:
- ROLLBACK
- Flashback
- Read consistency

Create Undo Tablespace:

CREATE UNDO TABLESPACE undo2
DATAFILE '/u01/app/oracle/oradata/undo02.dbf'
SIZE 200M;

Switch Undo:

ALTER SYSTEM SET UNDO_TABLESPACE=undo2;

------------------------------------------------------------
9. Check Tablespace Information
------------------------------------------------------------

List Tablespaces:
SELECT tablespace_name FROM dba_tablespaces;

Check Datafiles:
SELECT file_name, tablespace_name, bytes/1024/1024 MB
FROM dba_data_files;

Check Free Space:
SELECT tablespace_name,
       SUM(bytes)/1024/1024 FREE_MB
FROM dba_free_space
GROUP BY tablespace_name;

Check Used Space:
SELECT tablespace_name,
       SUM(bytes)/1024/1024 USED_MB
FROM dba_segments
GROUP BY tablespace_name;

------------------------------------------------------------
10. Check Tablespace Usage (Combined Query)
------------------------------------------------------------

SELECT df.tablespace_name,
       df.totalspace MB,
       fs.freespace MB,
       (df.totalspace - fs.freespace) USED_MB
FROM
  (SELECT tablespace_name,
          SUM(bytes)/1024/1024 totalspace
   FROM dba_data_files
   GROUP BY tablespace_name) df,
  (SELECT tablespace_name,
          SUM(bytes)/1024/1024 freespace
   FROM dba_free_space
   GROUP BY tablespace_name) fs
WHERE df.tablespace_name = fs.tablespace_name;

------------------------------------------------------------
11. Segments, Extents, Blocks
------------------------------------------------------------

Block:
Smallest storage unit (default 8KB)

Extent:
Group of blocks

Segment:
Collection of extents
Examples:
- Table segment
- Index segment
- Undo segment

------------------------------------------------------------
12. High Water Mark (HWM)
------------------------------------------------------------

HWM indicates highest block ever used in table.

TRUNCATE resets HWM.
DELETE does not reset HWM.

------------------------------------------------------------
13. Bigfile vs Smallfile Tablespace
------------------------------------------------------------

Smallfile:
- Multiple datafiles allowed
- Default type

Bigfile:
- Single large datafile
- Used in ASM environments

Create Bigfile Tablespace:

CREATE BIGFILE TABLESPACE big_data
DATAFILE '/u01/app/oracle/oradata/big01.dbf'
SIZE 5G;

------------------------------------------------------------
14. Real-Time DBA Scenarios
------------------------------------------------------------

Scenario 1:
Tablespace full.
→ Add datafile
→ Resize datafile
→ Enable autoextend

Scenario 2:
Temp tablespace full.
→ Add tempfile

Scenario 3:
Undo tablespace full.
→ Increase size
→ Check long running transactions

------------------------------------------------------------
15. Best Practices
------------------------------------------------------------

- Always enable AUTOEXTEND (with MAXSIZE)
- Monitor tablespace usage daily
- Separate data, index, and undo tablespaces
- Avoid unlimited quota unless required

------------------------------------------------------------
16. Interview Questions
------------------------------------------------------------

- Difference between Tablespace and Datafile?
- What happens if tablespace becomes full?
- What is High Water Mark?
- Difference between Bigfile and Smallfile?
- What is Undo tablespace used for?

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
