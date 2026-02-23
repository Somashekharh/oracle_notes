# 05_Exception_Handling.md
## Exception Handling in PL/SQL

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Exception handling allows us to handle runtime errors
gracefully instead of crashing the program.

Benefits:
- Prevent program failure
- Provide meaningful error messages
- Maintain transaction control
- Improve reliability

Structure:

DECLARE
BEGIN
EXCEPTION
END;

------------------------------------------------------------
2. Types of Exceptions
------------------------------------------------------------

1. Predefined Exceptions
2. User-Defined Exceptions
3. Non-Predefined Exceptions

------------------------------------------------------------
3. Predefined Exceptions
------------------------------------------------------------

Common predefined exceptions:

NO_DATA_FOUND
TOO_MANY_ROWS
ZERO_DIVIDE
DUP_VAL_ON_INDEX
VALUE_ERROR
INVALID_NUMBER

Example:

DECLARE
   v_name emp.name%TYPE;
BEGIN
   SELECT name INTO v_name
   FROM emp
   WHERE emp_id = 999;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
/

------------------------------------------------------------
4. TOO_MANY_ROWS Example
------------------------------------------------------------

DECLARE
   v_name emp.name%TYPE;
BEGIN
   SELECT name INTO v_name
   FROM emp;

EXCEPTION
   WHEN TOO_MANY_ROWS THEN
      DBMS_OUTPUT.PUT_LINE('Multiple rows returned');
END;
/

------------------------------------------------------------
5. User-Defined Exception
------------------------------------------------------------

Declare custom exception:

DECLARE
   ex_invalid_salary EXCEPTION;
   v_salary NUMBER := -1000;
BEGIN
   IF v_salary < 0 THEN
      RAISE ex_invalid_salary;
   END IF;

EXCEPTION
   WHEN ex_invalid_salary THEN
      DBMS_OUTPUT.PUT_LINE('Salary cannot be negative');
END;
/

------------------------------------------------------------
6. RAISE_APPLICATION_ERROR
------------------------------------------------------------

Used to generate custom error message.

Example:

BEGIN
   IF 100 < 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid Value');
   END IF;
END;
/

Error codes:
Must be between -20000 and -20999

------------------------------------------------------------
7. WHEN OTHERS Clause
------------------------------------------------------------

Catches all unhandled exceptions.

Example:

BEGIN
   SELECT 1/0 FROM dual;

EXCEPTION
   WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Cannot divide by zero');
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Unknown error');
END;
/

------------------------------------------------------------
8. SQLCODE and SQLERRM
------------------------------------------------------------

SQLCODE → Returns error number
SQLERRM → Returns error message

Example:

BEGIN
   SELECT 1/0 FROM dual;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error Code: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('Error Message: ' || SQLERRM);
END;
/

------------------------------------------------------------
9. Exception with Procedure
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
      ROLLBACK;
END;
/

------------------------------------------------------------
10. Exception Handling Best Practices
------------------------------------------------------------

✔ Handle specific exceptions first.
✔ Use WHEN OTHERS at the end.
✔ Log errors for debugging.
✔ Avoid hiding real errors.
✔ Do not use WHEN OTHERS without logging.

------------------------------------------------------------
11. Real-Time Scenarios
------------------------------------------------------------

Scenario 1:
User enters invalid salary.
→ Raise custom exception.

Scenario 2:
Duplicate primary key.
→ Catch DUP_VAL_ON_INDEX.

Scenario 3:
Query returns no rows.
→ Handle NO_DATA_FOUND.

Scenario 4:
Unexpected runtime error.
→ Log using SQLERRM.

------------------------------------------------------------
12. Important Interview Questions
------------------------------------------------------------

- What is exception handling?
- What is NO_DATA_FOUND?
- Difference between RAISE and RAISE_APPLICATION_ERROR?
- What is SQLCODE and SQLERRM?
- Why WHEN OTHERS should be last?
- Can we handle multiple exceptions?

------------------------------------------------------------
13. Golden Rule
------------------------------------------------------------

Good PL/SQL code:

1. Handles expected errors.
2. Logs unexpected errors.
3. Maintains transaction integrity.

