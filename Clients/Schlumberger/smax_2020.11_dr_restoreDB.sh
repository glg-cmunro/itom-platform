#!/bin/bash
################################################################################
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery / Data Load for SMA-X Suite on ITOM Platform
#
# Pre-requisite: PGPASS file must exist for the user executing this script
#   echo "$DB_TGT_HOST:$DB_TGT_PORT:*:$DBA:$DBA_PW" | tee -a $DB_PASS_FILE
################################################################################


################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
DATE=`date +%d%m%y%H%M%S`
PG_BIN_DIR="/usr/bin"
DB_BACKUP_DIR="/data/dr/db"
DB_PASS_FILE="~/.pgpass"
TGT_DB_PORT=5432

## Database Host for psql connection - RESTORE TO
#TGT_DB_HOST=$(hostname -f) # On-Prem (localhost) postgreSQL instance

##GITOpS - smax-west
#DBA="dbadmin"
#TGT_DB_HOST="smax-west-rds.gitops.com"

##SLB GKE Prod
#DBA="postgres"
#TGT_DB_HOST="10.241.160.2"

##SLB GKE NP
DBA="postgres"
TGT_DB_HOST="10.198.0.2"

## Location of the backup logfile.
LOGFILE="$DB_BACKUP_DIR/log_$DATE"

## FUNCTIONS ##
log() {
  if [ -n "$LOGFILE" ]; then
    printf "%s\n" "$@" >> "$LOGFILE"
  else
    printf "%s\n" "$@"
  fi
}


## Make sure you have rights to the databases
## Grant the rights if you need to
#$PG_BIN_DIR/psql -U $DBA -d maas_admin -h $TGT_DB_HOST -c "GRANT maas_admin TO $DBA;"
#$PG_BIN_DIR/psql -U $DBA -d maas_admin -h $TGT_DB_HOST -c "ALTER DATABASE maas_template WITH CONNECTION LIMIT -1;"

START_TIME=$(date +%Y%m%d_%H%M%S)

DBs=$(ls $DB_BACKUP_DIR)

for db in $DBs
do
  DB_FILE=$db
  DB_NAME=$(echo $db | awk -F '.' '{print $2}' | awk -F '-' '{print $1}')

  echo "cat $DB_FILE | gunzip | $PG_BIN_DIR/psql -U $DBA -d $DB_NAME -h $TGT_DB_HOST"
done

END_TIME=$(date +%Y%m%d_%H%M%S)

echo "Database Restore Complete! $START_TIME - $END_TIME"









