#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery for SMA-X Suite on ITOM Platform for Schlumberger
# Backup SUITE from Source
#


##### 2020.11 ############


curl -k 
python3 /opt/smax/2020.11/tools/disaster-recovery/sma_dr_executors/dr_preaction.py






##### END 2020.11 ########

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
PG_VERSION='10.17'
DB_BACKUP_DIR='/data/dr/db'

DR_TMP_DIR='/data/dr/tmp'
DR_OUTPUT_DIR='/data/dr/output'
DR_NFS_DIR='/data/dr/nfs'
DR_SMARTA_DIR='/data/dr/smarta-nfs'

SRC_DB_HOST=10.198.0.2
SRC_MASTER_HOST='gcp6133prdapp01'
SRC_NFS_HOST=10.145.240.146

TGT_DB_HOST=
TGT_MASTER_HOST=
TGT_NFS_HOST=

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

    DR_DATE=$(date +%Y%m%d_%H%M%S)
    for db in "${!suiteDBs[@]}"
    do
        DB_NAME=$db
        DB_USER=${suiteDBs[$db]}
        DB_FILENAME=$DB_BACKUP_DIR/$DR_DATE.$DB_NAME-$DB_USER.dmp

        echo DR Backup DB: Backing up $DB_NAME to File $DB_FILENAME ...
        sudo -u postgres $PG_DUMP -Fc -c --inserts -f $DB_FILENAME $DB_NAME -U $DB_USER -h `hostname -f`
    done
}


##Suite Backups
##On Master01 with the DR Toolkit installed
function backup_suite() {
    ##Verify pre-requisites with preaction script to ensure all mount points are accessible
    #python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_preaction.py
    
    mkdir -p /opt/sma/tmp
    mkdir -p /opt/sma/output

    ##Mount the necessary NFS directories for the Suite
    mkdir -p /opt/sma/nfs
    mkdir -p /opt/sma/smarta-nfs

    ##Backup Config
    python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m backup

    ##Compress Backup to Datafile
    python /opt/sma/bin/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t /opt/sma/tmp -b /opt/sma/output -m backup

}

################################################################################
#####                       TARGET SERVER  - RESTORE                       #####
################################################################################

##Copy only the lastest set of DB Backup Files to Target DB Host
##On the Target Database Host:
function restore_db() {


    sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d autopassdb `ls /opt/sma/db/*_autopassdb.dmp.Fc`
}




function restore_suite() {
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*autopassdb*` -d autopassdb -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*bo_ats*` -d bo_ats -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*bo_config*` -d bo_config -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*bo_license*` -d bo_license -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*bo_user*` -d bo_user -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*maas_admin*` -d maas_admin -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*maas_template*` -d maas_template -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*smartadb*` -d smartadb -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*idm*` -d idm -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*xservices_ems*` -d xservices_ems -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*xservices_mng*` -d xservices_mng -h `hostname -f`
    sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -f `ls /opt/sma/db/*xservices_rms*` -d xservices_rms -h `hostname -f`

#If backup was made using 'pg_dump -Fc'
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d autopassdb `ls /opt/sma/db/*_autopassdb.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d bo_ats `ls /opt/sma/db/*bo_ats.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d bo_config `ls /opt/sma/db/*bo_config.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d bo_license `ls /opt/sma/db/*bo_license.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d bo_user `ls /opt/sma/db/*bo_user.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d maas_admin `ls /opt/sma/db/*maas_admin.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d maas_template `ls /opt/sma/db/*maas_template.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d smartadb `ls /opt/sma/db/*smartadb.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d idm `ls /opt/sma/db/*idm.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d xservices_ems `ls /opt/sma/db/*xservices_ems.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d xservices_mng `ls /opt/sma/db/*xservices_mng.dmp.Fc`
sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U postgres -w -c -v -h `hostname -f` -d xservices_rms `ls /opt/sma/db/*xservices_rms.dmp.Fc`

##Copy Suite Backup to Target Master
##Verify pre-requisites with preaction script to ensure all mount points are accessible
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_preaction.py

##Extract Suite backup to be restored
python /opt/sma/bin/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t /opt/sma/tmp -b /opt/sma/output -m restore -f `ls /opt/sma/output/*`

##Restore Config parts only
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m restore --disable-idol --disable-nfs --disable-attachment

##Update configmaps before continuing
ns=$(kubectl get ns | grep itsma | awk {'print $1'}); kubectl edit cm database-configmap -n $ns -o yaml

##Restore NFS Data parts only
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m restore --disable-idol --disable-config-map --disable-attachment

##Restore Attachment Data parts only
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp/target -m restore --disable-idol --disable-config-map --disable-nfs

## Start the Suite and verify login to BO
ns=$(kubectl get ns | grep itsma | awk {'print $1'}); /opt/kubernetes/scripts/cdfctl.sh runlevel set -l UP -n $ns

##Restore Smartanalytics Data parts only
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp/target -m restore  --disable-config-map --disable-nfs -idol /opt/sma/smartanalytics-nfs

}


backup_db $DB_BACKUP_DIR $PG_VERSION
