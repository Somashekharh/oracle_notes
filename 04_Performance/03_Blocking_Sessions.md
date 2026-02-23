# 03_Blocking_Sessions.md
## Oracle Blocking Sessions, Locks & Deadlocks

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Blocking occurs when one session holds a lock
and another session waits for it to release.

Common causes:
- Long uncommitted transactions
- Missing WHERE clause updates
- Application errors
- Poor transaction handling

Blocking leads to:
- Application freeze
- Slow response
- User complaints

------------------------------------------------------------
2. What is a Lock?
------------------------------------------------------------

Lock is a mechanism to maintain data consistency.

Types of locks:

1. Row-Level Lock (TX)
   - Created during DML
   - Locks only specific rows

2. Table-Level Lock (TM)
   - Created during DDL
   - Can block entire table

------------------------------------------------------------
3. Identify Blocking Sessions
------------------------------------------------------------

Basic query:

SELECT sid,
       serial#,
       username,
       blocking_session
FROM v$session
WHERE blocking_session IS NOT NULL;

blocking_session column shows who is blocking.

------------------------------------------------------------
4. Find Blocking Chain (Detailed)
------------------------------------------------------------

SELECT s1.sid AS blocker_sid,
       s1.username AS blocker_user,
       s2.sid AS blocked_sid,
       s2.username AS blocked_user
FROM v$session s1,
     v$session s2
WHERE s1.sid = s2.blocking_session;

------------------------------------------------------------
5. Check Locks in Database
------------------------------------------------------------

SELECT l.session_id,
       s.username,
       l.locked_mode,
       o.object_name
FROM v$locked_object l,
     dba_objects o,
     v$session s
WHERE l.object_id = o.object_id
AND l.session_id = s.sid;

locked_mode values:

0 = None
1 = Null
2 = Row-S (SS)
3 = Row-X (SX)
4 = Share
5 = S/Row-X
6 = Exclusive

------------------------------------------------------------
6. Find Blocking SQL
------------------------------------------------------------

SELECT s.sid,
       s.username,
       q.sql_text
FROM v$session s,
     v$sql q
WHERE s.sql_id = q.sql_id
AND s.sid IN (
    SELECT blocking_session
    FROM v$session
    WHERE blocking_session IS NOT NULL
);

------------------------------------------------------------
7. Resolve Blocking
------------------------------------------------------------

Step 1:
Contact application team if possible.

Step 2:
Check if transaction can be committed.

Step 3:
If urgent, kill session:

ALTER SYSTEM KILL SESSION 'sid,serial#';

------------------------------------------------------------
8. Deadlock
------------------------------------------------------------

Deadlock occurs when:

Session A waits for Session B
Session B waits for Session A

Oracle automatically detects deadlock
and kills one session.

Error:
ORA-00060: deadlock detected

Deadlock information stored in alert log.

------------------------------------------------------------
9. Check Wait Events
------------------------------------------------------------

SELECT sid,
       username,
       event,
       wait_time,
       seconds_in_wait
FROM v$session
WHERE state='WAITING';

Common wait events:

- enq: TX - row lock contention
- db file sequential read
- log file sync
- buffer busy waits

------------------------------------------------------------
10. Check Blocking Wait Event
------------------------------------------------------------

SELECT sid,
       username,
       event
FROM v$session
WHERE event LIKE '%lock%';

------------------------------------------------------------
11. Real-Time DBA Scenarios
------------------------------------------------------------

Scenario 1:
Application stuck.
→ Check blocking_session.
→ Identify blocker.

Scenario 2:
High "row lock contention".
→ Find uncommitted transaction.
→ Kill if required.

Scenario 3:
Deadlock error in application.
→ Check alert log.
→ Review SQL logic.

Scenario 4:
Long transaction holding locks.
→ Ask developer to commit frequently.

------------------------------------------------------------
12. Best Practices to Avoid Blocking
------------------------------------------------------------

- Keep transactions short.
- Commit frequently.
- Avoid full table updates without WHERE.
- Use proper indexes.
- Avoid unnecessary table locks.

------------------------------------------------------------
13. Important Interview Questions
------------------------------------------------------------

- What is blocking session?
- What is deadlock?
- What is row lock contention?
- How to identify blocking chain?
- What is ORA-00060?
- Difference between row-level and table-level lock?

------------------------------------------------------------
14. Golden Rule
------------------------------------------------------------

Never kill session blindly.
Always:

1. Identify blocking chain.
2. Check SQL.
3. Understand business impact.
4. Take controlled action.

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
