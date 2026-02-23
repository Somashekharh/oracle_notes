# 01_DDL.md
## Data Definition Language (DDL) – Oracle

------------------------------------------------------------
1. Introduction to DDL
------------------------------------------------------------

Data Definition Language (DDL) is used to define, modify, and remove database objects like tables, indexes, views, sequences, etc.

Key Characteristics:
- Used to define structure
- Affects database schema
- Automatically commits transaction
- Cannot be rolled back (in most cases)
- Updates Data Dictionary

Common DDL Commands:
- CREATE
- ALTER
- DROP
- TRUNCATE
- RENAME
- COMMENT


------------------------------------------------------------
2. CREATE TABLE
------------------------------------------------------------

Concept:
Used to create a new table in the database.

Syntax:
CREATE TABLE table_name (
   column_name datatype constraint,
   column_name datatype constraint
);

Example:
CREATE TABLE emp (
   emp_id NUMBER PRIMARY KEY,
   name VARCHAR2(50) NOT NULL,
   salary NUMBER(10,2),
   hire_date DATE DEFAULT SYSDATE
);

Common Datatypes:
- NUMBER
- NUMBER(p,s)
- VARCHAR2(size)
- DATE
- CHAR
- CLOB
- BLOB

Real-Time Scenario:
Create new table based on application requirement.

Common Errors:
- ORA-00955: name already used
- ORA-00904: invalid identifier
- ORA-01031: insufficient privileges

Interview Questions:
- Difference between NUMBER and NUMBER(10,2)?
- Does CREATE TABLE auto-commit?
- Does CREATE generate redo?


------------------------------------------------------------
3. ALTER TABLE
------------------------------------------------------------

Concept:
Used to modify structure of existing table.

Add Column:
ALTER TABLE emp ADD email VARCHAR2(100);

Modify Column:
ALTER TABLE emp MODIFY salary NUMBER(12,2);

Drop Column:
ALTER TABLE emp DROP COLUMN email;

Add Constraint:
ALTER TABLE emp ADD CONSTRAINT emp_email_uq UNIQUE(email);

Drop Constraint:
ALTER TABLE emp DROP CONSTRAINT emp_email_uq;

Important Notes:
- Cannot reduce column size if data exists.
- Dropping column removes data permanently.

Common Errors:
- ORA-01430: column already exists
- ORA-01440: cannot decrease precision

Interview Questions:
- Difference between DROP COLUMN and SET UNUSED?
- Can we change datatype directly?


------------------------------------------------------------
4. DROP TABLE
------------------------------------------------------------

Concept:
Completely removes table structure and data.

Syntax:
DROP TABLE table_name;

Example:
DROP TABLE emp;

Drop with Constraints:
DROP TABLE emp CASCADE CONSTRAINTS;

Recovery (if recyclebin enabled):
FLASHBACK TABLE emp TO BEFORE DROP;

Important Notes:
- Cannot rollback
- Removes indexes
- Auto commit

Interview Questions:
- Difference between DROP and TRUNCATE?
- What is Recycle Bin?


------------------------------------------------------------
5. TRUNCATE TABLE
------------------------------------------------------------

Concept:
Removes all rows but keeps structure.

Syntax:
TRUNCATE TABLE table_name;

Example:
TRUNCATE TABLE emp;

Key Points:
- Faster than DELETE
- Minimal undo
- Cannot rollback
- Resets High Water Mark

DELETE vs TRUNCATE:

DELETE:
- Can rollback
- Row by row
- Triggers fire

TRUNCATE:
- Cannot rollback
- Bulk operation
- Triggers do not fire

Interview Questions:
- Why is TRUNCATE faster?
- What is High Water Mark?


------------------------------------------------------------
6. RENAME
------------------------------------------------------------

Concept:
Used to rename object.

Syntax:
RENAME old_name TO new_name;

Example:
RENAME emp TO employees;

Notes:
- Only changes name
- Does not affect data


------------------------------------------------------------
7. CONSTRAINTS
------------------------------------------------------------

Constraints enforce data integrity.

Types:
1. PRIMARY KEY
2. UNIQUE
3. NOT NULL
4. CHECK
5. FOREIGN KEY

PRIMARY KEY:
- Unique
- Not null
- Only one per table

UNIQUE:
- Ensures uniqueness
- Allows one NULL

NOT NULL:
- Column must have value

CHECK:
- Validates condition
Example:
salary NUMBER CHECK (salary > 0)

FOREIGN KEY:
Maintains referential integrity.

Example:
CREATE TABLE department (
   dept_id NUMBER PRIMARY KEY,
   dept_name VARCHAR2(50) UNIQUE
);

CREATE TABLE emp (
   emp_id NUMBER PRIMARY KEY,
   name VARCHAR2(50) NOT NULL,
   salary NUMBER CHECK (salary > 0),
   dept_id NUMBER,
   CONSTRAINT fk_dept FOREIGN KEY (dept_id)
   REFERENCES department(dept_id)
);

ON DELETE CASCADE:
REFERENCES department(dept_id)
ON DELETE CASCADE;

Interview Questions:
- Difference between PRIMARY KEY and UNIQUE?
- Can table have multiple UNIQUE constraints?
- What is ON DELETE CASCADE?


------------------------------------------------------------
8. COMMENT
------------------------------------------------------------

Add comment to table:
COMMENT ON TABLE emp IS 'Employee Master Table';

Add comment to column:
COMMENT ON COLUMN emp.salary IS 'Employee Salary Amount';


------------------------------------------------------------
9. Internal Working of DDL
------------------------------------------------------------

When DDL executed:
1. SQL parsed in Shared Pool
2. Data Dictionary updated
3. Space allocated in tablespace
4. Redo generated
5. Auto commit issued

Important DBA Points:
- Implicit commit before and after DDL
- DDL locks table structure
- Updates system catalog tables
- Generates redo but minimal undo


------------------------------------------------------------
END OF FILE
------------------------------------------------------------
