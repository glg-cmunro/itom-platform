#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery Backup script for SMA-X Suite on ITOM Platform
# NOTE: Based on DR Toolkit and instructions provided by Micro Focus

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
#DR_BIN_DIR='/opt/sma/bin'
#DR_TMP_DIR='/opt/sma/tmp'
#DR_OUTPUT_DIR='/opt/sma/output'
#DR_NFS_DIR='/opt/sma/nfs'
#DR_SMARTA_DIR='/opt/sma/smarta-nfs'
DR_BIN_DIR='/data/GLGfiles/toolkit111'
DR_TMP_DIR='/data/GLGfiles/tmp'
DR_OUTPUT_DIR='/data/GLGfiles/suitebackupDR'
DR_NFS_DIR='/data/GLGfiles/dr_nfs'
DR_SMARTA_DIR='/data/GLGfiles/dr_smarta-nfs'

##PRD
SRC_MASTER_HOST='usarav222.specialties.int.huntsman.com'
SRC_NFS_HOST='usarav228'
SRC_GLOBAL_VOL='/var/vols/itom/itsma/global-volume'
SRC_SMARTA_VOL='/var/vols/itom/itsma/smartanalytics-volume'

##QTY
#SRC_MASTER_HOST='azr6133qtyapp01.earaa6133.azr.slb.com'
#SRC_NFS_HOST='10.192.240.161'
#SRC_GLOBAL_VOL='/QTY_SIS_ITSMA_GLOBAL'
#SRC_SMARTA_VOL=''

##DEV
#SRC_MASTER_HOST='azr6133devapp10.earaa6133.azr.slb.com'
#SRC_NFS_HOST='10.192.236.147'
#SRC_GLOBAL_VOL='/DEV_SIS_ITSMA_GLOBAL'
#SRC_SMARTA_VOL='/DEV_SIS_ITMSA_SMARANALYTICS'


################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################
##Suite Backups
##On Master01 with the DR Toolkit installed
function backup_suite() {
    ##Verify pre-requisites with preaction script to ensure all mount points are accessible
    #python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_preaction.py
    
    sudo mkdir -p $DR_TMP_DIR
    sudo mkdir -p $DR_OUTPUT_DIR
    sudo mkdir -p $DR_NFS_DIR
    sudo mkdir -p $DR_SMARTA_DIR

    ##Mount the necessary NFS directories for the Suite
    sudo mount $SRC_NFS_HOST:$SRC_GLOBAL_VOL $DR_NFS_DIR
    sudo mount $SRC_NFS_HOST:$SRC_SMARTA_VOL $DR_SMARTA_DIR

    ##Backup Config
    sudo python $DR_BIN_DIR/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -nfs $DR_NFS_DIR -idol $DR_SMARTA_DIR -m backup

    ##Compress Backup to Datafile
    sudo python $DR_BIN_DIR/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t $DR_TMP_DIR -b $DR_OUTPUT_DIR -m backup

    ##Unmount the SUITE NFS directories after backup completes
    sudo umount $DR_NFS_DIR
    sudo umount $DR_SMARTA_DIR

}

#Clean up old versions of the backup before starting new (Keep 7 days)

backup_suite
