#!/bin/bash
#
# SCRIPT_NAME : smax_dr_postgres_backup.sh
# AUTHORS:
#    jitendra@greenlightgroup.com
#    chris@greenlightgroup.com

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
DATE=`date +%d%m%y%H%M%S`
PG_BIN_DIR='/usr/bin'
#DB_TGT_HOST='smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com'
DB_PASS_FILE='/root/.pgpass'
#DB_BACKUP_DIR='/opt/sma/dr_backup/db_backup'
DB_BACKUP_DIR='/opt/kubernetes/dr_backup/db_backup'

## Database Admin user to perform the psql and pg_dump operations
#DBA='postgres' # For On-Prem postgreSQL instance
#DBA='rdsadmin' # For AWS RDS
DBA='dbadmin' # For AWS RDS
DBA_PW='Gr33nl1ght_'

## Database Host for psql connection
#DB_SRC_HOST=$(hostname -f) # On-Prem (localhost) postgreSQL instance
DB_SRC_HOST='smaxdev.cz4qew1aonte.us-west-2.rds.amazonaws.com' # AWS RDS
DB_SRC_PORT=5432

## Location of the backup logfile.
LOGFILE="$DB_BACKUP_DIR/log_$DATE"


## FUNCTIONS ##
log() {
  if [ -n "$LOGFILE" ]; then
    printf '%s\n' "$@" >> "$LOGFILE"
  else
    printf '%s\n' "$@"
  fi
}

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

## delete Backup files more than 7 days and log file for more than 30 days old
 #find /opt/postgresql/Backup/FULL* -mtime +7 -exec rm {} \;
 #find /opt/postgresql/Backup/log_* -mtime +30 -exec rm {} \;

#exit
