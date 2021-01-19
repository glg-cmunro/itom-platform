#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery for SMA-X 2019.11 on ITOM Platform
#

################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################

##Database Backups - Not full DUMPALL
##On the Database Host:
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

for db in "${!suiteDBs[@]}"
do
  dbName=$db
  dbUser=${suiteDBs[$db]}
done

for db,user in sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_autopassdb.dmp autopassdb -U autopass -h `hostname -f`

sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_autopassdb.dmp autopassdb -U autopass -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_ats.dmp bo_ats -U bo_db_user -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_config.dmp bo_config -U bo_db_user -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_license.dmp bo_license -U bo_db_user -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_user.dmp bo_user -U bo_db_user -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_maas_admin.dmp maas_admin -U maas_admin -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_maas_template.dmp maas_template -U maas_admin -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_smartadb.dmp smartadb -U smarta -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_idm.dmp idm -U idm -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_ems.dmp xservices_ems -U maas_admin -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_mng.dmp xservices_mng -U maas_admin -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_rms.dmp xservices_rms -U maas_admin -h `hostname -f`

sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_autopassdb.dmp.Fc autopassdb -U autopass -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_ats.dmp.Fc bo_ats -U bo_db_user -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_config.dmp.Fc bo_config -U bo_db_user -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_license.dmp.Fc bo_license -U bo_db_user -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_bo_user.dmp.Fc bo_user -U bo_db_user -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_maas_admin.dmp.Fc maas_admin -U maas_admin -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_maas_template.dmp.Fc maas_template -U maas_admin -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_smartadb.dmp.Fc smartadb -U smarta -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_idm.dmp.Fc idm -U idm -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_ems.dmp.Fc xservices_ems -U maas_admin -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_mng.dmp.Fc xservices_mng -U maas_admin -h `hostname -f`
sudo -u postgres /usr/pgsql-9.6/bin/pg_dump -Fc -c -f /opt/sma/db/`date +%g%m%d_%H%M%S`_dr_xservices_rms.dmp.Fc xservices_rms -U maas_admin -h `hostname -f`

##Suite Backups
##On Master01 with the DR Toolkit installed

##Verify pre-requisites with preaction script to ensure all mount points are accessible
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_preaction.py

##Mount the necessary NFS directories for the Suite


##Backup Config
python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t /opt/sma/tmp -m backup

##Compress Backup to Datafile
python /opt/sma/bin/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t /opt/sma/tmp -b /opt/sma/output -m backup


################################################################################
#####                       TARGET SERVER  - RESTORE                       #####
################################################################################

##Copy only the lastest set of DB Backup Files to Target DB Host
##On the Target Database Host:
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
