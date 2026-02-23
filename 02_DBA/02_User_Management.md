# 02_User_Management.md
## Oracle User Management & Privileges

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

User Management in Oracle is used to:

- Create users
- Assign privileges
- Manage access control
- Enforce security policies

Only privileged users (like SYS or SYSTEM) can create/manage users.

------------------------------------------------------------
2. CREATE USER
------------------------------------------------------------

Concept:
Creates a new database user.

Basic Syntax:
CREATE USER username
IDENTIFIED BY password;

Example:
CREATE USER hr_user
IDENTIFIED BY hr123;

Important:
User cannot login until privileges are granted.

------------------------------------------------------------
3. Create User with Tablespace
------------------------------------------------------------

Better Practice:

CREATE USER hr_user
IDENTIFIED BY hr123
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON users;

Explanation:
DEFAULT TABLESPACE → Where objects will be stored
TEMPORARY TABLESPACE → Used for sorting
QUOTA → Space allocation limit

------------------------------------------------------------
4. Granting Privileges
------------------------------------------------------------

Types of Privileges:

1. System Privileges
2. Object Privileges

------------------------------------------------------------
4.1 System Privileges
------------------------------------------------------------

Allows user to perform administrative actions.

Examples:
- CREATE SESSION
- CREATE TABLE
- CREATE VIEW
- CREATE PROCEDURE
- DROP ANY TABLE

Grant Example:
GRANT CREATE SESSION TO hr_user;
GRANT CREATE TABLE TO hr_user;

To allow login:
GRANT CREATE SESSION TO hr_user;

------------------------------------------------------------
4.2 Object Privileges
------------------------------------------------------------

Allows user to perform actions on specific objects.

Examples:
- SELECT
- INSERT
- UPDATE
- DELETE
- EXECUTE

Grant Example:
GRANT SELECT, INSERT ON emp TO hr_user;

Grant with Grant Option:
GRANT SELECT ON emp TO hr_user WITH GRANT OPTION;

------------------------------------------------------------
5. Roles
------------------------------------------------------------

Role:
Collection of privileges.

Common Roles:
- CONNECT
- RESOURCE
- DBA

Grant Role:
GRANT CONNECT TO hr_user;
GRANT RESOURCE TO hr_user;

Revoke Role:
REVOKE CONNECT FROM hr_user;

Best Practice:
Create custom roles instead of using DBA.

Example:
CREATE ROLE hr_role;
GRANT CREATE SESSION, CREATE TABLE TO hr_role;
GRANT hr_role TO hr_user;

------------------------------------------------------------
6. REVOKE Privileges
------------------------------------------------------------

Removes granted privilege.

Example:
REVOKE CREATE TABLE FROM hr_user;
REVOKE SELECT ON emp FROM hr_user;

------------------------------------------------------------
7. ALTER USER
------------------------------------------------------------

Change Password:
ALTER USER hr_user IDENTIFIED BY newpass123;

Unlock Account:
ALTER USER hr_user ACCOUNT UNLOCK;

Lock Account:
ALTER USER hr_user ACCOUNT LOCK;

Change Default Tablespace:
ALTER USER hr_user DEFAULT TABLESPACE users;

------------------------------------------------------------
8. DROP USER
------------------------------------------------------------

Deletes user from database.

Syntax:
DROP USER username;

If user owns objects:
DROP USER hr_user CASCADE;

CASCADE removes all objects owned by user.

------------------------------------------------------------
9. Profiles
------------------------------------------------------------

Profile:
Used to enforce password policies and resource limits.

Create Profile:
CREATE PROFILE secure_profile
LIMIT
  PASSWORD_LIFE_TIME 30
  FAILED_LOGIN_ATTEMPTS 3
  PASSWORD_LOCK_TIME 1;

Assign Profile:
ALTER USER hr_user PROFILE secure_profile;

Check Profile:
SELECT username, profile FROM dba_users;

------------------------------------------------------------
10. Important Data Dictionary Views
------------------------------------------------------------

Check Users:
SELECT username FROM dba_users;

Check User Privileges:
SELECT * FROM dba_sys_privs WHERE grantee='HR_USER';

Check Object Privileges:
SELECT * FROM dba_tab_privs WHERE grantee='HR_USER';

Check Roles:
SELECT * FROM dba_role_privs WHERE grantee='HR_USER';

------------------------------------------------------------
11. Real-Time DBA Scenarios
------------------------------------------------------------

Scenario 1:
Application user cannot login.
→ Check CREATE SESSION privilege.

Scenario 2:
User cannot create table.
→ Check CREATE TABLE privilege.

Scenario 3:
Account locked after wrong attempts.
→ Unlock user.

Scenario 4:
Need to remove user completely.
→ DROP USER CASCADE.

------------------------------------------------------------
12. Security Best Practices
------------------------------------------------------------

- Never use DBA role for application users
- Use least privilege principle
- Use profiles for password policy
- Avoid granting ANY privileges
- Monitor powerful users regularly

------------------------------------------------------------
13. Interview Questions
------------------------------------------------------------

- Difference between System and Object privilege?
- What is WITH GRANT OPTION?
- Difference between Role and Privilege?
- What is profile?
- Difference between DROP USER and DROP USER CASCADE?

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
