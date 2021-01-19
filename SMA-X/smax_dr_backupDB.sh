#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery for SMA-X Suite on ITOM Platform for Schlumberger
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
<<<<<<< HEAD
=======
USE_SUDO=1
>>>>>>> 7159625be18995e887c5cb2adc504196760a78d2
PG_VERSION='9.6'
DB_BACKUP_DIR='/opt/sma/db'

DR_TMP_DIR='/opt/sma/tmp'
DR_OUTPUT_DIR='/opt/sma/tmp'
DR_NFS_DIR='/opt/sma/nfs'
DR_SMARTA_DIR='/opt/sma/smarta-nfs'

SRC_DB_HOST='slcvd-sma-d01.dev.glg.lcl'
SRC_MASTER_HOST='azr6133prdapp01.earaa6133.azr.slb.com'
SRC_NFS_HOST='10.192.236.147'

TGT_DB_HOST=
TGT_MASTER_HOST=
TGT_NFS_HOST=

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

################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################

##Database Backups - Not full DUMPALL
##On the Database Host:
function backup_db() {
    DB_BACKUP_DIR=$1
    PG_VERSION=$2

    PG_DUMP=/usr/pgsql-$PG_VERSION/bin/pg_dump

    cd /tmp
    mkdir -p $DB_BACKUP_DIR
    
    declare -A suiteDBs
<<<<<<< HEAD
    suiteDBs[autopassdb]=autopass
    suiteDBs[bo_ats]=bo_db_user
    suiteDBs[bo_config]=bo_db_user
    suiteDBs[bo_license]=bo_db_user
    suiteDBs[bo_user]=bo_db_user
    suiteDBs[idm]=idm
    suiteDBs[maas_admin]=maas_admin
    suiteDBs[maas_template]=maas_admin
    suiteDBs[xservices_ems]=maas_admin
    suiteDBs[xservices_mng]=maas_admin
    suiteDBs[xservices_rms]=maas_admin
    suiteDBs[smartadb]=smarta
    #suiteDBs[sxdb]=dbadmin
=======
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
>>>>>>> 7159625be18995e887c5cb2adc504196760a78d2

    DR_DATE=$(date +%Y%m%d_%H%M%S)
    for db in "${!suiteDBs[@]}"
    do
        DB_NAME=$db
        DB_USER=${suiteDBs[$db]}
        DB_FILENAME=$DB_BACKUP_DIR/$DR_DATE.$DB_NAME-$DB_USER.dmp

        echo DR Backup DB: Backing up $DB_NAME to File $DB_FILENAME ...
<<<<<<< HEAD
        sudo -u postgres $PG_DUMP -Fc -c --inserts -f $DB_FILENAME $DB_NAME -U $DB_USER -h `hostname -f`
=======
        sudo -u postgres $PG_DUMP -Fc -c --inserts $DB_NAME -U $DB_USER -h `hostname -f` -w -f $DB_FILENAME
        ##If using PostgreSQL 9.5 -f is not an option instead output command to a file
        #sudo -u postgres $PG_DUMP -Fc -c --inserts -d $DB_NAME -w -U $DB_USER > $DB_FILENAME
        #sudo -u postgres $PG_DUMP -Fc -c --inserts -d $DB_NAME -w -U $DB_USER > $DB_FILENAME
>>>>>>> 7159625be18995e887c5cb2adc504196760a78d2
    done
}

backup_db $DB_BACKUP_DIR $PG_VERSION
