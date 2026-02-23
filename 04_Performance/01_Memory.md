# 01_Memory.md
## Oracle Memory Architecture & Basic Tuning

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Oracle performance heavily depends on memory management.

Two main memory areas:

1. SGA (System Global Area) – Shared Memory
2. PGA (Program Global Area) – Private Memory

Proper tuning improves:
- Query performance
- Transaction speed
- System stability

------------------------------------------------------------
2. SGA (System Global Area)
------------------------------------------------------------

Shared memory area used by all sessions.

Main Components:

1. Shared Pool
2. Database Buffer Cache
3. Redo Log Buffer
4. Large Pool
5. Java Pool
6. Streams Pool (optional)

Check SGA size:

SHOW PARAMETER sga;

Or:

SELECT name, value
FROM v$sga;

------------------------------------------------------------
2.1 Shared Pool
------------------------------------------------------------

Stores:
- SQL execution plans
- Parsed queries
- Data dictionary cache

If too small:
- Hard parsing increases
- Performance degrades

Check shared pool size:

SHOW PARAMETER shared_pool_size;

------------------------------------------------------------
2.2 Database Buffer Cache
------------------------------------------------------------

Stores:
- Data blocks read from disk
- All DML operations occur here first

If too small:
- Frequent physical reads
- High I/O

Check buffer cache size:

SHOW PARAMETER db_cache_size;

------------------------------------------------------------
2.3 Redo Log Buffer
------------------------------------------------------------

Stores redo entries before writing to redo log files.

Check redo buffer:

SHOW PARAMETER log_buffer;

------------------------------------------------------------
3. PGA (Program Global Area)
------------------------------------------------------------

Private memory per session.

Contains:
- Sort area
- Hash join area
- Session variables

Check PGA:

SHOW PARAMETER pga;

Check total PGA usage:

SELECT name, value
FROM v$pgastat;

------------------------------------------------------------
4. Automatic Memory Management
------------------------------------------------------------

Oracle supports:

1. Automatic Shared Memory Management (ASMM)
2. Automatic Memory Management (AMM)

------------------------------------------------------------
4.1 AMM (Automatic Memory Management)
------------------------------------------------------------

Oracle automatically manages SGA + PGA.

Enable AMM:

ALTER SYSTEM SET memory_target=2G SCOPE=BOTH;
ALTER SYSTEM SET memory_max_target=2G SCOPE=SPFILE;

Check:

SHOW PARAMETER memory_target;

------------------------------------------------------------
4.2 ASMM
------------------------------------------------------------

Manages SGA automatically.

Enable:

ALTER SYSTEM SET sga_target=1G SCOPE=BOTH;

------------------------------------------------------------
5. Check Memory Usage
------------------------------------------------------------

Check SGA dynamic components:

SELECT component, current_size/1024/1024 MB
FROM v$sga_dynamic_components;

Check PGA usage:

SELECT pga_used_mem/1024/1024 MB
FROM v$process;

Top PGA sessions:

SELECT s.username,
       p.spid,
       p.pga_used_mem/1024/1024 MB
FROM v$process p, v$session s
WHERE p.addr = s.paddr
ORDER BY p.pga_used_mem DESC;

------------------------------------------------------------
6. Memory Tuning Indicators
------------------------------------------------------------

High Physical Reads:
→ Increase db_cache_size

High Hard Parsing:
→ Increase shared_pool_size

Sort operations to disk:
→ Increase pga_aggregate_target

Check sort operations:

SELECT name, value
FROM v$sysstat
WHERE name LIKE '%sort%';

------------------------------------------------------------
7. Important Performance Views
------------------------------------------------------------

V$SGA
V$SGAINFO
V$PGASTAT
V$PROCESS
V$SESSION
V$SYSSTAT

------------------------------------------------------------
8. Real-Time DBA Scenarios
------------------------------------------------------------

Scenario 1:
High CPU usage.
→ Check hard parsing.
→ Increase shared pool.

Scenario 2:
High disk I/O.
→ Check buffer cache.
→ Increase db_cache_size.

Scenario 3:
Frequent sorting to disk.
→ Increase PGA.

Scenario 4:
Memory pressure error.
→ Adjust memory_target.

------------------------------------------------------------
9. Memory Concepts for Interview
------------------------------------------------------------

- Difference between SGA and PGA?
- What is shared pool?
- What causes hard parsing?
- What is buffer cache?
- What is memory_target?
- Difference between AMM and ASMM?

------------------------------------------------------------
10. Golden Rules
------------------------------------------------------------

- Use automatic memory management in modern systems.
- Monitor before changing parameters.
- Avoid frequent manual memory changes.
- Always check alert log after memory change.

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
