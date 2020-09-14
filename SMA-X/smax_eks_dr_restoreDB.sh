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

#PG_BIN_DIR='/var/lib/docker/overlay2/4ea462b2499ca9d4fff967b4d082342c1678bd748f40723181e3bedfdc1eda5f/diff/usr/lib/postgresql10/bin'
PG_BIN_DIR='/usr/bin'
DB_RESTORE_DIR='/opt/sma/dr_backup/db_backup'
DB_PASS_FILE='/root/.pgpass'

DR_TMP_DIR='/opt/sma/tmp'
DR_OUTPUT_DIR='/opt/sma/tmp'
DR_NFS_DIR='/opt/sma/nfs'
DR_SMARTA_DIR='/opt/sma/smarta-nfs'

TGT_DB_HOST='smaxdev-rds.cz4qew1aonte.us-west-2.rds.amazonaws.com'
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

#CDFCTL='/opt/kubernetes/scripts/cdfctl.sh'
#ForEKS
CDFCTL='/install/2020.02/ITOM_Platform_Foundation_BYOK_2020.02.00119/scripts/cdfctl.sh'
################################################################################
#####                        TARGET SERVER  RESTORE                        #####
################################################################################

##Database Restore from GZipped Backup
##On the Database Host:
function restore_db() {
    PG_RESTORE=$PG_BIN_DIR/pg_restore

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

    ##Create .pgpass file to hold db login
    echo "\#$DB_PASS_FILE" | sudo tee $DB_PASS_FILE
    for db in "${!suiteDBs[@]}"
    do
        DB_NAME=$db
        IFS=';' read -ra dbARR <<< ${suiteDBs[$db]}
        DB_USER=${dbARR[0]}
        DB_PASS=${dbARR[1]}
    
        echo "$TGT_DB_HOST:5432:$DB_NAME:$DB_USER:$DB_PASS" | sudo tee -a $DB_PASS_FILE
    done
    sudo chmod 600 $DB_PASS_FILE

    ##Create DB Users and blank Databases if needed
    echo "$TGT_DB_HOST:5432:postgres:postgres:Gr33nl1ght_" | sudo tee -a $DB_PASS_FILE
    echo sudo $PG_BIN_DIR/psql -U postgres -h $TGT_DB_HOST
    for db in "${!suiteDBs[@]}"
    do
        DB_NAME=$db
        IFS=';' read -ra dbARR <<< ${suiteDBs[$db]}
        DB_USER=${dbARR[0]}
        DB_PASS=${dbARR[1]}
    
        echo "CREATE DATABASE $DB_NAME;"
        echo "CREATE USER $DB_USER with password $DB_PASS;"
        echo "GRANT ALL PRIVILEGES ON $DB_NAME TO $DB_USER;"
    done
    echo "\q"

    START_TIME=$(date +%Y%m%d_%H%M%S)
    DR_DATE=$(date +%Y%m%d_%H%M%S)
    for db in "${!suiteDBs[@]}"
    do
        DB_NAME=$db
        IFS=';' read -ra dbARR <<< ${suiteDBs[$db]}
        DB_USER=${dbARR[0]}
        DB_PASS=${dbARR[1]}
        #DB_FILENAME=$DB_BACKUP_DIR/$DR_DATE.$DB_NAME-$DB_USER.dmp
        DB_FILENAME=`ls $DB_RESTORE_DIR/*.$DB_NAME-$DB_USER.dmp`

        sudo $PG_RESTORE -Fc -c -d $DB_NAME -U $DB_USER -h $TGT_DB_HOST -v < $DB_FILENAME
        #sudo $PG_RESTORE -Fc -c -d xservices_rms -U maas_admin -h $TGT_DB_HOST < 20200824_213626.xservices_rms-maas_admin.dmp
        #sudo $PG_DUMP -Fc -c --inserts $DB_NAME -U $DB_USER -h $TGT_DB_HOST -f $DB_FILENAME
        #sudo $PG_DUMP -Fc -c --inserts bo_config -U bo_db_user -h $TGT_DB_HOST -f 20200824_213626.bo_config-bo_db_user.dmp
        #sudo $PG_DUMP -Fc -c --inserts bo_ats -U bo_db_user -h $TGT_DB_HOST -f 20200824_213626.bo_ats-bo_db_user.dmp
        #sudo $PG_DUMP -Fc -c --inserts bo_license -U bo_db_user -h $TGT_DB_HOST -f 20200824_213626.bo_license-bo_db_user.dmp
        #sudo $PG_DUMP -Fc -c --inserts bo_user -U bo_db_user -h $TGT_DB_HOST -f 20200824_213626.bo_user-bo_db_user.dmp
        #sudo $PG_DUMP -Fc -c --inserts autopassdb -U autopass -h $TGT_DB_HOST -f 20200824_213626.autopassdb-autopass.dmp
        #sudo $PG_DUMP -Fc -c --inserts idm -U idm -h $TGT_DB_HOST -f 20200824_213626.idm-idm.dmp
        #sudo $PG_DUMP -Fc -c --inserts maas_admin -U maas_admin -h $TGT_DB_HOST -f 20200824_213626.maas_admin-maas_admin.dmp
        #sudo $PG_DUMP -Fc -c --inserts maas_template -U maas_admin -h $TGT_DB_HOST -f 20200824_213626.maas_template-maas_admin.dmp
        #sudo $PG_DUMP -Fc -c --inserts xservices_ems -U maas_admin -h $TGT_DB_HOST -f 20200824_213626.xservices_ems-maas_admin.dmp
        #sudo $PG_DUMP -Fc -c --inserts xservices_mng -U maas_admin -h $TGT_DB_HOST -f 20200824_213626.xservices_mng-maas_admin.dmp
        #sudo $PG_DUMP -Fc -c --inserts xservices_rms -U maas_admin -h $TGT_DB_HOST -f 20200824_213626.xservices_rms-maas_admin.dmp
        #sudo $PG_DUMP -Fc -c --inserts smartadb -U smarta -h $TGT_DB_HOST -f 20200824_213626.smartadb-smarta.dmp
        #sudo $PG_DUMP -Fc -c --inserts autopassdb -U autopass -h $TGT_DB_HOST -f 20200824_213626.autopassdb-autopass.dmp
    done
    COMPLETE_TIME=$(date +%Y%m%d_%H%M%S)
    echo "Completed RESTORE: $START_TIME - $COMPLETE_TIME"
    
}

restore_db $DB_RESTORE_DIR
