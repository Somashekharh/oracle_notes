# 01_Backup_Types.md
## Oracle Backup Concepts & Types (RMAN Foundation)

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Backup is a copy of database files used to restore data
in case of:

- Accidental deletion
- Data corruption
- Disk failure
- Server crash
- Human error

Very Important:
No backup = No recovery.

------------------------------------------------------------
2. Why Backup is Required?
------------------------------------------------------------

Real-world failures:

- User drops table accidentally
- Datafile deleted from OS
- Control file corrupted
- Server power failure
- Ransomware attack

Without backup → Data permanently lost.

------------------------------------------------------------
3. Types of Backups (High Level)
------------------------------------------------------------

Oracle backups are categorized as:

1. Physical Backup
2. Logical Backup
3. Cold (Offline) Backup
4. Hot (Online) Backup
5. Full Backup
6. Incremental Backup

------------------------------------------------------------
4. Physical Backup
------------------------------------------------------------

Physical copy of:

- Datafiles
- Control files
- Redo log files

Tools Used:
- RMAN
- OS copy (rare in production)

Best for:
- Complete database recovery

------------------------------------------------------------
5. Logical Backup
------------------------------------------------------------

Exports logical objects.

Tool:
- Data Pump (expdp / impdp)

Example:
expdp system/password FULL=Y DIRECTORY=backup_dir

Used for:
- Migrating tables
- Exporting schemas
- Object-level recovery

Difference:
Physical → entire database structure
Logical → objects (tables, schema)

------------------------------------------------------------
6. Cold Backup (Offline Backup)
------------------------------------------------------------

Definition:
Backup taken when database is shut down.

Steps:
1. SHUTDOWN IMMEDIATE
2. Copy datafiles
3. Copy control file
4. Copy redo logs

Advantages:
- Simple
- Consistent backup

Disadvantages:
- Downtime required

------------------------------------------------------------
7. Hot Backup (Online Backup)
------------------------------------------------------------

Definition:
Backup taken while database is running.

Requirements:
- Database must be in ARCHIVELOG mode

Advantages:
- No downtime
- Used in production

Disadvantages:
- Slight performance overhead

------------------------------------------------------------
8. Archivelog Mode
------------------------------------------------------------

Archivelog mode archives redo logs
so database can be recovered to a specific point in time.

Check Log Mode:
SELECT log_mode FROM v$database;

Enable Archivelog:

SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

Verify:
SELECT log_mode FROM v$database;

If NOT in archivelog mode:
Only full recovery possible.
No point-in-time recovery.

------------------------------------------------------------
9. Full Backup
------------------------------------------------------------

Definition:
Backup of entire database.

Includes:
- All datafiles
- Control file
- Archived logs (optional)

Example (RMAN):
BACKUP DATABASE;

------------------------------------------------------------
10. Incremental Backup
------------------------------------------------------------

Backs up only changed blocks since last backup.

Two Types:

Level 0:
- Base backup
- Similar to full backup

Level 1:
- Backs up changes since Level 0

------------------------------------------------------------
10.1 Differential Incremental
------------------------------------------------------------

Backs up changes since last incremental backup.

------------------------------------------------------------
10.2 Cumulative Incremental
------------------------------------------------------------

Backs up changes since last Level 0 backup.

------------------------------------------------------------
11. Backup Strategy Concepts
------------------------------------------------------------

RPO (Recovery Point Objective):
Maximum acceptable data loss.

Example:
If RPO = 30 minutes
→ Must backup every 30 minutes.

RTO (Recovery Time Objective):
Maximum acceptable downtime.

Example:
If RTO = 1 hour
→ Must restore database within 1 hour.

Retention Policy:
How long backups are stored.

Example:
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;

------------------------------------------------------------
12. Backup Storage Types
------------------------------------------------------------

Disk Backup:
- Stored on filesystem
- Faster recovery

Tape Backup:
- Used for long-term storage

Cloud Backup:
- Object storage (modern setups)

------------------------------------------------------------
13. Internal Backup Flow
------------------------------------------------------------

When RMAN backup runs:

1. Reads data blocks
2. Copies to backup piece
3. Records metadata in control file
4. Stores backup info in recovery catalog (if configured)

------------------------------------------------------------
14. Real-Time DBA Scenarios
------------------------------------------------------------

Scenario 1:
User deletes table.
→ Recover using backup + archived logs.

Scenario 2:
Datafile corrupted.
→ Restore specific datafile.

Scenario 3:
Entire database crashed.
→ Restore full backup.

Scenario 4:
Need point-in-time recovery.
→ Use archivelog backups.

------------------------------------------------------------
15. Important Interview Questions
------------------------------------------------------------

- Difference between hot and cold backup?
- What is archivelog mode?
- Difference between Level 0 and Level 1?
- What is RPO and RTO?
- Difference between physical and logical backup?
- What is retention policy?

------------------------------------------------------------
16. Key Notes for Production
------------------------------------------------------------

- Always run production in ARCHIVELOG mode.
- Always configure retention policy.
- Always test restore, not just backup.
- Backup without restore testing is useless.

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