"""
################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
USE_SUDO=0

PG_VERSION='10.17'
DB_RESTORE_DIR='/data/dr/db'
DB_ADMIN_USER='postgres'

DR_BIN_DIR='/opt/smax/2020.11/tools'
DR_TMP_DIR='/data/dr/tmp'
DR_OUTPUT_DIR='/data/dr/output'

##GLG optic-dev
#TGT_DB_HOST='fs-339aec87.efs.us-east-1.amazonaws.com'

##SLB GKE Prod
#TGT_DB_HOST='10.241.160.2'

##SLB GKE Non-Prod
TGT_DB_HOST='10.198.0.2'

SUDO_='';
if [$USE_SUDO == 1]; then
    SUDO_='sudo ';
fi

#CDFCTL='/opt/kubernetes/scripts/cdfctl.sh'
#ForBYOK
CDFCTL='$DR_BIN_DIR/../scripts/cdfctl.sh'
################################################################################
#####                        TARGET SERVER  RESTORE                        #####
################################################################################

##Database Restore from GZipped Backup
##On the Database Host:
function restore_db() {
    PG_RESTORE=/usr/bin/pg_restore

    declare -A suiteDBs
    #suiteDBs[autopassdb]=autopass
    #suiteDBs[bo_ats]=bo_db_user
    #suiteDBs[bo_config]=bo_db_user
    #suiteDBs[bo_license]=bo_db_user
    #suiteDBs[bo_user]=bo_db_user
    #suiteDBs[idm]=idm
    #suiteDBs[maas_admin]=maas_admin
    #suiteDBs[maas_template]=maas_admin
    #suiteDBs[xservices_ems]=maas_admin
    #suiteDBs[xservices_mng]=maas_admin
    #suiteDBs[xservices_rms]=maas_admin
    #suiteDBs[smartadb]=smarta
    #suiteDBs[sxdb]=dbadmin
    
    ##If schemas all owned by postgres use this instead
    suiteDBs[autopassdb]=postgres
    suiteDBs[bo_ats]=postgres
    suiteDBs[bo_config]=postgres
    suiteDBs[bo_license]=postgres
    suiteDBs[bo_user]=postgres
    suiteDBs[idm]=postgres
    suiteDBs[maas_admin]=postgres
    suiteDBs[maas_template]=postgres
    suiteDBs[xservices_ems]=postgres
    suiteDBs[xservices_mng]=postgres
    suiteDBs[xservices_rms]=postgres
    suiteDBs[smartadb]=postgres
    #suiteDBs[sxdb]=postgres

    ##Create .pgpass file to hold db login
    #echo '#$DB_PASS_FILE' | $SUDO_ tee $DB_PASS_FILE
    #for db in '${!suiteDBs[@]}'
    #do
    #    DB_NAME=$db
    #    IFS=';' read -ra dbARR <<< ${suiteDBs[$db]}
    #    DB_USER=${dbARR[0]}
    #    DB_PASS=${dbARR[1]}
    # 
    #    echo '$TGT_DB_HOST:5432:$DB_NAME:$DB_USER:$DB_PASS' | $SUDO_ tee -a $DB_PASS_FILE
    #done
    #$SUDO_ chmod 600 $DB_PASS_FILE

    ## Create DB Users and blank Databases if needed
    #echo '$TGT_DB_HOST:5432:postgres:postgres:Gr33nl1ght_' | $SUDO_ tee -a $DB_PASS_FILE
    #echo $SUDO_ $PG_BIN_DIR/psql -U postgres -h $TGT_DB_HOST
    #for db in '${!suiteDBs[@]}'
    #do
    #    DB_NAME=$db
    #    IFS=';' read -ra dbARR <<< ${suiteDBs[$db]}
    #    DB_USER=${dbARR[0]}
    #    DB_PASS=${dbARR[1]}
    #
    #    echo 'CREATE DATABASE $DB_NAME;'
    #    echo 'CREATE USER $DB_USER with password $DB_PASS;'
    #    echo 'GRANT ALL PRIVILEGES ON $DB_NAME TO $DB_USER;'
    #done
    #echo '\q'

    START_TIME=$(date +%Y%m%d_%H%M%S)
    DR_DATE=$(date +%Y%m%d_%H%M%S)
    for db in '${!suiteDBs[@]}'
    do
        DB_NAME=$db
        IFS=';' read -ra dbARR <<< ${suiteDBs[$db]}
        DB_USER=$DB_ADMIN_USER
        #DB_USER=${dbARR[0]}
        #DB_PASS=${dbARR[1]}
        #DB_FILENAME=$DB_BACKUP_DIR/$DR_DATE.$DB_NAME-$DB_USER.dmp
        DB_FILENAME=`ls $DB_RESTORE_DIR/*.$DB_NAME-$DB_USER.dmp`

        sudo $PG_RESTORE -Fc -c -d $DB_NAME -U $DB_USER -h $TGT_DB_HOST -v < $DB_FILENAME
        #sudo $PG_RESTORE -Fc -c -d xservices_rms -U maas_admin -h $TGT_DB_HOST < 20200824_213626.xservices_rms-maas_admin.dmp
    done
    COMPLETE_TIME=$(date +%Y%m%d_%H%M%S)
    echo 'Completed RESTORE: $START_TIME - $COMPLETE_TIME'
    
}

restore_db $DB_RESTORE_DIR
"""

### Create DB Users if needed (Blank Database Instance)
"""
CREATE USER autopass login PASSWORD 'Gr33nl1ght_'; 
CREATE USER bo_db_user login PASSWORD 'Gr33nl1ght_'; 
CREATE USER idm login PASSWORD 'Gr33nl1ght_'; 
CREATE USER maas_admin login PASSWORD 'Gr33nl1ght_'; 
CREATE USER smarta login PASSWORD 'Gr33nl1ght_'; 

CREATE DATABASE autopassdb WITH owner=autopass;
CREATE DATABASE bo_ats WITH owner=bo_db_user;
CREATE DATABASE bo_config WITH owner=bo_db_user;
CREATE DATABASE bo_license WITH owner=bo_db_user;
CREATE DATABASE bo_user WITH owner=bo_db_user;
CREATE DATABASE idm WITH owner=idm;
CREATE DATABASE maas_admin WITH owner=maas_admin;
CREATE DATABASE maas_template WITH owner=maas_admin;
CREATE DATABASE xservices_ems WITH owner=maas_admin;
CREATE DATABASE xservices_mng WITH owner=maas_admin;
CREATE DATABASE xservices_rms WITH owner=maas_admin;
CREATE DATABASE smartadb WITH owner=smarta;

GRANT ALL ON DATABASE autopassdb to autopass;
"""