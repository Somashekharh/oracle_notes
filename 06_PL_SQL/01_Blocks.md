# 01_Blocks.md
## PL/SQL Blocks – Fundamentals

------------------------------------------------------------
1. Introduction to PL/SQL
------------------------------------------------------------

PL/SQL = Procedural Language extension of SQL.

It combines:
- SQL (data manipulation)
- Procedural programming (loops, conditions, variables)

Advantages:
- Better performance
- Code reusability
- Error handling
- Secure business logic implementation

------------------------------------------------------------
2. Structure of PL/SQL Block
------------------------------------------------------------

Basic Structure:

DECLARE
   -- Variable declarations
BEGIN
   -- Executable statements
EXCEPTION
   -- Error handling
END;
/

Sections:

1. DECLARE (Optional)
2. BEGIN (Mandatory)
3. EXCEPTION (Optional)
4. END (Mandatory)

------------------------------------------------------------
3. Simple PL/SQL Block Example
------------------------------------------------------------

BEGIN
   DBMS_OUTPUT.PUT_LINE('Hello Oracle');
END;
/

Enable output:

SET SERVEROUTPUT ON;

------------------------------------------------------------
4. Variables in PL/SQL
------------------------------------------------------------

Syntax:

variable_name datatype;

Example:

DECLARE
   v_name VARCHAR2(50);
   v_salary NUMBER;
BEGIN
   v_name := 'Ravi';
   v_salary := 50000;

   DBMS_OUTPUT.PUT_LINE(v_name || ' earns ' || v_salary);
END;
/

------------------------------------------------------------
5. Using SELECT INTO
------------------------------------------------------------

Used to fetch data into variable.

Example:

DECLARE
   v_name emp.name%TYPE;
BEGIN
   SELECT name
   INTO v_name
   FROM emp
   WHERE emp_id = 101;

   DBMS_OUTPUT.PUT_LINE(v_name);
END;
/

Important:
SELECT INTO must return exactly one row.

If no row:
NO_DATA_FOUND error.

If multiple rows:
TOO_MANY_ROWS error.

------------------------------------------------------------
6. %TYPE and %ROWTYPE
------------------------------------------------------------

%TYPE:
Variable inherits datatype of table column.

DECLARE
   v_salary emp.salary%TYPE;

%ROWTYPE:
Variable stores entire row.

DECLARE
   v_emp emp%ROWTYPE;

BEGIN
   SELECT *
   INTO v_emp
   FROM emp
   WHERE emp_id = 101;

   DBMS_OUTPUT.PUT_LINE(v_emp.name);
END;
/

------------------------------------------------------------
7. IF-THEN Condition
------------------------------------------------------------

Syntax:

IF condition THEN
   statements;
ELSIF condition THEN
   statements;
ELSE
   statements;
END IF;

Example:

DECLARE
   v_salary NUMBER := 60000;
BEGIN
   IF v_salary > 50000 THEN
      DBMS_OUTPUT.PUT_LINE('High Salary');
   ELSE
      DBMS_OUTPUT.PUT_LINE('Normal Salary');
   END IF;
END;
/

------------------------------------------------------------
8. Loops in PL/SQL
------------------------------------------------------------

8.1 Simple LOOP

DECLARE
   v_counter NUMBER := 1;
BEGIN
   LOOP
      DBMS_OUTPUT.PUT_LINE(v_counter);
      v_counter := v_counter + 1;
      EXIT WHEN v_counter > 5;
   END LOOP;
END;
/

------------------------------------------------------------
8.2 WHILE LOOP

DECLARE
   v_counter NUMBER := 1;
BEGIN
   WHILE v_counter <= 5 LOOP
      DBMS_OUTPUT.PUT_LINE(v_counter);
      v_counter := v_counter + 1;
   END LOOP;
END;
/

------------------------------------------------------------
8.3 FOR LOOP

BEGIN
   FOR i IN 1..5 LOOP
      DBMS_OUTPUT.PUT_LINE(i);
   END LOOP;
END;
/

------------------------------------------------------------
9. Cursors (Basic)
------------------------------------------------------------

Cursor is used to process multiple rows.

Implicit Cursor:
Automatically created for DML.

Explicit Cursor Example:

DECLARE
   CURSOR emp_cursor IS
      SELECT name FROM emp;

   v_name emp.name%TYPE;
BEGIN
   OPEN emp_cursor;
   LOOP
      FETCH emp_cursor INTO v_name;
      EXIT WHEN emp_cursor%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(v_name);
   END LOOP;
   CLOSE emp_cursor;
END;
/

------------------------------------------------------------
10. Nested Blocks
------------------------------------------------------------

BEGIN
   DECLARE
      v_num NUMBER := 10;
   BEGIN
      DBMS_OUTPUT.PUT_LINE(v_num);
   END;
END;
/

------------------------------------------------------------
11. Exception Handling (Basic)
------------------------------------------------------------

DECLARE
   v_name emp.name%TYPE;
BEGIN
   SELECT name INTO v_name
   FROM emp
   WHERE emp_id = 999;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No employee found');
END;
/

------------------------------------------------------------
12. Real-Time Scenarios
------------------------------------------------------------

Scenario 1:
Validate salary before insert.

Scenario 2:
Automate bonus calculation.

Scenario 3:
Generate reports using loops.

Scenario 4:
Perform bulk updates safely.

------------------------------------------------------------
13. Important Interview Questions
------------------------------------------------------------

- What is PL/SQL?
- Structure of PL/SQL block?
- What is %TYPE?
- What is %ROWTYPE?
- Difference between implicit and explicit cursor?
- What is SELECT INTO?
- What is NO_DATA_FOUND error?

------------------------------------------------------------
14. Golden Rule
------------------------------------------------------------

Use PL/SQL when:

- Business logic required
- Multiple SQL statements together
- Need error handling
- Need looping

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
