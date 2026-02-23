# 03_Functions.md
## Functions in Oracle PL/SQL

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Function is a named PL/SQL block
that must return a value.

Difference from Procedure:
Procedure → May or may not return value.
Function → Must return value.

Functions can be:
- Called inside SQL
- Used in SELECT statements
- Used in expressions

------------------------------------------------------------
2. Basic Function Syntax
------------------------------------------------------------

CREATE OR REPLACE FUNCTION function_name
RETURN datatype
IS
BEGIN
   -- statements
   RETURN value;
END;
/

------------------------------------------------------------
3. Simple Function Example
------------------------------------------------------------

CREATE OR REPLACE FUNCTION greet
RETURN VARCHAR2
IS
BEGIN
   RETURN 'Welcome to Oracle';
END;
/

Execute:

SELECT greet FROM dual;

------------------------------------------------------------
4. Function with Parameter
------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_salary (
   p_emp_id IN NUMBER
)
RETURN NUMBER
IS
   v_salary emp.salary%TYPE;
BEGIN
   SELECT salary INTO v_salary
   FROM emp
   WHERE emp_id = p_emp_id;

   RETURN v_salary;
END;
/

Call in SQL:

SELECT get_salary(101) FROM dual;

------------------------------------------------------------
5. Function Used in SELECT
------------------------------------------------------------

SELECT emp_id,
       name,
       get_salary(emp_id) salary
FROM emp;

------------------------------------------------------------
6. Function with Conditional Logic
------------------------------------------------------------

CREATE OR REPLACE FUNCTION salary_category (
   p_salary IN NUMBER
)
RETURN VARCHAR2
IS
BEGIN
   IF p_salary > 50000 THEN
      RETURN 'High';
   ELSE
      RETURN 'Normal';
   END IF;
END;
/

------------------------------------------------------------
7. Function with Exception Handling
------------------------------------------------------------

CREATE OR REPLACE FUNCTION safe_get_salary (
   p_emp_id IN NUMBER
)
RETURN NUMBER
IS
   v_salary emp.salary%TYPE;
BEGIN
   SELECT salary INTO v_salary
   FROM emp
   WHERE emp_id = p_emp_id;

   RETURN v_salary;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN 0;
END;
/

------------------------------------------------------------
8. Deterministic Function
------------------------------------------------------------

If function always returns same output
for same input → use DETERMINISTIC keyword.

Example:

CREATE OR REPLACE FUNCTION double_value (
   p_num NUMBER
)
RETURN NUMBER DETERMINISTIC
IS
BEGIN
   RETURN p_num * 2;
END;
/

Improves performance for repeated calls.

------------------------------------------------------------
9. Difference Between Procedure and Function
------------------------------------------------------------

Procedure:
- Can return multiple values (OUT parameters)
- Called using EXEC
- Not directly used in SQL

Function:
- Must return one value
- Used inside SQL
- Called in SELECT

------------------------------------------------------------
10. Function Restrictions in SQL
------------------------------------------------------------

Function used in SQL must:

- Not commit or rollback
- Not modify database
- Not call non-deterministic operations

------------------------------------------------------------
11. View Function Code
------------------------------------------------------------

SELECT text
FROM user_source
WHERE name='GET_SALARY'
ORDER BY line;

------------------------------------------------------------
12. Drop Function
------------------------------------------------------------

DROP FUNCTION get_salary;

------------------------------------------------------------
13. Real-Time Scenarios
------------------------------------------------------------

Scenario 1:
Calculate tax for salary.

Scenario 2:
Classify employee grade.

Scenario 3:
Generate formatted ID.

Scenario 4:
Reusable calculation logic across application.

------------------------------------------------------------
14. Important Interview Questions
------------------------------------------------------------

- Difference between procedure and function?
- Can function commit?
- What is deterministic function?
- Can function be used in SELECT?
- What happens if function raises exception?
- Why function cannot perform DML when used in SQL?

------------------------------------------------------------
15. Golden Rule
------------------------------------------------------------

Use function when:

- You need a return value
- Logic used in SQL queries
- Calculation required repeatedly

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
