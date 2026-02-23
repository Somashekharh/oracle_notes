# =============================================================================
# Oracle DBA Task 4: User Management & Security - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant (CDB + PDB)
# Date: February 2026
# Run as SYSDBA (sys / as sysdba) unless mentioned otherwise
# Assumes Task 1-3 are completed (database running)
# =============================================================================

# 1. ENVIRONMENT SETUP (Run every new session)
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. CHECK CURRENT USERS & CONTAINERS
sqlplus / as sysdba << EOF
SHOW PDBS;
SELECT username, account_status, common, oracle_maintained 
FROM dba_users 
ORDER BY common DESC, username;
EXIT;
EOF

# 3. CREATE COMMON USER (CDB level - visible in all PDBs)
sqlplus / as sysdba << EOF
-- Common user must start with C##
CREATE USER c##dba_admin IDENTIFIED BY StrongPass123# CONTAINER=ALL;
GRANT DBA TO c##dba_admin CONTAINER=ALL;
GRANT CONNECT, RESOURCE TO c##dba_admin CONTAINER=ALL;
EXIT;
EOF

# 4. CREATE LOCAL USER (Inside a specific PDB)
sqlplus / as sysdba << EOF
ALTER SESSION SET CONTAINER=ORCLPDB1;   -- Change to your PDB name

CREATE USER app_user IDENTIFIED BY AppPass123# CONTAINER=CURRENT;
GRANT CONNECT, RESOURCE TO app_user;
GRANT CREATE TABLE, CREATE PROCEDURE TO app_user;
GRANT SELECT ANY TABLE TO app_user;     -- Be careful with ANY privileges
EXIT;
EOF

# 5. ALTER / DROP USER
sqlplus / as sysdba << EOF
-- Alter user (change password, unlock, etc.)
ALTER USER app_user IDENTIFIED BY NewStrongPass456# ACCOUNT UNLOCK CONTAINER=CURRENT;

-- Expire password (force change on next login)
ALTER USER app_user PASSWORD EXPIRE;

-- Drop user (with cascade to remove objects)
DROP USER app_user CASCADE CONTAINER=CURRENT;
EXIT;
EOF

# 6. MANAGE ROLES
sqlplus / as sysdba << EOF
-- Create custom role
CREATE ROLE app_role CONTAINER=CURRENT;

-- Grant privileges to role
GRANT SELECT ANY TABLE, INSERT ANY TABLE TO app_role;

-- Grant role to user
GRANT app_role TO app_user;

-- Grant common role to common user
GRANT DBA TO c##dba_admin CONTAINER=ALL;

-- Revoke
REVOKE app_role FROM app_user;
EXIT;
EOF

# 7. PROFILES & PASSWORD POLICIES
sqlplus / as sysdba << EOF
-- Create custom profile
CREATE PROFILE secure_profile LIMIT
  PASSWORD_LIFE_TIME 90
  PASSWORD_REUSE_TIME 365
  PASSWORD_REUSE_MAX 10
  FAILED_LOGIN_ATTEMPTS 5
  PASSWORD_LOCK_TIME 1
  PASSWORD_GRACE_TIME 7
  SESSIONS_PER_USER UNLIMITED
  CPU_PER_SESSION UNLIMITED;

-- Assign profile to user
ALTER USER app_user PROFILE secure_profile CONTAINER=CURRENT;

-- Set as default profile
ALTER PROFILE secure_profile LIMIT PASSWORD_LIFE_TIME 60;
EXIT;
EOF

# 8. PASSWORD FILE MANAGEMENT (orapwd)
# Create/refresh password file for remote SYSDBA
orapwd FILE='$ORACLE_HOME/dbs/orapwORCL' ENTRIES=100 FORCE=Y

# Verify
ls -l $ORACLE_HOME/dbs/orapw*

# 9. ENABLE UNIFIED AUDITING (23ai default)
sqlplus / as sysdba << EOF
-- Check current auditing
SELECT name, value FROM v\$parameter WHERE name LIKE '%audit%';

-- Enable full auditing (if not already)
AUDIT ALL BY ACCESS;
AUDIT SELECT TABLE;
EXIT;
EOF

# View audit records
sqlplus / as sysdba << EOF
SELECT dbusername, action_name, object_name, event_timestamp 
FROM unified_audit_trail 
ORDER BY event_timestamp DESC 
FETCH FIRST 20 ROWS ONLY;
EXIT;
EOF

# 10. TRANSPARENT DATA ENCRYPTION (TDE) - Column / Tablespace
sqlplus / as sysdba << EOF
-- Create keystore (wallet)
ADMINISTER KEY MANAGEMENT CREATE KEYSTORE '/u01/app/oracle/admin/ORCL/wallet' IDENTIFIED BY WalletPass123#;

-- Open keystore
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY WalletPass123#;

-- Create master encryption key
ADMINISTER KEY MANAGEMENT CREATE ENCRYPTION KEY IDENTIFIED BY WalletPass123# WITH BACKUP;

-- Encrypt a column
ALTER TABLE app_user.employees MODIFY (salary ENCRYPT);

-- Encrypt entire tablespace (online)
ALTER TABLESPACE USERS ENCRYPTION ONLINE USING 'AES256' ENCRYPT;
EXIT;
EOF

# 11. BASIC VIRTUAL PRIVATE DATABASE (VPD) - Row Level Security
sqlplus / as sysdba << EOF
ALTER SESSION SET CONTAINER=ORCLPDB1;

-- Create policy function
CREATE OR REPLACE FUNCTION dept_policy (p_schema VARCHAR2, p_object VARCHAR2)
RETURN VARCHAR2 IS
BEGIN
  RETURN 'dept_id = SYS_CONTEXT(''USERENV'', ''SESSION_USER'')';  -- Example
END;
/

-- Apply policy
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'APP_USER',
    object_name     => 'EMPLOYEES',
    policy_name     => 'DEPT_POLICY',
    policy_function => 'DEPT_POLICY',
    statement_types => 'SELECT,INSERT,UPDATE,DELETE'
  );
END;
/
EXIT;
EOF

# 12. SECURITY VERIFICATION COMMANDS
sqlplus / as sysdba << EOF
-- Privileges granted to user
SELECT * FROM dba_sys_privs WHERE grantee = 'APP_USER';
SELECT * FROM dba_role_privs WHERE grantee = 'APP_USER';

-- Audit settings
SELECT * FROM dba_stmt_audit_opts;
SELECT * FROM dba_priv_audit_opts;

-- Check locked accounts
SELECT username, account_status FROM dba_users WHERE account_status LIKE '%LOCK%';
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task4_user_management_security_commands.txt
# Replace ORCL, ORCLPDB1, StrongPass123# with your actual values
# Always use strong, unique passwords
# For production: Enable Oracle Database Vault + Advanced Security
# Test all changes in non-production first!
# =============================================================================