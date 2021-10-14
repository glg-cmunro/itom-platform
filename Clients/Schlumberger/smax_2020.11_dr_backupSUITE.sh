#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
#
# Disaster Recovery for SMA-X Suite on ITOM Platform for Schlumberger
#
# NOTE: When downloading the toolkit from Marketplace you need to modify
#       a couple of python scripts to not change the permissions of the
#       DR_OUTPUT_DIR for this to work as non-root
#
#       Comment out the following line:
#         sh('chmod 700 ' + shell_quote(DATA_PATH))
#       FROM:
#         <dr_tools_install_dir>/sma_dr_storage/storage_dispatcher.py
#
#       Comment out the following line:
#         sh('chmod 700 -R ' + shell_quote(storage_path))
#       FROM:
#         <dr_tools_install_dir>/sma_dr_executors/pre_backup.py
#         

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
PG_VERSION='10.15'
DB_BACKUP_DIR='/data/dr/db'

#DR_BIN_DIR='/opt/smax/2020.11/tools'
#DR_TMP_DIR='/data/dr/tmp'
#DR_OUTPUT_DIR='/data/dr/output'
#DR_NFS_DIR='/data/dr/nfs'
#DR_SMARTA_DIR='/data/dr/smarta-nfs'

DR_BIN_DIR='/opt/smax/2020.11/tools'
DR_TMP_DIR='/tmp/smax-app-shutdown-backup/tmp'
DR_OUTPUT_DIR='/tmp/smax-app-shutdown-backup/output'
DR_NFS_DIR='/tmp/smax-app-shutdown-backup/nfs'
DR_SMARTA_DIR='/tmp/smax-app-shutdown-backup/smarta-nfs'

##GLG smax-west
SRC_NFS_HOST='10.0.1.127'
SRC_NFS_GLOBAL_VOL='/var/vols/itom/itsma/global-volume'

##GLG optic-dev
#SRC_NFS_HOST='fs-339aec87.efs.us-east-1.amazonaws.com'
#SRC_NFS_GLOBAL_VOL='/var/vols/itom/itsma/global-volume'

##FireEye Prod
#SRC_NFS_HOST='??'
#SRC_NFS_GLOBAL_VOL='??'


################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################
##Suite Backups
##On Master01 with the DR Toolkit installed
function backup_suite() {
    ##Verify pre-requisites with preaction script to ensure all mount points are accessible
    #python /opt/sma/bin/disaster-recovery/sma_dr_executors/dr_preaction.py
    
    sudo mkdir -p $DR_TMP_DIR
    sudo chmod 777 $DR_TMP_DIR
    
    sudo mkdir -p $DR_OUTPUT_DIR
    sudo chmod 777 $DR_OUTPUT_DIR
    
    ##Mount the necessary NFS directories for the Suite
    sudo mkdir -p $DR_NFS_DIR
    sudo chmod 777 $DR_NFS_DIR
    
    sudo mkdir -p $DR_SMARTA_DIR
    sudo chmod 777 $DR_SMARTA_DIR
    
    ##Backup Config Only
    #python3 $DR_BIN_DIR/disaster-recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m backup --disable-nfs --disable-idol
    
    ##Backup Config with NFS
    sudo mkdir -p $DR_TMP_DIR/netapp
    sudo chmod 777 $DR_TMP_DIR/netapp
    #sudo mkdir -p $SRC_NFS_GLOBAL_VOL; sudo chown -R 1999:1999 $SRC_NFS_GLOBAL_VOL
    #sudo mount -t nfs $SRC_NFS_HOST:$SRC_NFS_GLOBAL_VOL $SRC_NFS_GLOBAL_VOL
    sudo python3 $DR_BIN_DIR/disaster-recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m backup --disable-idol
    #sudo umount $SRC_NFS_GLOBAL_VOL

    ##Compress Backup to Datafile
    sudo python3 $DR_BIN_DIR/disaster-recovery/sma_dr_storage/storage_dispatcher.py -t $DR_TMP_DIR -b $DR_OUTPUT_DIR -m backup

}

#Cleanup all file more than 7 days
#find $DR_OUTPUT_DIR -maxdepth 1 -type f -mtime +7 -name '*.tar.gz' -exec rm {} \;

backup_suite
