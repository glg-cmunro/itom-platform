#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery Backup script for SMA-X Suite on ITOM Platform
# NOTE: Based on DR Toolkit and instructions provided by Micro Focus

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
DR_BIN_DIR='/opt/sma/bin'
DR_TMP_DIR='/opt/sma/tmp'
DR_OUTPUT_DIR='/opt/sma/output'
DR_NFS_DIR='/opt/sma/nfs'
DR_SMARTA_DIR='/opt/sma/smarta-nfs'
ns=$(kubectl get ns | grep itsma | awk {'print $1'});
##PRD
#SRC_MASTER_HOST='azr6133prdapp01.earaa6133.azr.slb.com'
#SRC_NFS_HOST='10.192.236.147'
#SRC_GLOBAL_VOL='/PRD_SIS_ITSMA_GLOBAL'
#SRC_SMARTA_VOL='/PRD_SIS_ITMSA_SMARANALYTICS'

##QTY
#SRC_MASTER_HOST='azr6133qtyapp01.earaa6133.azr.slb.com'
#SRC_NFS_HOST='10.192.240.161'
#SRC_GLOBAL_VOL='/QTY_SIS_ITSMA_GLOBAL'
#SRC_SMARTA_VOL=''

##DEV
SRC_MASTER_HOST='azr6133devapp10.earaa6133.azr.slb.com'
SRC_NFS_HOST='10.192.240.188'
SRC_GLOBAL_VOL='/TMP_SIS_ITSMA_ITSMAGLOBAL'
SRC_SMARTA_VOL='/TMP_SIS_ITSMA_SMARANALYTICS'


################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################
##Suite Backups
##On Master01 with the DR Toolkit installed
function restore_suite() {
    ##Verify pre-requisites with preaction script to ensure all mount points are accessible
    #python /opt/sma/bin/disaster_recovery/sma_dr_executors/dr_preaction.py
    
    mkdir -p $DR_TMP_DIR
    mkdir -p $DR_OUTPUT_DIR
    mkdir -p $DR_NFS_DIR
    mkdir -p $DR_SMARTA_DIR

    ##Mount the necessary NFS directories for the Suite
    mount $SRC_NFS_HOST:$SRC_GLOBAL_VOL $DR_NFS_DIR
    mount $SRC_NFS_HOST:$SRC_SMARTA_VOL $DR_SMARTA_DIR

    ##Uncompress the backup file to restorable content
    python $DR_BIN_DIR/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t $DR_TMP_DIR -b $DR_OUTPUT_DIR -m restore -f `ls $DR_OUTPUT_DIR/sma-*`

    ##Restore SUITE Configuration content only
    python $DR_BIN_DIR/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m restore --disable-idol --disable-nfs

    ##Pause to execute ConfigMap updates
    read -p '''
    MANUAL STEP: Update default config map after import ... 
    In a seperate terminal execute the following:
    kubectl edit cm database-configmap -n $ns -o yaml
    Update the DB information to point back to restored DB Host
    Save the updates, then Press [ENTER] to continue
    '''

    python $DR_BIN_DIR//disaster_recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m restore --disable-idol --disable-config-map -nfs $DR_NFS_DIR


    ##Pause to execute ConfigMap updates
    read -p '''
    MANUAL STEP: Restart the SUITE and wait for it to be ready ... 
    In a seperate terminal execute the following:
    /opt/kubernetes/scripts/cdfctl.sh runlevel set -l UP -n $ns
    
    Once the SUITE is ready, Press [ENTER] to finish the restore ...
    '''

    ##Unmount the SUITE NFS directories after backup completes
    umount $DR_NFS_DIR
    umount $DR_SMARTA_DIR

}

#Clean up old versions of the backup before starting new (Keep 7 days)

restore_suite
