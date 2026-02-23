# 02_Procedures.md
## Stored Procedures in Oracle PL/SQL

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Procedure is a named PL/SQL block stored in the database.

Used for:
- Reusable business logic
- Reducing code repetition
- Improving performance
- Enhancing security

Advantages:
- Stored in database
- Compiled once, reused many times
- Can accept parameters
- Can handle exceptions

------------------------------------------------------------
2. Basic Procedure Syntax
------------------------------------------------------------

CREATE OR REPLACE PROCEDURE procedure_name
IS
BEGIN
   -- statements
END;
/

Execute procedure:

EXEC procedure_name;

------------------------------------------------------------
3. Simple Procedure Example
------------------------------------------------------------

CREATE OR REPLACE PROCEDURE greet_user
IS
BEGIN
   DBMS_OUTPUT.PUT_LINE('Welcome to Oracle');
END;
/

Execute:

EXEC greet_user;

------------------------------------------------------------
4. Procedure with Parameters
------------------------------------------------------------

Parameters allow passing values.

Types:
1. IN (Default)
2. OUT
3. IN OUT

------------------------------------------------------------
4.1 IN Parameter Example
------------------------------------------------------------

CREATE OR REPLACE PROCEDURE show_salary (
   p_emp_id IN NUMBER
)
IS
   v_salary emp.salary%TYPE;
BEGIN
   SELECT salary INTO v_salary
   FROM emp
   WHERE emp_id = p_emp_id;

   DBMS_OUTPUT.PUT_LINE('Salary: ' || v_salary);
END;
/

Execute:

EXEC show_salary(101);

------------------------------------------------------------
4.2 OUT Parameter Example
------------------------------------------------------------

CREATE OR REPLACE PROCEDURE get_salary (
   p_emp_id IN NUMBER,
   p_salary OUT NUMBER
)
IS
BEGIN
   SELECT salary INTO p_salary
   FROM emp
   WHERE emp_id = p_emp_id;
END;
/

Execute:

DECLARE
   v_sal NUMBER;
BEGIN
   get_salary(101, v_sal);
   DBMS_OUTPUT.PUT_LINE(v_sal);
END;
/

------------------------------------------------------------
4.3 IN OUT Parameter Example
------------------------------------------------------------

CREATE OR REPLACE PROCEDURE increase_salary (
   p_salary IN OUT NUMBER
)
IS
BEGIN
   p_salary := p_salary + 1000;
END;
/

------------------------------------------------------------
5. Procedure with DML
------------------------------------------------------------

CREATE OR REPLACE PROCEDURE add_employee (
   p_id NUMBER,
   p_name VARCHAR2,
   p_salary NUMBER
)
IS
BEGIN
   INSERT INTO emp(emp_id, name, salary)
   VALUES (p_id, p_name, p_salary);

   COMMIT;
END;
/

------------------------------------------------------------
6. Procedure with Exception Handling
------------------------------------------------------------

CREATE OR REPLACE PROCEDURE safe_insert (
   p_id NUMBER
)
IS
BEGIN
   INSERT INTO emp(emp_id) VALUES (p_id);
   COMMIT;

EXCEPTION
   WHEN DUP_VAL_ON_INDEX THEN
      DBMS_OUTPUT.PUT_LINE('Duplicate ID');
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error occurred');
END;
/

------------------------------------------------------------
7. View Procedure Code
------------------------------------------------------------

SELECT text
FROM user_source
WHERE name='SAFE_INSERT'
ORDER BY line;

------------------------------------------------------------
8. Drop Procedure
------------------------------------------------------------

DROP PROCEDURE safe_insert;

------------------------------------------------------------
9. Compile Procedure
------------------------------------------------------------

ALTER PROCEDURE safe_insert COMPILE;

Check invalid objects:

SELECT object_name, status
FROM user_objects
WHERE object_type='PROCEDURE';

------------------------------------------------------------
10. Real-Time Scenarios
------------------------------------------------------------

Scenario 1:
Insert employee with validation logic.

Scenario 2:
Automate monthly bonus calculation.

Scenario 3:
Batch update salary.

Scenario 4:
Encapsulate complex SQL inside procedure.

------------------------------------------------------------
11. Security Advantage
------------------------------------------------------------

Grant execute permission:

GRANT EXECUTE ON add_employee TO hr_user;

User can execute procedure
without direct table access.

------------------------------------------------------------
12. Important Interview Questions
------------------------------------------------------------

- What is stored procedure?
- Difference between procedure and function?
- What is IN, OUT, IN OUT parameter?
- How to handle exceptions in procedure?
- How to check procedure source code?
- Why use procedures instead of raw SQL?

------------------------------------------------------------
13. Golden Rule
------------------------------------------------------------

Use procedures when:

- Business logic must be centralized
- Multiple SQL statements required
- Need security control
- Need reusability

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
