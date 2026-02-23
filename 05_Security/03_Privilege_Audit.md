# 01_Auditing.md
## Oracle Auditing (Security Monitoring)

------------------------------------------------------------
1. Introduction
------------------------------------------------------------

Auditing is used to track:

- Who logged in
- Who executed commands
- Who modified data
- Who accessed sensitive objects

Auditing is critical for:
- Security compliance
- Forensic investigation
- Detecting unauthorized activity
- Meeting regulatory requirements

------------------------------------------------------------
2. Types of Auditing in Oracle
------------------------------------------------------------

1. Standard Auditing
2. Fine-Grained Auditing (FGA)
3. Unified Auditing (12c+ recommended)

------------------------------------------------------------
3. Check Audit Status
------------------------------------------------------------

Check if auditing enabled:

SHOW PARAMETER audit_trail;

Values:
NONE → Auditing disabled
DB → Stored in database
DB,EXTENDED → Includes SQL text
OS → Stored in OS files

------------------------------------------------------------
4. Enable Standard Auditing
------------------------------------------------------------

Enable auditing in SPFILE:

ALTER SYSTEM SET audit_trail=DB SCOPE=SPFILE;

Restart database:

SHUTDOWN IMMEDIATE;
STARTUP;

Verify:

SHOW PARAMETER audit_trail;

------------------------------------------------------------
5. Audit User Login
------------------------------------------------------------

Audit successful and failed logins:

AUDIT SESSION;

View login records:

SELECT username,
       action_name,
       returncode,
       timestamp
FROM dba_audit_session;

returncode:
0 → Success
Non-zero → Failed login

------------------------------------------------------------
6. Audit Table Access
------------------------------------------------------------

Audit SELECT on emp table:

AUDIT SELECT ON hr.emp;

Check audit records:

SELECT username,
       obj_name,
       action_name,
       timestamp
FROM dba_audit_trail
WHERE obj_name='EMP';

------------------------------------------------------------
7. Audit DML Operations
------------------------------------------------------------

Audit INSERT, UPDATE, DELETE:

AUDIT INSERT, UPDATE, DELETE ON hr.emp;

------------------------------------------------------------
8. Disable Auditing
------------------------------------------------------------

Disable specific audit:

NOAUDIT SELECT ON hr.emp;

Disable session audit:

NOAUDIT SESSION;

------------------------------------------------------------
9. Fine-Grained Auditing (FGA)
------------------------------------------------------------

Used for conditional auditing.

Example:
Audit when salary > 100000.

BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema => 'HR',
    object_name   => 'EMP',
    policy_name   => 'salary_audit',
    audit_condition => 'salary > 100000',
    audit_column  => 'salary'
  );
END;
/

Check FGA logs:

SELECT *
FROM dba_fga_audit_trail;

------------------------------------------------------------
10. Unified Auditing (12c+)
------------------------------------------------------------

Unified auditing combines:
- Standard audit
- FGA
- RMAN audit
- Privilege audit

Check unified audit:

SELECT *
FROM unified_audit_trail;

Create unified audit policy:

CREATE AUDIT POLICY login_audit
ACTIONS LOGON;

Enable policy:

AUDIT POLICY login_audit;

------------------------------------------------------------
11. Audit Important Activities
------------------------------------------------------------

Audit user creation:

AUDIT CREATE USER;

Audit privilege grants:

AUDIT GRANT ANY PRIVILEGE;

Audit system changes:

AUDIT ALTER SYSTEM;

------------------------------------------------------------
12. Clean Audit Trail
------------------------------------------------------------

Audit tables grow large.

Clean old records:

DELETE FROM sys.aud$
WHERE timestamp < SYSDATE - 30;

Or use:

EXEC DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL;

------------------------------------------------------------
13. Real-Time Security Scenarios
------------------------------------------------------------

Scenario 1:
Multiple failed logins detected.
→ Check DBA_AUDIT_SESSION.

Scenario 2:
Sensitive table accessed.
→ Check DBA_AUDIT_TRAIL.

Scenario 3:
Unauthorized privilege granted.
→ Audit GRANT statements.

Scenario 4:
Suspicious high salary access.
→ Use FGA.

------------------------------------------------------------
14. Best Practices
------------------------------------------------------------

- Always audit login attempts.
- Audit privilege grants.
- Monitor sensitive tables.
- Use Unified Auditing in modern systems.
- Regularly clean audit logs.
- Store audit logs securely.

------------------------------------------------------------
15. Important Interview Questions
------------------------------------------------------------

- What is auditing?
- Difference between standard and FGA?
- What is unified auditing?
- How to audit login attempts?
- Where are audit records stored?
- How to check failed logins?

------------------------------------------------------------
16. Golden Rule
------------------------------------------------------------

Security is not only preventing attacks,
it is detecting suspicious activity early.

Auditing gives visibility.

------------------------------------------------------------
END OF FILE
------------------------------------------------------------