------------------------------------------------------------
END OF FILE
------------------------------------------------------------# 05_Exception_Handling.md
## Exception Handling in PL/SQL

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Exception handling allows us to handle runtime errors
gracefully instead of crashing the program.

Benefits:
- Prevent program failure
- Provide meaningful error messages
- Maintain transaction control
- Improve reliability

Structure:

DECLARE
BEGIN
EXCEPTION
END;

------------------------------------------------------------
2. Types of Exceptions
------------------------------------------------------------

1. Predefined Exceptions
2. User-Defined Exceptions
3. Non-Predefined Exceptions

------------------------------------------------------------
3. Predefined Exceptions
------------------------------------------------------------

Common predefined exceptions:

NO_DATA_FOUND
TOO_MANY_ROWS
ZERO_DIVIDE
DUP_VAL_ON_INDEX
VALUE_ERROR
INVALID_NUMBER

Example:

DECLARE
   v_name emp.name%TYPE;
BEGIN
   SELECT name INTO v_name
   FROM emp
   WHERE emp_id = 999;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Employee not found');
END;
/

------------------------------------------------------------
4. TOO_MANY_ROWS Example
------------------------------------------------------------

DECLARE
   v_name emp.name%TYPE;
BEGIN
   SELECT name INTO v_name
   FROM emp;

EXCEPTION
   WHEN TOO_MANY_ROWS THEN
      DBMS_OUTPUT.PUT_LINE('Multiple rows returned');
END;
/

------------------------------------------------------------
5. User-Defined Exception
------------------------------------------------------------

Declare custom exception:

DECLARE
   ex_invalid_salary EXCEPTION;
   v_salary NUMBER := -1000;
BEGIN
   IF v_salary < 0 THEN
      RAISE ex_invalid_salary;
   END IF;

EXCEPTION
   WHEN ex_invalid_salary THEN
      DBMS_OUTPUT.PUT_LINE('Salary cannot be negative');
END;
/

------------------------------------------------------------
6. RAISE_APPLICATION_ERROR
------------------------------------------------------------

Used to generate custom error message.

Example:

BEGIN
   IF 100 < 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Invalid Value');
   END IF;
END;
/

Error codes:
Must be between -20000 and -20999

------------------------------------------------------------
7. WHEN OTHERS Clause
------------------------------------------------------------

Catches all unhandled exceptions.

Example:

BEGIN
   SELECT 1/0 FROM dual;

EXCEPTION
   WHEN ZERO_DIVIDE THEN
      DBMS_OUTPUT.PUT_LINE('Cannot divide by zero');
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Unknown error');
END;
/

------------------------------------------------------------
8. SQLCODE and SQLERRM
------------------------------------------------------------

SQLCODE → Returns error number
SQLERRM → Returns error message

Example:

BEGIN
   SELECT 1/0 FROM dual;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error Code: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('Error Message: ' || SQLERRM);
END;
/

------------------------------------------------------------
9. Exception with Procedure
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
      ROLLBACK;
END;
/

------------------------------------------------------------
10. Exception Handling Best Practices
------------------------------------------------------------

✔ Handle specific exceptions first.
✔ Use WHEN OTHERS at the end.
✔ Log errors for debugging.
✔ Avoid hiding real errors.
✔ Do not use WHEN OTHERS without logging.

------------------------------------------------------------
11. Real-Time Scenarios
------------------------------------------------------------

Scenario 1:
User enters invalid salary.
→ Raise custom exception.

Scenario 2:
Duplicate primary key.
→ Catch DUP_VAL_ON_INDEX.

Scenario 3:
Query returns no rows.
→ Handle NO_DATA_FOUND.

Scenario 4:
Unexpected runtime error.
→ Log using SQLERRM.

------------------------------------------------------------
12. Important Interview Questions
------------------------------------------------------------

- What is exception handling?
- What is NO_DATA_FOUND?
- Difference between RAISE and RAISE_APPLICATION_ERROR?
- What is SQLCODE and SQLERRM?
- Why WHEN OTHERS should be last?
- Can we handle multiple exceptions?

------------------------------------------------------------
13. Golden Rule
------------------------------------------------------------

Good PL/SQL code:

1. Handles expected errors.
2. Logs unexpected errors.
3. Maintains transaction integrity.

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
