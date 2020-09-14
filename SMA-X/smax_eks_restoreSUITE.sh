#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery Backup script for SMA-X Suite on ITOM Platform
# NOTE: Based on DR Toolkit and instructions provided by Micro Focus

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
DR_TOOL_PATH=/opt/sma
DR_BIN_DIR=$DR_TOOL_PATH/bin
DR_TMP_DIR=$DR_TOOL_PATH/tmp
DR_OUT_DIR=$DR_TOOL_PATH/output
DR_LOG_DIR=$DR_TOOL_PATH/log

DR_NFS_DIR='/mnt/efs/var/vols/itom'
DR_SMARTA_DIR='/opt/sma/smarta-nfs'

ns=$(sudo kubectl get ns | grep itsma | awk {'print $1'});

################################################################################
#####                         SOURCE SERVER BACKUP                         #####
################################################################################
##Suite Backups
##On Master01 with the DR Toolkit installed
function restore_suite() {

    ##Uncompress the backup file to restorable content
    sudo python $DR_BIN_DIR/disaster_recovery/sma_dr_storage/storage_dispatcher.py -t $DR_TMP_DIR -b $DR_OUT_DIR -m restore -f `ls $DR_TOOL_PATH/sma-dr-*.gz`

    ##Restore SUITE Configuration content only
    sudo python $DR_BIN_DIR/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m restore --disable-idol --disable-nfs --disable-attachment

    ##Pause to execute ConfigMap updates
    read -p '''
    MANUAL STEP: Update default config map after import ... 
    In a seperate terminal execute the following:
    sudo kubectl edit cm database-configmap -n $ns -o yaml
    Update the DB information to point back to restored DB Host
    Save the updates, then Press [ENTER] to continue
    '''

    sudo python $DR_BIN_DIR/disaster_recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m restore --disable-idol --disable-config-map --disable-attachment -nfs $DR_NFS_DIR


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
