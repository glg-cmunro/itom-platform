#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery for SMA-X Suite on ITOM Platform for Schlumberger
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
DB_BACKUP_DIR='/data/dr/db'
DB_PASS_FILE='~/.pgpass'

DR_BIN_DIR='/opt/smax/2020.11/tools'
DR_TMP_DIR='/data/dr/tmp'
DR_OUTPUT_DIR='/data/dr/output'

SRC_DB_HOST='10.241.160.2'

################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################

##Database Backups - Not full DUMPALL
##On the Database Host:
function backup_db() {
    DB_BACKUP_DIR=$1
    PG_DUMP=/usr/bin/pg_dump

    cd /tmp
    sudo mkdir -p $DB_BACKUP_DIR
    sudo chmod 777 $DB_BACKUP_DIR
    
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

    DR_DATE=$(date +%Y%m%d_%H%M%S)
    for db in "${!suiteDBs[@]}"
    do
        DB_NAME=$db
        DB_USER=${suiteDBs[$db]}
        DB_FILENAME=$DB_BACKUP_DIR/$DR_DATE.$DB_NAME-$DB_USER.dmp

        echo DR Backup DB: Backing up $DB_NAME to File $DB_FILENAME ...
        $PG_DUMP -Fc -c --inserts $DB_NAME -U $DB_USER -h $SRC_DB_HOST -w -f $DB_FILENAME
    done
}

backup_db $DB_BACKUP_DIR
