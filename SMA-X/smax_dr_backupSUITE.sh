#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Disaster Recovery for SMA-X Suite on ITOM Platform for Schlumberger
#

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

backup_suite
