# =============================================================================
# Oracle DBA Task 15: Compliance, Auditing & Documentation - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as SYSDBA
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. UNIFIED AUDITING (23ai Default - Recommended)
sqlplus / as sysdba << EOF
-- Enable full unified auditing
ALTER SYSTEM SET audit_trail=DB, EXTENDED SCOPE=SPFILE;

-- Audit all actions
AUDIT ALL BY ACCESS;

-- Audit specific actions
AUDIT SELECT TABLE, INSERT TABLE, UPDATE TABLE, DELETE TABLE BY ACCESS;
AUDIT EXECUTE PROCEDURE BY ACCESS;

-- View audit records (fastest query)
SELECT dbusername, action_name, object_name, sql_text, event_timestamp
FROM unified_audit_trail
WHERE event_timestamp > SYSDATE-7
ORDER BY event_timestamp DESC
FETCH FIRST 50 ROWS ONLY;
EXIT;
EOF

# 3. FINE-GRAINED AUDITING (FGA)
sqlplus / as sysdba << EOF
BEGIN
  DBMS_FGA.ADD_POLICY(
    object_schema   => 'APP_USER',
    object_name     => 'EMPLOYEES',
    policy_name     => 'SALARY_AUDIT',
    audit_condition => 'SALARY > 50000',
    audit_column    => 'SALARY',
    statement_types => 'SELECT,UPDATE');
END;
/
EXIT;
EOF

# 4. ORACLE DATABASE VAULT (Advanced Security - Prevent Insider Threats)
# After installing DV
sqlplus / as sysdba << EOF
EXEC DBMS_MACADM.CREATE_REALM('PROD_REALM', 'Protect production data', 'YES');
EXEC DBMS_MACADM.ADD_AUTH_TO_REALM('PROD_REALM', 'C##SEC_ADMIN', 1, 1);
EXIT;
EOF

# 5. COMPLIANCE CHECKS (SOX/GDPR/HIPAA Ready)
sqlplus / as sysdba << EOF
-- Privileged users with DBA role
SELECT grantee FROM dba_role_privs WHERE granted_role = 'DBA';

-- Users with direct system privileges
SELECT grantee, privilege FROM dba_sys_privs WHERE grantee NOT IN ('SYS','SYSTEM');

-- Password policy compliance
SELECT username, profile, account_status, expiry_date
FROM dba_users
WHERE expiry_date < SYSDATE + 30;
EXIT;
EOF

# 6. AUDIT TRAIL CLEANUP (Retention Policy)
sqlplus / as sysdba << EOF
BEGIN
  DBMS_AUDIT_MGMT.SET_LAST_ARCHIVE_TIMESTAMP(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    last_archive_ts  => SYSDATE-90);
  
  DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    use_last_arch_timestamp => TRUE);
END;
/
EXIT;
EOF

# 7. DOCUMENTATION TEMPLATES (Create these files)
cat > /u01/docs/DB_Runbook_ORCL.md << 'EOF'
# Oracle Database Runbook - ORCL
Database Name: ORCL
Version: 23ai
CDB: Yes | PDBs: SALES_PDB, HR_PDB
Last Patch: Feb 2026 RU
DR: Data Guard (Physical Standby)
Contact: DBA Team
EOF

# Daily Checklist Template
cat > /u01/docs/Daily_DBA_Checklist.txt << 'EOF'
[ ] Alert log errors
[ ] Tablespace >85%
[ ] Blocking sessions
[ ] RMAN backup success
[ ] OEM alerts
[ ] Listener status
EOF

# 8. EXPORT AUDIT REPORT
sqlplus / as sysdba << EOF
SET PAGES 999 LINES 200
SPOOL /u01/docs/audit_report_$(date +%Y%m%d).html
SELECT * FROM unified_audit_trail WHERE event_timestamp > SYSDATE-30;
SPOOL OFF
EXIT;
EOF

# =============================================================================
# END OF FILE
# After saving: chmod +x oracle_dba_task15_compliance_auditing_documentation_commands.txt
# Create folder: mkdir -p /u01/docs
# For full compliance use Oracle Database Vault + Label Security + TDE
# Store all docs in Git or shared drive
# =============================================================================