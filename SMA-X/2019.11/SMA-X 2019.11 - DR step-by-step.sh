#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery for SMA-X 2019.11 on ITOM Platform
#

################################################################################
#####                  SOURCE SERVER BACKUP - DATABASE 01                  #####
################################################################################
SOURCE_DBHOST='azr6133prddb05.earaa6133.azr.slb.com'
SOURCE_MASTER='azr6133prdapp01.earaa6133.azr.slb.com'
SOURCE_NFS='10.192.236.147'
TARGET_DBHOST=<DR SYSTEM DB HOSTNAME>
TARGET_MASTER=<DR SYSTEM MASTER>
TARGET_NFS=<DR SYSTEM NFS IP>
PGSQL_VERSION='9.6'

DB_BACKUP_DIR='/opt/sma/db'
DR_SCRIPT_DIR='$DB_BACKUP_DIR/scripts'
DB_RESTORE_DIR='$DB_BACKUP_DIR/restore'

################################################################################
#####                  SOURCE SERVER BACKUP - DATABASE 01                  #####
################################################################################
mkdir -p /opt/sma/db   #Make sure we match the DB Backup Disk to the directory used here (we used /backup/backups)

##Database Backups - Not full DUMPALL
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
#suiteDBs[sxdb]=dbadmin #Add SMA-X Version and include this with if version = 2019.05

dbDate=$(date +%Y%m%d_%H%M%S)
for db in "${!suiteDBs[@]}"
do
  dbName=$db
  dbUser=${suiteDBs[$db]}
  sudo -u postgres /usr/pgsql-$PGSQL_VERSION/bin/pg_dump -Fc -c --inserts -f $DB_BACKUP_DIR/$dbDate.$dbName-$dbUser.dmp $dbName -U $dbUser -h `hostname -f`
done
  sudo -u postgres /usr/pgsql-$PGSQL_VERSION/bin/pg_dump -Fc -c --inserts -f $DB_BACKUP_DIR/$dbDate.$dbName-$dbUser.dmp $dbName -U $dbUser -h `hostname -f`

##NOT USED##
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_autopassdb.dmp autopassdb -U autopass -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_ats.dmp bo_ats -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_config.dmp bo_config -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_license.dmp bo_license -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_user.dmp bo_user -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_maas_admin.dmp maas_admin -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_maas_template.dmp maas_template -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_smartadb.dmp smartadb -U smarta -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_idm.dmp idm -U idm -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_ems.dmp xservices_ems -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_mng.dmp xservices_mng -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_rms.dmp xservices_rms -U maas_admin -h `hostname -f`

#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_autopassdb.dmp.Fc autopassdb -U autopass -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_ats.dmp.Fc bo_ats -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_config.dmp.Fc bo_config -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_license.dmp.Fc bo_license -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_user.dmp.Fc bo_user -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_maas_admin.dmp.Fc maas_admin -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_maas_template.dmp.Fc maas_template -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_smartadb.dmp.Fc smartadb -U smarta -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_idm.dmp.Fc idm -U idm -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_ems.dmp.Fc xservices_ems -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_mng.dmp.Fc xservices_mng -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c --inserts  -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_rms.dmp.Fc xservices_rms -U maas_admin -h `hostname -f`

#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.autopass.dmp.Fp autopassdb -U autopass -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.bo_db_user.dmp.Fp autopassdb -U autopass -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.bo_ats.dmp.Fp bo_ats -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.bo_config.dmp.Fp bo_config -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.bo_license.dmp.Fp bo_license -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.bo_user.dmp.Fp bo_user -U bo_db_user -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.maas_admin.dmp.Fp maas_admin -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.maas_template.dmp.Fp maas_template -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.smartadb.dmp.Fp smartadb -U smarta -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.idm.dmp.Fp idm -U idm -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.xservices_ems.dmp.Fp xservices_ems -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.xservices_mng.dmp.Fp xservices_mng -U maas_admin -h `hostname -f`
#sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fp -c --inserts -f /opt/sma/db/$dbDate.xservices_rms.dmp.Fp xservices_rms -U maas_admin -h `hostname -f`

################################################################################
#####                   SOURCE SERVER BACKUP - MASTER 01                   #####
################################################################################
mkdir -p /opt/sma/tmp
mkdir -p /opt/sma/output


##Suite Backup
##On Master01 with the DR Toolkit installed

