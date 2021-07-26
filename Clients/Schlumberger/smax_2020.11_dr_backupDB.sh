#!/bin/bash
################################################################################
# SCRIPT_NAME : smax_2020.11_dr_backupDB.sh
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery for SMA-X Suite on ITOM Platform for Schlumberger
#
# Pre-requisite:  PGPASS must exist for user execting this script
#   echo "$SRC_DB_HOST:5432:*:$DBA:$DBA_PW" | tee $DB_PASS_FILE
#   chmod 0600 ~/.pgpass
################################################################################


################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
DATE=`date +%d%m%y%H%M%S`
PG_BIN_DIR='/usr/bin'
DB_PASS_FILE='~/.pgpass'
#DB_BACKUP_DIR='/opt/sma/dr_backup/db_backup'
DB_BACKUP_DIR='/data/dr/db'

SRC_DB_PORT=5432
#SRC_DB_HOST=$(kubectl get cm -n core default-database-configmap -o yaml | grep ...)

##GITOpS - smax-west
#DBA='dbadmin' # For AWS RDS
#SRC_DB_HOST='smax-west-rds.gitops.com' # AWS RDS

##SLB GKE Prod
DBA="postgres"
SRC_DB_HOST="10.241.160.2"

##SLB GKE NP
#DBA='postgres' # For On-Prem postgreSQL instance
#SRC_DB_HOST='10.198.0.2'

## Database Host for psql connection
#SRC_DB_HOST=$(hostname -f) # On-Prem (localhost) postgreSQL instance

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

mkdir -p $DB_BACKUP_DIR

##GRANT Rights to DBA if necessary
$PG_BIN_DIR/psql -U $DBA -h $SRC_DB_HOST -d maas_admin -q -c "GRANT maas_admin TO $DBA;"
$PG_BIN_DIR/psql -U $DBA -h $SRC_DB_HOST -d maas_admin -q -c "ALTER DATABASE maas_template WITH CONNECTION LIMIT -1;"

TIMESLOT=$(date +%Y%m%d_%H%M%S)
DATABASES=`$PG_BIN_DIR/psql -U $DBA -h $SRC_DB_HOST -d maas_admin -q -c "\l" | awk '{ print $1}' | grep -vE '^\||^-|^List|^Name|template[0|1]|postgres|rdsadmin|cloudsqladmin|default|^\('`

#echo "$SRC_DB_HOST:$SRC_DB_PORT:*:$DBA:$DBA_PW" | sudo tee -a $DB_PASS_FILE
for i in $DATABASES; do
    timeinfo=`date '+%T %x'`
    log "Backup started at $timeinfo for time slot $TIMESLOT on database: $i "

    $PG_BIN_DIR/pg_dump -c $i -U $DBA -h $SRC_DB_HOST | gzip > "$DB_BACKUP_DIR/$TIMESLOT.$i-database.gz"
    
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
