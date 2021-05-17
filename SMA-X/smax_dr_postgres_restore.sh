################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
DATE=`date +%d%m%y%H%M%S`
PG_BIN_DIR='/usr/bin'
#DB_BACKUP_DIR='/opt/sma/dr_backup/db_backup'
DB_BACKUP_DIR='/tmp/smax-app-backup/db_backup'
DB_PASS_FILE='/root/.pgpass'


## Database Host for psql connection - RESTORE TO
#DB_TGT_HOST=$(hostname -f) # On-Prem (localhost) postgreSQL instance
#DB_TGT_HOST='smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com' # AWS RDS
DB_TGT_HOST='10.198.0.5' # SLB GKE
DB_TGT_PORT=5432

## Database Admin user to perform the psql and pg_dump operations
DBA='postgres' # For On-Prem postgreSQL instance
#DBA='dbadmin' # For AWS RDS
DBA_PW='K7#YND5Btxqs22$Z'


## FUNCTIONS ##
log() {
  if [ -n "$LOGFILE" ]; then
    printf '%s\n' "$@" >> "$LOGFILE"
  else
    printf '%s\n' "$@"
  fi
}

echo "$DB_TGT_HOST:$DB_TGT_PORT:*:$DBA:$DBA_PW" | sudo tee -a $DB_PASS_FILE

## Make sure you have rights to the databases
#psql -U $DBA -d maas_admin -h $DB_TGT_HOST
#
#GRANT maas_admin TO $DBA;
#ALTER DATABASE maas_template WITH CONNECTION LIMIT -1;

START_TIME=$(date +%Y%m%d_%H%M%S)

sudo cat $DB_BACKUP_DIR/autopassdb.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d autopassdb
sudo cat $DB_BACKUP_DIR/bo_ats.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d bo_ats
sudo cat $DB_BACKUP_DIR/bo_config.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d bo_config
sudo cat $DB_BACKUP_DIR/bo_license.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d bo_license
sudo cat $DB_BACKUP_DIR/bo_user.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d bo_user
sudo cat $DB_BACKUP_DIR/idm.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d idm
sudo cat $DB_BACKUP_DIR/maas_admin.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d maas_admin
sudo cat $DB_BACKUP_DIR/maas_template.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d maas_template
sudo cat $DB_BACKUP_DIR/smartadb.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d smartadb
sudo cat $DB_BACKUP_DIR/sxdb.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d sxdb
sudo cat $DB_BACKUP_DIR/xservices_ems.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d xservices_ems
sudo cat $DB_BACKUP_DIR/xservices_mng.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d xservices_mng
sudo cat $DB_BACKUP_DIR/xservices_rms.sql.gz | gunzip | sudo psql -h $DB_TGT_HOST -U postgres -d xservices_rms

END_TIME=$(date +%Y%m%d_%H%M%S)

echo "Database Restore Complete! $START_TIME - $END_TIME"



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



#!/bin/bash
#
# SCRIPT_NAME : smax_dr_postgres_backup.sh
# AUTHORS:
#    jitendra@greenlightgroup.com
#    chris@greenlightgroup.com

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################

## Location of the backup logfile.
LOGFILE="$DB_BACKUP_DIR/log_$DATE"



#touch $LOGFILE

TIMESLOT=$(date +%Y%m%d_%H%M%S)
DATABASES=`$PG_BIN_DIR/psql -U $DBA -h $DB_SRC_HOST -d maas_admin -q -c "\l" | awk '{ print $1}' | grep -vE '^\||^-|^List|^Name|template[0|1]|postgres|rdsadmin|^\('`

echo "$DB_SRC_HOST:$DB_SRC_PORT:*:$DBA:$DBA_PW" | sudo tee -a $DB_PASS_FILE
for i in $DATABASES; do
    timeinfo=`date '+%T %x'`
    log "Backup started at $timeinfo for time slot $TIMESLOT on database: $i "

    $PG_BIN_DIR/pg_dump -c $i -U $DBA -h $DB_SRC_HOST | gzip > "$DB_BACKUP_DIR/openerp-$i-$TIMESLOT-database.gz"
    
    RC=$?
    timeinfo=`date '+%T %x'`

    if [ $RC = 0 ]; then
        log "Backup completed successfully at $timeinfo for time slot $TIMESLOT on database: $i"
    else
        log "Backup Failed at $timeinfo for time slot $TIMESLOT on database: $i"
    fi
done
