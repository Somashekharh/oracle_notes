# =============================================================================
# Oracle DBA Task 9: Patching, Upgrades & Maintenance - All Commands
# Oracle Database 23ai (Enterprise Edition) - Multitenant
# Date: February 2026
# Run as oracle user (opatch, AutoUpgrade) or SYSDBA (SQL)
# Assumes Task 1-8 are completed (database running)
# =============================================================================

# 1. ENVIRONMENT SETUP
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# 2. CHECK CURRENT PATCH LEVEL (Always run first)
opatch lsinventory | tail -50
opatch lspatches

# Check RU / PSU level from database
sqlplus / as sysdba << EOF
SELECT * FROM dba_registry_history ORDER BY action_time DESC;
SELECT banner FROM v\$version WHERE banner LIKE '%Update%';
EXIT;
EOF

# 3. DOWNLOAD & STAGE PATCHES
# Download from My Oracle Support (MOS):
# - Latest RU (Release Update) for 23ai
# - One-off patches if needed
# Example: p12345678_230000_Linux-x86-64.zip

mkdir -p /u01/stage/patches/23ai_RU
cd /u01/stage/patches/23ai_RU
unzip p*.zip

# 4. APPLY PATCH USING OPATCH (Single Instance - Rolling in RAC)
# Stop database (in RAC use srvctl stop database -rolling)
sqlplus / as sysdba << EOF
SHUTDOWN IMMEDIATE;
EXIT;
EOF

# Apply patch (from patch directory)
cd /u01/stage/patches/23ai_RU/12345678
opatch apply -silent

# Post-patch steps
sqlplus / as sysdba << EOF
STARTUP;
@?/rdbms/admin/catbundle.sql  -- Only if Bundle Patch
@?/rdbms/admin/utlrp.sql      -- Recompile invalid objects
EXIT;
EOF

# Verify
opatch lsinventory
sqlplus / as sysdba << EOF
SELECT * FROM dba_registry_history ORDER BY action_time DESC;
EXIT;
EOF

# 5. ROLLBACK PATCH (if needed)
opatch rollback -id 12345678 -silent

# 6. UPGRADE DATABASE USING AUTOUPGRADE (19c/21c → 23ai) - Recommended
# Download latest AutoUpgrade.jar from MOS

mkdir -p /u01/upgrade/logs
cat > /u01/upgrade/autoupgrade.cfg << EOF
global.autoupgrade_log_dir=/u01/upgrade/logs
upg1.source_home=/u01/app/oracle/product/19.0.0/dbhome_1
upg1.target_home=/u01/app/oracle/product/23.0.0/dbhome_1
upg1.sid=ORCL19
upg1.target_sid=ORCL23
upg1.upgrade_mode=auto
upg1.action=analyze,upgrade,postupgrade
upg1.log_dir=/u01/upgrade/logs/ORCL19
EOF

# Analyze first
java -jar /u01/stage/autoupgrade_23.0.0.jar -config /u01/upgrade/autoupgrade.cfg -mode analyze

# Run upgrade
java -jar /u01/stage/autoupgrade_23.0.0.jar -config /u01/upgrade/autoupgrade.cfg -mode deploy

# Post-upgrade (AutoUpgrade does most automatically)
sqlplus / as sysdba << EOF
@?/rdbms/admin/utlrp.sql
EXIT;
EOF

# 7. QUARTERLY MAINTENANCE WINDOW TASKS
# 1. Apply latest RU (every 3 months)
# 2. Gather fixed object stats
sqlplus / as sysdba << EOF
EXEC DBMS_STATS.GATHER_FIXED_OBJECTS_STATS;
EXEC DBMS_STATS.GATHER_DICTIONARY_STATS;
EXIT;
EOF

# 3. Check invalid objects
@?/rdbms/admin/utlrp.sql

# 4. Clean audit trail / recyclebin
sqlplus / as sysdba << EOF
PURGE DBA_RECYCLEBIN;
BEGIN
  DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(
    audit_trail_type => DBMS_AUDIT_MGMT.AUDIT_TRAIL_UNIFIED,
    use_last_arch_timestamp => TRUE);
END;
/
EXIT;
EOF

# 8. OPATCH AUTO (Zero Downtime Patching - 19c+)
opatchauto apply /u01/stage/patches/23ai_RU/12345678 -oh /u01/app/oracle/product/23.0.0/dbhome_1

# 9. INVENTORY & HOME MANAGEMENT
opatch lsinventory -detail > /u01/backup/patch_inventory_$(date +%Y%m%d).txt
opatch lspatches -oh /u01/app/oracle/product/23.0.0/dbhome_1

# List all Oracle Homes
cat /u01/app/oraInventory/ContentsXML/inventory.xml | grep ORACLE_HOME

# 10. CRITICAL PATCH UPDATE (CPU) - Security Only
# Same as RU but only security patches
# Always apply in test first!

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task9_patching_upgrades_maintenance_commands.txt
# Replace ORCL, ORCL19, ORCL23 with your actual SIDs
# Always test patches/upgrades on a cloned environment first!
# Download latest AutoUpgrade.jar and patches from My Oracle Support
# For RAC/Exadata use opatchauto or rolling upgrade
# Run utlrp.sql after every patch/upgrade
# =============================================================================