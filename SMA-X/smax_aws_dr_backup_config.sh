#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery Backup script for SMA-X Suite configuration on ITOM Platform
# Schedule to run for regular maintenance backup process
# NOTE: Based on DR Toolkit and instructions provided by Micro Focus

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
NFS_BASE_PATH='/mnt/efs'
DR_BIN_DIR='/var/vols/itom/toolkit_1.1.3'
DR_TMP_DIR='/opt/smax/tmp'
DR_OUTPUT_DIR='/opt/sma/tmp'
#DR_NFS_DIR='/opt/sma/nfs'
#DR_SMARTA_DIR='/opt/sma/smarta-nfs'

##QTY
#SRC_NFS_HOST='10.0.1.163'
#SRC_GLOBAL_VOL='/var/vols/itom/itsma/global-volume'
#SRC_SMARTA_VOL='/var/vols/itom/itsma/smartanalytics-volume'

##DEV
#SRC_NFS_HOST='10.192.236.147'
#SRC_GLOBAL_VOL='/DEV_SIS_ITSMA_GLOBAL'
#SRC_SMARTA_VOL='/DEV_SIS_ITMSA_SMARANALYTICS'


################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################
## Suite Backup
function backup_suite() {
    ##Verify pre-requisites with preaction script to ensure all mount points are accessible
    #python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_preaction.py
    
    sudo mkdir -p $DR_TMP_DIR
    sudo mkdir -p $DR_OUTPUT_DIR
    sudo mkdir -p $DR_NFS_DIR
    sudo mkdir -p $DR_SMARTA_DIR

    ###Mount the necessary NFS directories for the Suite
    #mount $SRC_NFS_HOST:$SRC_GLOBAL_VOL $DR_NFS_DIR
    #[[!-z "${SRC_SMARTA_VOL}"]] && mount $SRC_NFS_HOST:$SRC_SMARTA_VOL $DR_SMARTA_DIR

    ##Backup Config only
    python3 $DR_BIN_DIR/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR --disable-attachment --disable-nfs --disable-idol -m backup
    
    ##Compress Backup to Datafile
    python $DR_BIN_DIR/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t $DR_TMP_DIR -b $DR_OUTPUT_DIR -m backup

    ###Unmount the SUITE NFS directories after backup completes
    #umount $DR_NFS_DIR
    #[[!-z "${SRC_SMARTA_VOL}"]] && umount $DR_SMARTA_DIR

}

#Clean up old versions of the backup before starting new (Keep 7 days)

backup_suite
