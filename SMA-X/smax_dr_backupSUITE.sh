#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery for SMA-X Suite on ITOM Platform for Schlumberger
#
# Disaster Recovery Backup script for SMA-X Suite on ITOM Platform
# NOTE: Based on DR Toolkit and instructions provided by Micro Focus

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
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
DR_BIN_DIR='/var/vols/itom/toolkit_1.1.3'
DR_TMP_DIR='/var/vols/itom/tmp'
DR_OUTPUT_DIR='/var/vols/itom/dr_backup/suite_backup'
DR_NFS_DIR='/opt/sma/nfs'
DR_SMARTA_DIR='/opt/sma/smarta-nfs'

##PRD
#SRC_MASTER_HOST='10.0.1.127'
#SRC_NFS_HOST='10.0.1.127'
#SRC_GLOBAL_VOL='/PRD_SIS_ITSMA_GLOBAL'
#SRC_SMARTA_VOL='/PRD_SIS_ITMSA_SMARANALYTICS'

##QTY
SRC_MASTER_HOST='10.0.1.163'
SRC_NFS_HOST='10.0.1.163'
SRC_GLOBAL_VOL='/var/vols/itom/itsma/global-volume'
SRC_SMARTA_VOL='/var/vols/itom/itsma/smartanalytics-volume'

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

    sudo mkdir -p $DR_TMP_DIR
    sudo mkdir -p $DR_OUTPUT_DIR
    sudo mkdir -p $DR_NFS_DIR
    sudo mkdir -p $DR_SMARTA_DIR

    ##Mount the necessary NFS directories for the Suite
    mount $SRC_NFS_HOST:$SRC_GLOBAL_VOL $DR_NFS_DIR
    [[!-z "${SRC_SMARTA_VOL}"]] && mount $SRC_NFS_HOST:$SRC_SMARTA_VOL $DR_SMARTA_DIR

    ##Backup Config
    [-z "${SRC_SMARTA_VOL}"] && python $DR_BIN_DIR/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -nfs $DR_NFS_DIR --disable-idol -m backup \
    || python $DR_BIN_DIR/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -nfs $DR_NFS_DIR -idol $DR_SMARTA_DIR -m backup

    ##Compress Backup to Datafile
    python $DR_BIN_DIR/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t $DR_TMP_DIR -b $DR_OUTPUT_DIR -m backup

    ##Unmount the SUITE NFS directories after backup completes
    umount $DR_NFS_DIR
    [[!-z "${SRC_SMARTA_VOL}"]] && umount $DR_SMARTA_DIR

}

#Clean up old versions of the backup before starting new (Keep 7 days)

backup_suite
