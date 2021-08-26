#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
#
# Disaster Recovery for SMA-X Suite on ITOM Platform for Schlumberger
#
# PRE-REQ:
#       Expect DR_TMP, DR_OUTPUT directories already exist (created with Backup)
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
DR_BIN_DIR='/opt/smax/2020.11/tools'
DR_TMP_DIR='/opt/glg/fe_dr/tmp'
DR_OUTPUT_DIR='/opt/glg/fe_dr/output'

##AUTOMATION
TGT_NFS_HOST=`kubectl get pv $(kubectl get pv | grep global-volume | awk '{print $1}') -o json | jq -r .spec.nfs.server`
TGT_NFS_GLOBAL_VOL=`kubectl get pv $(kubectl get pv | grep global-volume | awk '{print $1}') -o json | jq -r .spec.nfs.path`
DR_DB_HOST=`kubectl get cm -n $(kubectl get ns | grep itsma | awk '{print $1}') database-configmap -o json | jq -r .data.xruntime_db_host`

##GLG optic-dev
#TGT_NFS_HOST='fs-339aec87.efs.us-east-1.amazonaws.com'
#TGT_NFS_GLOBAL_VOL='/var/vols/itom/itsma/global-volume'

##SLB GKE Prod
#TGT_NFS_HOST='10.12.81.138'
#TGT_NFS_GLOBAL_VOL='/gcp6133_p_nfs01/var/vols/itom/itsma/global-volume'

##SLB GKE Non-Prod
#TGT_NFS_HOST='10.145.240.146'
#TGT_NFS_GLOBAL_VOL='/gcp6133_np_nfs04/var/vols/itom/itsma/global-volume'

################################################################################
#####                         TARGET SERVER RESTORE                        #####
################################################################################
##Suite Backups
##On Master01 with the DR Toolkit installed
function restore_suite() {
    ##Verify pre-requisites with preaction script to ensure all mount points are accessible
    #python /opt/sma/bin/disaster-recovery/sma_dr_executors/dr_preaction.py
    
    ##Shutdown the SUITE before proceeding
    CDFCTL='/opt/smax/2020.05/scripts/cdfctl.sh'
    NS=`kubectl get ns | grep itsma | awk '{print $1}'`
    $CDFCTL runlevel set -l DOWN -n $NS
    
    ##Pause to execute ConfigMap updates
    read -p '''
    EXTERNAL STEP: Verify the SUITE is shutdown ... 
    In a seperate terminal execute the following:
    Restore the Databases
    then Press [ENTER] to continue
    '''
    ##Uncompress the backup file to restorable content
    python3 $DR_BIN_DIR/disaster-recovery/sma_dr_storage/storage_dispatcher.py -t $DR_TMP_DIR -b $DR_OUTPUT_DIR -m restore -f `ls $DR_OUTPUT_DIR/sma-*`
    
    ##Restore SUITE Configuration content only
    sudo python3 $DR_BIN_DIR/disaster-recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m restore --disable-idol --disable-nfs --disable-attachment
    
    ##Pause to execute ConfigMap updates
    read -p '''
    MANUAL STEP: Update default config map after import ... 
    In a seperate terminal execute the following:
    sudo kubectl edit cm database-configmap -n $ns -o yaml
    Update the DB information to point back to restored DB Host
    Save the updates, then Press [ENTER] to continue
    '''
    
    ##Restore SUITE NFS content only
    sudo mkdir -p $TGT_NFS_GLOBAL_VOL; sudo chown -R 1999:1999 $TGT_NFS_GLOBAL_VOL
    sudo mount -t nfs $TGT_NFS_HOST:$TGT_NFS_GLOBAL_VOL $TGT_NFS_GLOBAL_VOL
    
    sudo python3 $DR_BIN_DIR/disaster-recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m restore --disable-idol --disable-config-map --disable-attachment
    
    ##Restore Attachments
    sudo python3 $DR_BIN_DIR/disaster-recovery/sma_dr_executors/dr_dispatcher.py -t $DR_TMP_DIR -m restore --disable-nfs --disable-config-map --disable-idol
    
    sudo umount $TGT_NFS_GLOBAL_VOL
    
    ##Pause to bring SUITE back up
    read -p '''
    MANUAL STEP: Restart the SUITE and wait for it to be ready ... 
    In a seperate terminal execute the following:
    /opt/kubernetes/scripts/cdfctl.sh runlevel set -l UP -n $NS
    
    Once the SUITE is ready, Press [ENTER] to finish the restore ...
    '''
    $CDFCTL runlevel set -l UP -n $NS
    
}

#Cleanup all file more than 7 days
#find $DR_OUTPUT_DIR -maxdepth 1 -type f -mtime +7 -name '*.tar.gz' -exec rm {} \;

restore_suite
