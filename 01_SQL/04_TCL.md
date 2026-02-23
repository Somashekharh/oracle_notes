# 02_DML.md
## Data Manipulation Language (DML) – Oracle

------------------------------------------------------------
1. Introduction to DML
------------------------------------------------------------

Data Manipulation Language (DML) is used to manipulate data inside tables.

Unlike DDL:
- DML does NOT auto commit
- Changes can be rolled back
- Generates UNDO and REDO
- Works on rows, not structure

Main DML Commands:
- INSERT
- UPDATE
- DELETE
- MERGE


------------------------------------------------------------
2. INSERT
------------------------------------------------------------

Concept:
Used to insert new records into a table.

Syntax (Full Insert):
INSERT INTO table_name (column1, column2)
VALUES (value1, value2);

Example:
INSERT INTO emp (emp_id, name, salary)
VALUES (101, 'Ravi', 50000);

Syntax (Without Column Names):
INSERT INTO emp
VALUES (102, 'Amit', 45000, SYSDATE);

Insert Using SELECT:
INSERT INTO emp_backup
SELECT * FROM emp;

Important Notes:
- Column order must match if not specifying columns
- NULL allowed only if column permits
- Requires COMMIT to save permanently

Common Errors:
- ORA-00001: unique constraint violated
- ORA-01400: cannot insert NULL
- ORA-00947: not enough values

Interview Questions:
- Difference between INSERT and INSERT INTO SELECT?
- What happens if we don’t commit?


------------------------------------------------------------
3. UPDATE
------------------------------------------------------------

Concept:
Used to modify existing records.

Syntax:
UPDATE table_name
SET column_name = value
WHERE condition;

Example:
UPDATE emp
SET salary = 60000
WHERE emp_id = 101;

Update Multiple Columns:
UPDATE emp
SET salary = 55000,
    name = 'Ravi Kumar'
WHERE emp_id = 101;

Important Notes:
- WHERE clause is very important
- Without WHERE → updates all rows

Example (Dangerous):
UPDATE emp SET salary = 0;

Rollback Example:
ROLLBACK;

Common Errors:
- ORA-00904: invalid identifier

Interview Questions:
- What happens if WHERE clause missing?
- Does UPDATE generate undo?


------------------------------------------------------------
4. DELETE
------------------------------------------------------------

Concept:
Used to delete rows from table.

Syntax:
DELETE FROM table_name
WHERE condition;

Example:
DELETE FROM emp
WHERE emp_id = 101;

Delete All Rows:
DELETE FROM emp;

Important Notes:
- Can rollback before commit
- Generates UNDO
- Triggers will fire
- Slower than TRUNCATE

Rollback Example:
ROLLBACK;

Common Errors:
- ORA-02292: integrity constraint violated (child record found)

Interview Questions:
- Difference between DELETE and TRUNCATE?
- Does DELETE reset High Water Mark?


------------------------------------------------------------
5. MERGE
------------------------------------------------------------

Concept:
Used to insert or update data based on condition.
Also called UPSERT.

Syntax:
MERGE INTO target_table t
USING source_table s
ON (condition)
WHEN MATCHED THEN
   UPDATE SET column = value
WHEN NOT MATCHED THEN
   INSERT (columns) VALUES (values);

Example:
MERGE INTO emp e
USING emp_new n
ON (e.emp_id = n.emp_id)
WHEN MATCHED THEN
   UPDATE SET e.salary = n.salary
WHEN NOT MATCHED THEN
   INSERT (emp_id, name, salary)
   VALUES (n.emp_id, n.name, n.salary);

Real-Time Scenario:
Daily data sync from staging table to main table.

Interview Questions:
- When to use MERGE?
- Difference between MERGE and UPDATE?


------------------------------------------------------------
6. Transaction Control in DML
------------------------------------------------------------

DML works with transactions.

COMMIT:
Saves changes permanently.
COMMIT;

ROLLBACK:
Undo changes before commit.
ROLLBACK;

SAVEPOINT:
Creates point inside transaction.
SAVEPOINT sp1;

Rollback to savepoint:
ROLLBACK TO sp1;

Example Flow:
INSERT INTO emp VALUES (103, 'Suresh', 40000);
SAVEPOINT s1;
UPDATE emp SET salary = 45000 WHERE emp_id = 103;
ROLLBACK TO s1;
COMMIT;

Important:
After COMMIT → cannot rollback.


------------------------------------------------------------
7. Internal Working of DML
------------------------------------------------------------

When DML executed:
1. Row data modified in buffer cache
2. Undo generated (for rollback)
3. Redo generated (for recovery)
4. Changes visible after COMMIT

Important DBA Notes:
- Heavy DML increases undo tablespace usage
- Large DELETE operations may cause performance issues
- Always use WHERE clause carefully


------------------------------------------------------------
8. DML vs DDL
------------------------------------------------------------

DDL:
- Structure change
- Auto commit
- Minimal undo

DML:
- Data change
- Requires commit
- Generates undo


------------------------------------------------------------
END OF FILE
------------------------------------------------------------
