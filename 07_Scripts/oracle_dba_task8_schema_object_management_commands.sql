# =============================================================================
# Oracle DBA Task 8: Schema & Object Management - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as SYSDBA or as the schema owner (e.g., APP_USER)
# Assumes Task 1-7 are completed (database running)
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# Switch to PDB if needed
sqlplus / as sysdba << EOF
ALTER SESSION SET CONTAINER=ORCLPDB1;
EXIT;
EOF

# 2. CREATE / ALTER / DROP TABLE
sqlplus app_user/AppPass123# << EOF
-- Basic heap table
CREATE TABLE employees (
  emp_id      NUMBER PRIMARY KEY,
  first_name  VARCHAR2(50),
  last_name   VARCHAR2(50),
  hire_date   DATE DEFAULT SYSDATE,
  salary      NUMBER(10,2)
);

-- Partitioned table (Range)
CREATE TABLE sales (
  sale_id     NUMBER,
  sale_date   DATE,
  amount      NUMBER(12,2)
) PARTITION BY RANGE (sale_date) (
  PARTITION p2025 VALUES LESS THAN (TO_DATE('2026-01-01','YYYY-MM-DD')),
  PARTITION p2026 VALUES LESS THAN (TO_DATE('2027-01-01','YYYY-MM-DD'))
);

-- Alter table - add column, modify
ALTER TABLE employees ADD (email VARCHAR2(100));
ALTER TABLE employees MODIFY salary NUMBER(12,2);

-- Drop table (with purge to skip recyclebin)
DROP TABLE employees PURGE;
EXIT;
EOF

# 3. INDEX MANAGEMENT
sqlplus app_user/AppPass123# << EOF
-- Create B-tree index
CREATE INDEX idx_emp_lastname ON employees(last_name);

-- Create unique index
CREATE UNIQUE INDEX idx_emp_email ON employees(email);

-- Bitmap index (for low-cardinality columns)
CREATE BITMAP INDEX idx_emp_dept ON employees(dept_id);

-- Function-based index
CREATE INDEX idx_emp_uppername ON employees(UPPER(last_name));

-- Invisible index (for testing)
CREATE INDEX idx_test ON employees(hire_date) INVISIBLE;
ALTER INDEX idx_test VISIBLE;

-- Rebuild index online
ALTER INDEX idx_emp_lastname REBUILD ONLINE;

-- Drop index
DROP INDEX idx_test;
EXIT;
EOF

# 4. CONSTRAINTS
sqlplus app_user/AppPass123# << EOF
-- Add primary key, foreign key, check
ALTER TABLE employees ADD CONSTRAINT pk_emp PRIMARY KEY (emp_id);
ALTER TABLE employees ADD CONSTRAINT fk_dept FOREIGN KEY (dept_id) REFERENCES departments(dept_id);
ALTER TABLE employees ADD CONSTRAINT chk_salary CHECK (salary > 0);

-- Disable / Enable constraint
ALTER TABLE employees DISABLE CONSTRAINT chk_salary;
ALTER TABLE employees ENABLE CONSTRAINT chk_salary;
EXIT;
EOF

# 5. VIEWS & MATERIALIZED VIEWS
sqlplus app_user/AppPass123# << EOF
-- Simple view
CREATE OR REPLACE VIEW v_employees AS
SELECT emp_id, first_name, last_name, salary FROM employees;

-- Materialized View (fast refresh)
CREATE MATERIALIZED VIEW mv_sales_summary
BUILD IMMEDIATE
REFRESH FAST ON DEMAND
AS
SELECT sale_date, SUM(amount) total FROM sales GROUP BY sale_date;

-- Refresh MV
EXEC DBMS_MVIEW.REFRESH('MV_SALES_SUMMARY');
EXIT;
EOF

# 6. SEQUENCES & SYNONYMS
sqlplus app_user/AppPass123# << EOF
-- Create sequence
CREATE SEQUENCE seq_emp_id START WITH 1000 INCREMENT BY 1 NOCACHE;