##Verify pre-requisites with preaction script to ensure all mount points are accessible
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_preaction.py

##Mount the necessary NFS directories for the Suite
mkdir -p /opt/sma/nfs
mkdir -p /opt/sma/smarta-nfs

global_volume_nfs=$(df -h | grep -v tmpfs | grep itom-vol | head -n1 | awk {'print $1'})
smarta_volume_nfs=$(df -h | grep -v tmpfs | grep smartanalytics-volume | head -n1 | awk {'print $1'})
echo $global_volume_nfs
echo $smarta_volume_nfs

#MOUNT COMMNADS GO HERE


##Backup Config
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m backup

##Compress Backup to Datafile
python /opt/sma/bin/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t /opt/sma/tmp -b /opt/sma/output -m backup


###TRANSFER PROCESS

#Need to make files made from source server available on target restore server
#One option could be to add a file copy to the end of the backup process to place a copy of the files on NFS server

###RESTORE PROCESS

################################################################################
#####                       TARGET SERVER  - RESTORE                       #####
################################################################################

##Copy only the lastest set of DB Backup Files to Target DB Host
##On the Target Database Host:
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

dbDate_latest=$(ls -lat /opt/sma/db/| awk {'print $9'} | awk -F. {'print $1'} | head -n 2 | tail -n 1)
for db in "${!suiteDBs[@]}"
do
  dbName=$db
  dbUser=${suiteDBs[$db]}
  sudo -u postgres /usr/pgsql-9.6/bin/pg_restore -U $dbUser -d $dbName -w -c -v -h `hostname -f` /opt/sma/db/$dbDate_latest.$dbName-$dbUser.dmp
done

'''
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
'''

#If backup was made using 'pg_dump -Fc'
'''
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
'''

##To execute as pg_dumpall
#sudo -u postgres /usr/pgsql-9.6/bin/psql -U postgres -w -f /opt/sma/db/20200313_smax_dr_dumpall.dmp


################################################################################
#####                TARGET SERVER FOR RESTORE - MASTER 01                 #####
################################################################################
##NOTE: add if to check if directory already exists / and is empty
mkdir -p /opt/sma/tmp
mkdir -p /opt/sma/output

##Mount the necessary NFS directories for the Suite
mkdir -p /opt/sma/nfs
mkdir -p /opt/sma/smarta-nfs

global_volume_nfs=$(df -h | grep -v tmpfs | grep itom-vol | head -n1 | awk {'print $1'})
smarta_volume_nfs=$(df -h | grep -v tmpfs | grep smartanalytics-volume | head -n1 | awk {'print $1'})
echo $global_volume_nfs
echo $smarta_volume_nfs

#MOUNT COMMNADS GO HERE

##Copy Suite Backup to Target Master
##Verify pre-requisites with preaction script to ensure all mount points are accessible
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_preaction.py

##Extract Suite backup to be restored
python /opt/sma/bin/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t /opt/sma/tmp -b /opt/sma/output -m restore -f `ls /opt/sma/output/*`

##Restore Config parts only
##SMA-X version 2019.08+
#python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m restore --disable-idol --disable-nfs --disable-attachment
##OTHERWISE
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m restore --disable-idol --disable-nfs

###PAUSE HERE WITH MANUAL STEP FOR UPDATE CONFIG MAP###
##Update configmaps before continuing
ns=$(kubectl get ns | grep itsma | awk {'print $1'}); kubectl edit cm database-configmap -n $ns -o yaml
###CONTINUE HERE AFTER MANUAL STEP FOR UPDATE CONFIG MAP###

##Restore NFS Data parts only
#python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m restore --disable-idol --disable-config-map --disable-attachment
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m restore --disable-idol --disable-config-map -nfs /opt/sma/nfs #variable for <NFS FOLDER>

##Restore Attachment Data parts only
##Only for SMA-X 2019.08+
#python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp/target -m restore --disable-idol --disable-config-map --disable-nfs

## Start the Suite and verify login to BO
ns=$(kubectl get ns | grep itsma | awk {'print $1'}); /opt/kubernetes/scripts/cdfctl.sh runlevel set -l UP -n $ns

##Restore Smartanalytics Data parts only
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m restore  --disable-config-map --disable-nfs -idol /opt/sma/smartanalytics-nfs #variable for <SMARTA-NFS-FOLDER>
