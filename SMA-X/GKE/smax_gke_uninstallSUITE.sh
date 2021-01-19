NFS_BASE_PATH='/mnt/nfs/var/vols/itom'
JQ=`sudo ls /opt/smax/*/bin/jq | head -n 1`
SUITE_VERSION=`sudo kubectl get cm -n core base-configmap -o json | sudo $JQ -r .data."PLATFORM_VERSION"`
#SUITE_VERSION='2019.05.00131'
#SUITE_VERSION='2019.08.00134'
#SUITE_VERSION='2020.02.00119'

## Uninstall SMAX SUITE:

## Delete ITSMA Namespace
echo "Deleting ITSMA Namespace"
sudo kubectl get namespaces|grep itsma|head -n 1|awk '{print $1}'| xargs sudo kubectl delete ns

## Delete ITSMA Persistent Volumes
echo "Deleting ITSMA Persisten Volumes"
sudo kubectl get pv | grep itsma | awk '{print $1}'|xargs sudo kubectl delete pv

### Uninstall CDF - GKE
echo "Removing RBAC Configuration"
sudo kubectl delete -f /opt/smax/$SUITE_VERSION/objectdefs/rbac-config.yaml

## Delete Core Namespace
echo "Deleting CORE Namespace"
sudo kubectl delete ns core --grace-period=0 --force

## Delete ITSMA Persistent Volumes
echo "Deleting ITOM Persisten Volumes"
sudo kubectl get pv | grep itom | awk '{print $1}'|xargs sudo kubectl delete pv

## Clear out NFS Directories
echo "Clearing NFS Directories"
sudo rm -rf $NFS_BASE_PATH/core/*
sudo rm -rf $NFS_BASE_PATH/itsma/*/*

'''
db-backup-vol
db-volume
db-volume-1
db-volume-2
global-volume
itom-logging-vol
itsma-smarta-sawarc-con-0
itsma-smarta-sawarc-con-1
itsma-smarta-sawarc-con-2
itsma-smarta-sawarc-con-3
itsma-smarta-sawarc-con-4
itsma-smarta-sawarc-con-5
itsma-smarta-sawarc-con-a-0
itsma-smarta-sawarc-con-a-1
itsma-smarta-sawarc-con-a-2
itsma-smarta-sawarc-con-a-3
itsma-smarta-sawarc-con-a-4
itsma-smarta-sawarc-con-a-5
itsma-smarta-saw-con-0
itsma-smarta-saw-con-1
itsma-smarta-saw-con-2
itsma-smarta-saw-con-3
itsma-smarta-saw-con-4
itsma-smarta-saw-con-5
itsma-smarta-saw-con-a-0
itsma-smarta-saw-con-a-1
itsma-smarta-saw-con-a-2
itsma-smarta-saw-con-a-3
itsma-smarta-saw-con-a-4
itsma-smarta-saw-con-a-5
itsma-smarta-sawmeta-con-0
itsma-smarta-sawmeta-con-1
itsma-smarta-sawmeta-con-a-0
itsma-smarta-sawmeta-con-a-1
rabbitmq-infra-rabbitmq-0
rabbitmq-infra-rabbitmq-1
rabbitmq-infra-rabbitmq-2
smartanalytics-volume
'''

### Database Cleanup (Note replace postgres with the dbadmin user)
psql -U postgres -h 10.4.176.5 "sslmode=require sslrootcert=/home/jjr109_slb_com/server-ca.pem sslcert=/home/jjr109_slb_com/controlNodeDBCert.pem sslkey=/home/jjr109_slb_com/controlNodeDBKey.pem"

##If you drop the databases and roles, you need to recreate them before installing
GRANT maas_admin TO postgres;
drop database autopassdb;
drop database bo_ats;
drop database bo_config;
drop database bo_license;
drop database bo_user;
drop database idm;
drop database maas_admin;
drop database maas_template;
drop database smartadb;
drop database xservices_ems;
drop database xservices_mng;
drop database xservices_rms;
drop database suitedb;
drop database cdfapiserverdb;
drop role maas_admin;
drop role bo_db_user;
drop role smarta;
drop role idm;
drop role autopass;
drop role cdfidm;
create database cdfapiserverdb WITH owner=cdfapiserver;
