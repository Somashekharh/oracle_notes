# 05_JOINS_Advanced.md
## JOINS – Advanced Level (Oracle)

------------------------------------------------------------
1. Introduction to Joins
------------------------------------------------------------

Joins are used to retrieve data from multiple tables based on related columns.

Real-Time Example:
emp table → employee details
department table → department details

Common column: dept_id

Joins combine rows from two or more tables.


------------------------------------------------------------
2. Types of Joins
------------------------------------------------------------

1. INNER JOIN
2. LEFT OUTER JOIN
3. RIGHT OUTER JOIN
4. FULL OUTER JOIN
5. CROSS JOIN
6. SELF JOIN


------------------------------------------------------------
3. INNER JOIN
------------------------------------------------------------

Concept:
Returns only matching rows from both tables.

Syntax:
SELECT columns
FROM table1 t1
INNER JOIN table2 t2
ON t1.column = t2.column;

Example:
SELECT e.emp_id, e.name, d.dept_name
FROM emp e
INNER JOIN department d
ON e.dept_id = d.dept_id;

Result:
Only employees with valid department.


------------------------------------------------------------
4. LEFT OUTER JOIN
------------------------------------------------------------

Concept:
Returns all rows from left table
+ matching rows from right table
+ NULL if no match

Syntax:
SELECT columns
FROM table1 t1
LEFT JOIN table2 t2
ON t1.column = t2.column;

Example:
SELECT e.emp_id, e.name, d.dept_name
FROM emp e
LEFT JOIN department d
ON e.dept_id = d.dept_id;

Result:
All employees shown
If no department → dept_name = NULL


------------------------------------------------------------
5. RIGHT OUTER JOIN
------------------------------------------------------------

Concept:
Returns all rows from right table
+ matching rows from left table

Example:
SELECT e.emp_id, e.name, d.dept_name
FROM emp e
RIGHT JOIN department d
ON e.dept_id = d.dept_id;

Result:
All departments shown
Even if no employees assigned.


------------------------------------------------------------
6. FULL OUTER JOIN
------------------------------------------------------------

Concept:
Returns all rows from both tables.
Non-matching rows filled with NULL.

Example:
SELECT e.emp_id, e.name, d.dept_name
FROM emp e
FULL OUTER JOIN department d
ON e.dept_id = d.dept_id;


------------------------------------------------------------
7. CROSS JOIN
------------------------------------------------------------

Concept:
Cartesian product.
Every row from table1 combines with every row from table2.

Example:
SELECT *
FROM emp
CROSS JOIN department;

If emp has 5 rows
department has 3 rows
Result = 15 rows

Use carefully.


------------------------------------------------------------
8. SELF JOIN
------------------------------------------------------------

Concept:
Join table with itself.

Example:
Find employee and manager:

SELECT e.name AS employee,
       m.name AS manager
FROM emp e
LEFT JOIN emp m
ON e.manager_id = m.emp_id;


------------------------------------------------------------
9. Old Oracle Join Syntax
------------------------------------------------------------

Old outer join operator: (+)

Example:
SELECT e.emp_id, e.name, d.dept_name
FROM emp e, department d
WHERE e.dept_id = d.dept_id(+);

Note:
Old syntax not recommended.


------------------------------------------------------------
10. Join vs Subquery
------------------------------------------------------------

Join:
Used when retrieving related data columns.

Subquery:
Used when filtering based on another query.

Performance:
Joins usually faster than correlated subqueries.


------------------------------------------------------------
11. Join Execution Order
------------------------------------------------------------

Logical order:
1. FROM
2. JOIN
3. WHERE
4. GROUP BY
5. HAVING
6. SELECT
7. ORDER BY

Oracle uses optimizer to decide join method:
- Nested Loop
- Hash Join
- Sort Merge Join


------------------------------------------------------------
12. Real-Time Interview Scenarios
------------------------------------------------------------

Q: Get employees with department name.
→ INNER JOIN

Q: Get employees even without department.
→ LEFT JOIN

Q: Get departments without employees.
→ LEFT JOIN with WHERE e.emp_id IS NULL

Example:
SELECT d.dept_name
FROM department d
LEFT JOIN emp e
ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL;


------------------------------------------------------------
13. Performance Tips
------------------------------------------------------------

- Join on indexed columns
- Avoid joining large tables without condition
- Use proper WHERE filters
- Check execution plan


------------------------------------------------------------
END OF FILE
------------------------------------------------------------
