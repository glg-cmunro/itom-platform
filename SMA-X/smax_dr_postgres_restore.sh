################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
DATE=`date +%d%m%y%H%M%S`
PG_BIN_DIR='/usr/bin'
DB_BACKUP_DIR='/opt/sma/dr_backup/db_backup'
DB_PASS_FILE='/root/.pgpass'


## Database Host for psql connection - RESTORE TO
#DB_TGT_HOST=$(hostname -f) # On-Prem (localhost) postgreSQL instance
DB_TGT_HOST='smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com' # AWS RDS
DB_TGT_PORT=5432

## Database Admin user to perform the psql and pg_dump operations
DBA='postgres' # For On-Prem postgreSQL instance
#DBA='dbadmin' # For AWS RDS
DBA_PW='Gr33nl1ght_'


## FUNCTIONS ##
log() {
  if [ -n "$LOGFILE" ]; then
    printf '%s\n' "$@" >> "$LOGFILE"
  else
    printf '%s\n' "$@"
  fi
}

    declare -A suiteDBs
    suiteDBs[autopassdb]='autopass;Gr33nl1ght_'
    suiteDBs[bo_ats]='bo_db_user;Gr33nl1ght_'
    suiteDBs[bo_config]='bo_db_user;Gr33nl1ght_'
    suiteDBs[bo_license]='bo_db_user;Gr33nl1ght_'
    suiteDBs[bo_user]='bo_db_user;Gr33nl1ght_'
    suiteDBs[idm]='idm;Gr33nl1ght_'
    suiteDBs[maas_admin]='maas_admin;Gr33nl1ght_'
    suiteDBs[maas_template]='maas_admin;Gr33nl1ght_'
    suiteDBs[xservices_ems]='maas_admin;Gr33nl1ght_'
    suiteDBs[xservices_mng]='maas_admin;Gr33nl1ght_'
    suiteDBs[xservices_rms]='maas_admin;Gr33nl1ght_'
    suiteDBs[smartadb]='smarta;Gr33nl1ght_'


echo "$DB_TGT_HOST:$DB_TGT_PORT:*:$DBA:$DBA_PW" | sudo tee -a $DB_PASS_FILE

## Make sure you have rights to the databases
psql -U $DBA -d maas_admin -h $DB_TGT_HOST

GRANT maas_admin TO $DBA;
ALTER DATABASE maas_template WITH CONNECTION LIMIT -1;


cat $DB_BACKUP_DIR/openerp-autopassdb-20200929_210446-database.gz | gunzip \
  | $PG_BIN_DIR/psql -U $DBA -d autopassdb -h $DB_TGT_HOST

START_TIME=$(date +%Y%m%d_%H%M%S)

cat /tmp/smax-app-backup/db_backup/autopassdb.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U autopass -d autopassdb
cat /tmp/smax-app-backup/db_backup/bo_ats.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U bo_db_user -d bo_ats
cat /tmp/smax-app-backup/db_backup/bo_config.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U bo_db_user -d bo_config
cat /tmp/smax-app-backup/db_backup/bo_license.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U bo_db_user -d bo_license
cat /tmp/smax-app-backup/db_backup/bo_user.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U bo_db_user -d bo_user
cat /tmp/smax-app-backup/db_backup/idm.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U idm -d idm
cat /tmp/smax-app-backup/db_backup/maas_admin.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U maas_admin -d maas_admin
cat /tmp/smax-app-backup/db_backup/maas_template.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U maas_admin -d maas_template
cat /tmp/smax-app-backup/db_backup/smartadb.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U smarta -d smartadb
cat /tmp/smax-app-backup/db_backup/xservices_ems.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U maas_admin -d xservices_ems
cat /tmp/smax-app-backup/db_backup/xservices_mng.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U maas_admin -d xservices_mng
cat /tmp/smax-app-backup/db_backup/xservices_rms.sql.gz | gunzip | sudo psql -h 10.198.0.5 -U maas_admin -d xservices_rms

END_TIME=$(date +%Y%m%d_%H%M%S)

echo "Database Restore Complete! $START_TIME - $END_TIME"

cat /backup/DailyBackup/openerp-autopassdb-220920102849-database.gz | gunzip | psql -U postgres -d autopassdb
cat /backup/DailyBackup/openerp-bo_ats-220920102849-database.gz | gunzip | psql -U postgres -d bo_ats
cat /backup/DailyBackup/openerp-bo_config-220920102849-database.gz | gunzip | psql -U postgres -d bo_config
cat /backup/DailyBackup/openerp-bo_license-220920102849-database.gz | gunzip | psql -U postgres -d bo_license
cat /backup/DailyBackup/openerp-bo_user-220920102849-database.gz | gunzip | psql -U postgres -d bo_user
cat /backup/DailyBackup/openerp-idm-220920102849-database.gz | gunzip | psql -U postgres -d idm
cat /backup/DailyBackup/openerp-maas_admin-220920102849-database.gz | gunzip | psql -U postgres -d maas_admin
cat /backup/DailyBackup/openerp-maas_template-220920102849-database.gz | gunzip | psql -U postgres -d maas_template
cat /backup/DailyBackup/openerp-smartadb-220920102849-database.gz | gunzip | psql -U postgres -d smartadb
cat /backup/DailyBackup/openerp-xservices_ems-220920102849-database.gz | gunzip | psql -U postgres -d xservices_ems
cat /backup/DailyBackup/openerp-xservices_mng-220920102849-database.gz | gunzip | psql -U postgres -d xservices_mng
cat /backup/DailyBackup/openerp-xservices_rms-220920102849-database.gz | gunzip | psql -U postgres -d xservices_rms




### NOTES:


echo "smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com:5432:*:postgres:Gr33nl1ght_" | tee ~/.pgpass

START_TIME=$(date +%Y%m%d_%H%M%S)
cat /opt/sma/dr_backup/db_backup/openerp-autopassdb-20200929_210446-database.gz | gunzip | psql -U postgres -d autopassdb -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-bo_ats-20200929_210446-database.gz | gunzip | psql -U postgres -d bo_ats -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-bo_config-20200929_210446-database.gz | gunzip | psql -U postgres -d bo_config -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-bo_license-20200929_210446-database.gz | gunzip | psql -U postgres -d bo_license -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-bo_user-20200929_210446-database.gz | gunzip | psql -U postgres -d bo_user -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-idm-20200929_210446-database.gz | gunzip | psql -U postgres -d idm -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-maas_admin-20200929_210446-database.gz | gunzip | psql -U postgres -d maas_admin -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-maas_template-20200929_210446-database.gz | gunzip | psql -U postgres -d maas_template -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-smartadb-20200929_210446-database.gz | gunzip | psql -U postgres -d smartadb -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-sxdb-20200929_210446-database.gz | gunzip | psql -U postgres -d sxdb -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-xservices_ems-20200929_210446-database.gz | gunzip | psql -U postgres -d xservices_ems -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-xservices_mng-20200929_210446-database.gz | gunzip | psql -U postgres -d xservices_mng -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
cat /opt/sma/dr_backup/db_backup/openerp-xservices_rms-20200929_210446-database.gz | gunzip | psql -U postgres -d xservices_rms -h smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com
END_TIME=$(date +%Y%m%d_%H%M%S)

echo "Database Restore Complete! $START_TIME - $END_TIME"

