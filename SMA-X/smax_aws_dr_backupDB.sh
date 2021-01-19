#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery / Data Load for SMA-X Suite on ITOM Platform
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
USE_SUDO=1

#PG_BIN_DIR='/var/lib/docker/overlay2/4ea462b2499ca9d4fff967b4d082342c1678bd748f40723181e3bedfdc1eda5f/diff/usr/lib/postgresql10/bin/'
PG_BIN_DIR='/usr/bin/'
DB_BACKUP_DIR='/var/vols/itom/dr_backup/db'
DB_PASS_FILE='/root/.pgpass'

DR_TMP_DIR='/opt/sma/tmp'
DR_OUTPUT_DIR='/opt/sma/tmp'
DR_NFS_DIR='/opt/sma/nfs'
DR_SMARTA_DIR='/opt/sma/smarta-nfs'

SRC_DB_HOST='smaxdev.cz4qew1aonte.us-west-2.rds.amazonaws.com'
#SRC_MASTER_HOST='10.0.1.145' #For EKS this is the Bastion, or Control Node
#SRC_NFS_HOST='10.192.236.147' #Need to figure out EKS version of this

##Process arguments
#while getopts ":pg_sql:p:" opt; do
#    case $opt in
#        pg_sql) PG_VERSION="$OPTARG"; echo $PG_VERSION
#        ;;
#        p) echo "ARG p=$name"
#        ;;
#        \?) echo "Invalid Option: -$OPTARG"
#        ;;
#    esac
#done

SUDO_='';
if [$USE_SUDO == 1]; then
    SUDO_='sudo ';
fi
PGSUDO_=''
if [$USE_PGSUDO == '1']; then
    PGSUDO_='-U postgres '
fi
#CDFCTL='/opt/kubernetes/scripts/cdfctl.sh'
#ForEKS
#CDFCTL='/install/2020.02/ITOM_Platform_Foundation_BYOK_2020.02.00119/scripts/cdfctl.sh'
################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################

##Database Backups - Not full DUMPALL
##On the Database Host:
function backup_db() {
    DB_BACKUP_DIR=$1
    PG_DUMP=$PG_BIN_DIR/pg_dump

    cd /tmp
    mkdir -p $DB_BACKUP_DIR
    
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
    #suiteDBs[sxdb]='dbadmin;Gr33nl1ght_'

    echo "\#$DB_PASS_FILE" | sudo tee $DB_PASS_FILE
    for db in "${!suiteDBs[@]}"
    do
        DB_NAME=$db
        IFS=';' read -ra dbARR <<< ${suiteDBs[$db]}
        DB_USER=${dbARR[0]}
        DB_PASS=${dbARR[1]}
    
        echo "$SRC_DB_HOST:5432:$DB_NAME:$DB_USER:$DB_PASS" | sudo tee -a $DB_PASS_FILE
    done
    sudo chmod 600 $DB_PASS_FILE

    DR_DATE=$(date +%Y%m%d_%H%M%S)
    for db in "${!suiteDBs[@]}"
    do
        DB_NAME=$db
        IFS=';' read -ra dbARR <<< ${suiteDBs[$db]}
        DB_USER=${dbARR[0]}
        DB_PASS=${dbARR[1]}
        DB_FILENAME=$DB_BACKUP_DIR/$DR_DATE.$DB_NAME-$DB_USER.dmp

        sudo $PG_DUMP -Fc -c --inserts $DB_NAME -U $DB_USER -h $SRC_DB_HOST -w -f $DB_FILENAME

    done
}

backup_db $DB_BACKUP_DIR
