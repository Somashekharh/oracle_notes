# 03_Recovery_Scenarios.md
## RMAN Recovery Scenarios (Real Production Cases)

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Recovery means restoring database to a usable state
after failure or data loss.

Failures may include:
- Datafile deleted
- Table dropped
- Control file lost
- Complete database crash
- Corruption

Recovery Types:
1. Complete Recovery
2. Incomplete (Point-in-Time) Recovery

------------------------------------------------------------
2. Scenario 1 – Datafile Deleted Accidentally
------------------------------------------------------------

Problem:
OS-level datafile deleted.

Error:
ORA-01157 / ORA-01110

Step 1: Identify missing file

SELECT file#, name
FROM v$datafile;

Step 2: Restore Datafile

RMAN> RESTORE DATAFILE 4;

Step 3: Recover Datafile

RMAN> RECOVER DATAFILE 4;

Step 4: Bring Online

ALTER DATABASE DATAFILE 4 ONLINE;

------------------------------------------------------------
3. Scenario 2 – Tablespace Offline Recovery
------------------------------------------------------------

Take tablespace offline:

ALTER TABLESPACE users OFFLINE;

Restore:

RMAN> RESTORE TABLESPACE users;
RMAN> RECOVER TABLESPACE users;

Bring online:

ALTER TABLESPACE users ONLINE;

------------------------------------------------------------
4. Scenario 3 – Control File Lost
------------------------------------------------------------

If controlfile autobackup enabled:

Start in NOMOUNT:

STARTUP NOMOUNT;

Restore control file:

RMAN> RESTORE CONTROLFILE FROM AUTOBACKUP;

Mount database:

ALTER DATABASE MOUNT;

Recover database:

RMAN> RECOVER DATABASE;

Open database:

ALTER DATABASE OPEN;

------------------------------------------------------------
5. Scenario 4 – Complete Database Crash
------------------------------------------------------------

Server crash / disk failure.

Steps:

STARTUP MOUNT;

RMAN> RESTORE DATABASE;

RMAN> RECOVER DATABASE;

ALTER DATABASE OPEN;

This performs complete recovery.

------------------------------------------------------------
6. Scenario 5 – Accidental Table Drop
------------------------------------------------------------

If recyclebin enabled:

FLASHBACK TABLE emp TO BEFORE DROP;

If not:
Use Point-in-Time Recovery.

------------------------------------------------------------
7. Scenario 6 – Point-in-Time Recovery
------------------------------------------------------------

Used when:
- Wrong DELETE
- Wrong UPDATE
- Logical corruption

Step 1:
Shutdown database

SHUTDOWN IMMEDIATE;

Step 2:
Startup mount

STARTUP MOUNT;

Step 3:
Recover until time

RMAN> RECOVER DATABASE
UNTIL TIME "TO_DATE('2026-02-21 10:00:00','YYYY-MM-DD HH24:MI:SS')";

Step 4:
Open resetlogs

ALTER DATABASE OPEN RESETLOGS;

Important:
RESETLOGS creates new incarnation.

------------------------------------------------------------
8. Scenario 7 – Block Corruption
------------------------------------------------------------

Check corruption:

RMAN> VALIDATE DATABASE;

Recover block:

RMAN> BLOCKRECOVER DATAFILE 4 BLOCK 120;

------------------------------------------------------------
9. Scenario 8 – Archivelog Missing
------------------------------------------------------------

If archivelog missing:

Recovery fails.

Solution:
Restore missing archivelog from backup.

RMAN> RESTORE ARCHIVELOG ALL;

------------------------------------------------------------
10. Complete vs Incomplete Recovery
------------------------------------------------------------

Complete Recovery:
- Restore all changes
- No data loss

Incomplete Recovery:
- Recover until specific time/SCN
- Some data loss possible

------------------------------------------------------------
11. RESETLOGS
------------------------------------------------------------

Required after incomplete recovery.

Command:
ALTER DATABASE OPEN RESETLOGS;

Creates:
- New redo log sequence
- New database incarnation

------------------------------------------------------------
12. Important Recovery Views
------------------------------------------------------------

Check recover file:

SELECT * FROM v$recover_file;

Check backup status:

LIST BACKUP;

Check archivelogs:

LIST ARCHIVELOG ALL;

------------------------------------------------------------
13. Real Production Workflow
------------------------------------------------------------

Failure Occurs →
Check Alert Log →
Identify issue →
Restore required file →
Recover →
Open database →
Validate application

------------------------------------------------------------
14. Important Interview Questions
------------------------------------------------------------

- Difference between RESTORE and RECOVER?
- What is RESETLOGS?
- What is complete vs incomplete recovery?
- How to recover lost controlfile?
- How to recover deleted datafile?
- What happens after shutdown abort?

------------------------------------------------------------
15. Golden Rule
------------------------------------------------------------

Backup without testing restore is useless.

Always test:
- Datafile restore
- Controlfile restore
- Full database restore

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
