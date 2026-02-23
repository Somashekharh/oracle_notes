# =============================================================================
# Oracle DBA Task 1: Installation, Configuration & Deployment - All Commands
# Oracle Database 23ai (Enterprise Edition) on Oracle Linux 8/9 (x86_64)
# Date: February 2026
# Tested on Oracle Linux 8.10 / 9.5 with latest 23ai RU
# Run as root unless mentioned otherwise
# =============================================================================

# 1. PRE-INSTALLATION CHECKS & PREPARATION (as root)
hostname
cat /etc/os-release
uname -r
df -h
free -g
df -h /tmp

# Install Oracle Preinstallation RPM (automatically creates oracle user, groups, kernel params)
dnf install -y oracle-database-preinstall-23ai

# Verify what was set
cat /etc/sysconfig/oracle-database-preinstall-23ai/results/orakernel.log | tail -50

# Create required directories (as root)
mkdir -p /u01/app/oracle/product/23.0.0/dbhome_1
mkdir -p /u01/app/oraInventory
mkdir -p /u01/app/oracle/admin
chown -R oracle:oinstall /u01
chmod -R 775 /u01

# Switch to oracle user for all further steps
su - oracle

# 2. ENVIRONMENT SETUP (as oracle user)
cat >> ~/.bash_profile << 'EOF'
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/23.0.0/dbhome_1
export ORACLE_SID=ORCL
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
EOF

source ~/.bash_profile

# 3. DOWNLOAD & STAGE SOFTWARE (as oracle)
# Download from https://edelivery.oracle.com (Oracle account required)
# Example filenames (replace with your actual downloaded files):
cd /u01/app/oracle
mkdir -p /u01/stage/23ai
cd /u01/stage/23ai
# Unzip both parts if downloaded as zip
unzip V*.zip
# You will see "Disk1" folder after unzip

# 4. CREATE RESPONSE FILE FOR SILENT INSTALL (as oracle)
cat > /u01/stage/23ai/db_install.rsp << 'EOF'
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v23.0.0
oracle.install.option=INSTALL_DB_SWONLY
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=/u01/app/oraInventory
ORACLE_HOME=/u01/app/oracle/product/23.0.0/dbhome_1
ORACLE_BASE=/u01/app/oracle
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=oper
oracle.install.db.OSBACKUPDBA_GROUP=backupdba
oracle.install.db.OSDGDBA_GROUP=dgdba
oracle.install.db.OSKMDBA_GROUP=kmdba
oracle.install.db.OSRACDBA_GROUP=racdba
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
oracle.install.db.config.starterdb.globalDBName=ORCL
oracle.install.db.config.starterdb.SID=ORCL
oracle.install.db.config.starterdb.characterSet=AL32UTF8
oracle.install.db.config.starterdb.memoryOption=true
oracle.install.db.config.starterdb.memoryLimit=2048
oracle.install.db.config.starterdb.installExampleSchemas=false
oracle.install.db.config.starterdb.password.ALL=YourStrongPassword123#
DECLINE_SECURITY_UPDATES=true
EOF

# 5. SILENT SOFTWARE INSTALLATION (as oracle)
cd /u01/stage/23ai/Disk1
./runInstaller -silent -responseFile /u01/stage/23ai/db_install.rsp -ignorePrereq

# After installer finishes, run root scripts (as root in new terminal)
su - root
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/23.0.0/dbhome_1/root.sh
exit

# 6. LISTENER CONFIGURATION (as oracle)
netca -silent -responseFile << EOF
[General]
ResponseFileVersion=23.0.0
[oracle.net.ca]
INSTALLED_COMPONENTS={"server","net8","javavm"}
INSTALL_TYPE=typical
LISTENER_NUMBER=1
LISTENER_NAME=LISTENER
LISTENER_PROTOCOL=TCP
LISTENER_PORT=1521
LISTENER_START=yes
EOF

# 7. CREATE DATABASE SILENTLY USING DBCA (as oracle) - Multitenant CDB+PDB
dbca -silent -createDatabase \
  -templateName General_Purpose.dbc \
  -gdbName ORCL \
  -sid ORCL \
  -responseFile NO_VALUE \
  -characterSet AL32UTF8 \
  -createAsContainerDatabase true \
  -numberOfPDBs 1 \
  -pdbName ORCLPDB1 \
  -sysPassword YourStrongPassword123# \
  -systemPassword YourStrongPassword123# \
  -pdbAdminPassword YourStrongPassword123# \
  -emConfiguration NONE \
  -storageType FS \
  -datafileDestination /u01/app/oracle/oradata \
  -redoLogFileSize 50 \
  -totalMemory 2048 \
  -ignorePrereq

# 8. POST-INSTALLATION CONFIGURATION (as oracle)
# Set environment
. /u01/app/oracle/product/23.0.0/dbhome_1/bin/oraenv <<< ORCL

# Start listener & database
lsnrctl start
sqlplus / as sysdba << EOF
startup
exit
EOF

# Create spfile from pfile (if needed)
sqlplus / as sysdba << EOF
CREATE SPFILE FROM PFILE;
exit
EOF

# Enable ARCHIVELOG (recommended)
sqlplus / as sysdba << EOF
shutdown immediate
startup mount
alter database archivelog;
alter database open;
exit
EOF

# 9. COMMON POST-DEPLOYMENT COMMANDS
# Check status
lsnrctl status
sqlplus / as sysdba << EOF
select name, open_mode, database_role from v\$database;
select instance_name, status from v\$instance;
show pdbs;
EOF

# Create common user (CDB level)
sqlplus / as sysdba << EOF
CREATE USER c##admin IDENTIFIED BY StrongPass123# CONTAINER=ALL;
GRANT DBA TO c##admin CONTAINER=ALL;
EOF

# 10. OPTIONAL: ASM Configuration (if using ASM)
# Install Grid Infrastructure separately first, then use asmca

# 11. OPTIONAL: Silent DBCA for additional PDB
dbca -silent -createPluggableDatabase \
  -pdbName NEWPDB \
  -pdbAdminPassword YourStrongPassword123# \
  -createPDBFrom DEFAULT \
  -pdbDatafileDestination /u01/app/oracle/oradata/ORCL/NEWPDB

# =============================================================================
# END OF FILE
# After saving, make executable if needed: chmod +x oracle_dba_task1_install_config_deployment_commands.txt
# Run sections one by one. Replace "YourStrongPassword123#" with your secure password.
# For Oracle Database Free RPM version (simpler), use:
#   dnf install -y oracle-database-preinstall-23ai
#   dnf -y install oracle-database-free-23ai-*.rpm
#   /etc/init.d/oracle-free-23ai configure
# =============================================================================