-- Use in insert
INSERT INTO employees (emp_id, first_name, last_name) VALUES (seq_emp_id.NEXTVAL, 'John', 'Doe');

-- Public synonym
CREATE PUBLIC SYNONYM emp FOR employees;

-- Drop synonym
DROP PUBLIC SYNONYM emp;
EXIT;
EOF

# 7. PL/SQL OBJECTS (Procedures, Functions, Packages, Triggers)
sqlplus app_user/AppPass123# << EOF
-- Simple Procedure
CREATE OR REPLACE PROCEDURE raise_salary(p_emp_id IN NUMBER, p_percent IN NUMBER) AS
BEGIN
  UPDATE employees SET salary = salary * (1 + p_percent/100) WHERE emp_id = p_emp_id;
  COMMIT;
END;
/

-- Function
CREATE OR REPLACE FUNCTION get_emp_salary(p_emp_id NUMBER) RETURN NUMBER IS
  v_sal NUMBER;
BEGIN
  SELECT salary INTO v_sal FROM employees WHERE emp_id = p_emp_id;
  RETURN v_sal;
END;
/

-- Package
CREATE OR REPLACE PACKAGE emp_pkg AS
  PROCEDURE raise_salary(p_emp_id NUMBER, p_percent NUMBER);
  FUNCTION get_emp_salary(p_emp_id NUMBER) RETURN NUMBER;
END emp_pkg;
/

CREATE OR REPLACE PACKAGE BODY emp_pkg AS
  PROCEDURE raise_salary(p_emp_id NUMBER, p_percent NUMBER) IS
  BEGIN
    UPDATE employees SET salary = salary * (1 + p_percent/100) WHERE emp_id = p_emp_id;
    COMMIT;
  END;
  FUNCTION get_emp_salary(p_emp_id NUMBER) RETURN NUMBER IS
    v_sal NUMBER;
  BEGIN
    SELECT salary INTO v_sal FROM employees WHERE emp_id = p_emp_id;
    RETURN v_sal;
  END;
END emp_pkg;
/

-- Trigger
CREATE OR REPLACE TRIGGER trg_emp_before_insert
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
  :NEW.emp_id := seq_emp_id.NEXTVAL;
END;
/
EXIT;
EOF

# 8. COMPILE INVALID OBJECTS
sqlplus / as sysdba << EOF
-- Compile all invalid objects
@?/rdbms/admin/utlrp.sql

-- List invalid objects
SELECT object_name, object_type, status
FROM dba_objects
WHERE status = 'INVALID'
ORDER BY owner, object_type;
EXIT;
EOF

# 9. JSON, LOB & VECTOR (23ai) SUPPORT
sqlplus app_user/AppPass123# << EOF
-- JSON column
ALTER TABLE employees ADD (json_data JSON);

-- Insert JSON
INSERT INTO employees (emp_id, json_data) VALUES (1001, '{"skills":["SQL","Python"],"level":5}');

-- VECTOR column (23ai AI Vector Search)
ALTER TABLE employees ADD (embedding VECTOR);

-- Large Object (CLOB/BLOB)
ALTER TABLE employees ADD (resume CLOB);

-- Gather statistics after changes
EXEC DBMS_STATS.GATHER_TABLE_STATS('APP_USER', 'EMPLOYEES', cascade => TRUE);
EXIT;
EOF

# 10. OBJECT DEPENDENCIES & METADATA
sqlplus / as sysdba << EOF
-- Objects depending on a table
SELECT name, type, referenced_name
FROM dba_dependencies
WHERE referenced_name = 'EMPLOYEES'
  AND owner = 'APP_USER';

-- Object size report
SELECT segment_name, segment_type, bytes/1024/1024 AS size_mb
FROM dba_segments
WHERE owner = 'APP_USER'
ORDER BY bytes DESC;
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task8_schema_object_management_commands.txt
# Replace ORCLPDB1, app_user, AppPass123# with your actual values
# Always gather statistics after major schema changes
# Use ONLINE operations for zero-downtime in production
# Test all DDL in non-production first!
# =============================================================================