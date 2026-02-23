# 01_Architecture.md
## Oracle Database Architecture (19c Focus)

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Understanding Oracle Architecture is mandatory for any DBA.

Oracle Architecture explains:
- How data is stored
- How memory works
- How background processes work
- How instance interacts with database

Very Important Interview Question:
"What is the difference between Instance and Database?"

------------------------------------------------------------
2. Oracle Database vs Oracle Instance
------------------------------------------------------------

Oracle Database:
- Physical files stored on disk
- Datafiles
- Control files
- Redo log files

Oracle Instance:
- Memory structures
- Background processes
- Runs in RAM

Formula:
Instance = Memory (SGA + PGA) + Background Processes
Database = Physical Files on Disk

Instance mounts and opens the database.

------------------------------------------------------------
3. Oracle Architecture Overview
------------------------------------------------------------

Main Components:

1. Memory Structure
2. Background Processes
3. Physical Database Files

------------------------------------------------------------
4. Memory Structure
------------------------------------------------------------

Oracle Memory has two main parts:

1. SGA (System Global Area)
2. PGA (Program Global Area)

------------------------------------------------------------
4.1 SGA (System Global Area)
------------------------------------------------------------

Shared memory region.
Shared by all users.

Components of SGA:

1. Shared Pool
2. Database Buffer Cache
3. Redo Log Buffer
4. Large Pool
5. Java Pool
6. Streams Pool (optional)

------------------------------------------------------------
Shared Pool
------------------------------------------------------------

Contains:
- Library Cache (parsed SQL)
- Data Dictionary Cache

Purpose:
- Stores SQL execution plans
- Avoids re-parsing SQL
- Improves performance

------------------------------------------------------------
Database Buffer Cache
------------------------------------------------------------

- Stores data blocks read from disk
- All DML operations happen here first
- Changes written to disk later by DBWR

------------------------------------------------------------
Redo Log Buffer
------------------------------------------------------------

- Stores redo entries
- Redo written to redo log files by LGWR
- Used for recovery

------------------------------------------------------------
Large Pool
------------------------------------------------------------

Used for:
- RMAN
- Parallel execution
- Shared server

------------------------------------------------------------
4.2 PGA (Program Global Area)
------------------------------------------------------------

Private memory area.
One PGA per session.

Contains:
- Sort area
- Session variables
- Cursor information

Not shared between users.

------------------------------------------------------------
5. Background Processes
------------------------------------------------------------

Oracle uses background processes to manage database.

Important Background Processes:

1. PMON
2. SMON
3. DBWR
4. LGWR
5. CKPT
6. ARCn

------------------------------------------------------------
PMON (Process Monitor)
------------------------------------------------------------

- Cleans up failed user sessions
- Releases locks
- Frees resources

------------------------------------------------------------
SMON (System Monitor)
------------------------------------------------------------

- Performs instance recovery
- Cleans temporary segments

------------------------------------------------------------
DBWR (Database Writer)
------------------------------------------------------------

- Writes dirty buffers from Buffer Cache to Datafiles

------------------------------------------------------------
LGWR (Log Writer)
------------------------------------------------------------

- Writes redo from Redo Log Buffer to Redo Log Files
- Writes on COMMIT

------------------------------------------------------------
CKPT (Checkpoint Process)
------------------------------------------------------------

- Updates control file and datafile headers
- Signals DBWR

------------------------------------------------------------
ARCn (Archiver Process)
------------------------------------------------------------

- Copies redo logs to archive location
- Works only in ARCHIVELOG mode

------------------------------------------------------------
6. Physical Database Files
------------------------------------------------------------

1. Datafiles
2. Control Files
3. Redo Log Files
4. Archive Log Files

------------------------------------------------------------
Datafiles
------------------------------------------------------------

- Stores actual table data
- Stored inside tablespaces
- Extension: .dbf

------------------------------------------------------------
Control Files
------------------------------------------------------------

- Stores database metadata
- Database name
- File locations
- Checkpoint info

Very critical file.

------------------------------------------------------------
Redo Log Files
------------------------------------------------------------

- Stores redo records
- Used for crash recovery

------------------------------------------------------------
Archive Log Files
------------------------------------------------------------

- Copy of redo logs
- Required for point-in-time recovery

------------------------------------------------------------
7. Multitenant Architecture (CDB & PDB)
------------------------------------------------------------

Oracle 19c uses Multitenant Architecture.

CDB = Container Database
PDB = Pluggable Database

Structure:

CDB
 ├── CDB$ROOT
 ├── PDB$SEED
 ├── PDB1
 ├── PDB2

CDB$ROOT:
- Root container
- Stores Oracle metadata

PDB$SEED:
- Template for new PDBs

PDB:
- Actual user database

Important Commands:

Check current container:
SHOW CON_NAME;

Switch container:
ALTER SESSION SET CONTAINER = pdb1;

------------------------------------------------------------
8. Database Startup Stages
------------------------------------------------------------

1. NOMOUNT
   - Instance started
   - SGA allocated
   - Background processes started

2. MOUNT
   - Control file opened

3. OPEN
   - Datafiles and redo logs opened
   - Database available

Command:
STARTUP;

------------------------------------------------------------
9. Important Architecture Interview Questions
------------------------------------------------------------

- Difference between SGA and PGA?
- What happens during COMMIT?
- What is checkpoint?
- What is instance recovery?
- Difference between CDB and PDB?
- What is dirty buffer?

------------------------------------------------------------
10. Internal Working of DML (Architecture Level)
------------------------------------------------------------

Example: INSERT statement

1. SQL parsed in Shared Pool
2. Data block loaded into Buffer Cache
3. Changes made in memory
4. Redo generated in Redo Buffer
5. LGWR writes redo to disk
6. DBWR writes data to datafile later

COMMIT:
LGWR writes redo immediately.

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
