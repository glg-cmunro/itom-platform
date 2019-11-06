#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for CDF Master host used for HCM on ITOM Platform
# *** For use with systems built from SA Kickstart Template ***
#
#  System Size:
#    CPU: 4
#    RAM: 12 (12288MB)
#    HDD: 60, 100, 100
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)
HOST_NFS=slcvp-hcm-n01.prd.glg.lcl
HOST_POSTGRES=slcvp-hcm-d01.prd.glg.lcl
HOST_VERTICA=slcvp-hcm-v01.prd.glg.lcl
HOST_MASTER01=slcvp-hcm-m01.prd.glg.lcl
HOST_WORKER01=slcvp-hcm-w01.prd.glg.lcl
HOST_WORKER02=slcvp-hcm-w02.prd.glg.lcl
HOST_WORKER03=slcvp-hcm-w03.prd.glg.lcl
EXT_HOSTNAME=hcm.gitops.com

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry
if [ `grep $IPADDR /etc/hosts -c` -eq 0 ]; then
  echo Updating /etc/hosts with Host IP: $IPADDR
  sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
  sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts
  sed -i "/::1/c\#::1\tlocalhost6 localhost6.localdomain6" /etc/hosts
else
  echo /etc/hosts already contains $IPADDR - NO ACTION
fi


################################################################################
#####                      ITOM PLATFORM INSTALLATION                      #####
################################################################################
## Copy CDF Installation bits to Master in /tmp
mkdir -p /tmp/sInstall/images
## Copy HCM Metadata .tgz to Master in /tmp/sInstall
## Create Silent Install file 'hcm-silentInstall-config.json' in /tmp/sInstall


cd /tmp
unzip CDF1908-00132-15001-installer.zip
unzip ITOM_Suite_Foundation_2019.08.00132.zip
/tmp/ITOM_Suite_Foundation_2019.08.00132/tools/generate-download/generate_download_bundle.sh -s hcm -m /tmp/sInstall/hcm-2019.08-metadata.tgz -c /tmp/sInstall/hcm-silentInstall-config.json

cd /tmp/sInstall
unzip /tmp/ITOM_Suite_Foundation_2019.08.00132/tools/generate-download/offline-download.zip
/tmp/sInstall/offline-download/downloadimages.sh -d /tmp/sInstall/images -u jcthepcguy -p Cmandm42181 -y

/tmp/ITOM_Suite_Foundation_2019.08.00132/install -m /tmp/sInstall/hcm-2019.08-metadata.tgz -c /tmp/sInstall/hcm-silentInstall-config.json -P Gr33nl1ght_ --nfs-server slcvp-hcm-n01.prd.glg.lcl --nfs-folder /var/vols/itom/cdf/itom-vol-claim -e suite -i /tmp/sInstall/images

#sed -e "/#THINPOOL_DEVICE=\"\"/c\THINPOOL_DEVICE=\"/dev/mapper/docker-thinpool\"" -i ./install.properties
#./install -m ../hcm-2019.08-metadata.tgz --nfs-server slcvp-hcm-n01.prd.glg.lcl --nfs-folder /var/vols/itom/core -p ./install.properties





##POSSIBLE Way to create the silent install config.json using parameters....
cat <<EOT > /tmp/sInstall/hcm-silentInstall-config.json
{
    "capabilities": {
        "configuration": [
            {
                "suite": {
                    "suite-content": {
                        "container": true,
                        "databases": true,
                        "monitoring": true,
                        "network": true,
                        "compute": true,
                        "it_service_management": true,
                        "middleware": true,
                        "applications": true
                    },
                    "suite-vertica": {
                        "type": "vertica",
                        "expanded-type": "",
                        "isInternal": false,
                        "password": "dbadmin",
                        "dbname": "hcmdb",
                        "port": 5433,
                        "host": "slcvp-hcm-v01.prd.glg.lcl",
                        "hosts": "slcvp-hcm-v01.prd.glg.lcl",
                        "servicename": "",
                        "initialize": false,
                        "user": "dbadmin"
                    },
                    "suite-deployment": {
                        "type": "install"
                    },
                    "suite-sso": {
                        "token": "9db7d02e0d21804975030b16c2582aed"
                    },
                    "suite-mpp": {
                        "port": 8089
                    },
                    "suite-login": {
                        "codarIntegrationUser": "Gr33nl1ght_",
                        "consumerAdmin": "Gr33nl1ght_",
                        "admin": "Gr33nl1ght_",
                        "UISysadmin": "Gr33nl1ght_",
                        "ooInboundUser": "Gr33nl1ght_",
                        "idmTransportUser": "Gr33nl1ght_",
                        "csaTransportUser": "Gr33nl1ght_",
                        "csaReportingUser": "Gr33nl1ght_",
                        "csbTransportUser": "Gr33nl1ght_",
                        "sysadmin": "Gr33nl1ght_",
                        "consumer": "Gr33nl1ght_"
                    },
                    "suite-database": {
                        "oo": {
                            "type": "postgres",
                            "expanded-type": "postgresql",
                            "host": "slcvp-hcm-d01.prd.glg.lcl",
                            "hosts": "",
                            "port": "5432",
                            "user": "hcmadmin",
                            "password": "Gr33nl1ght_",
                            "dbname": "oo",
                            "isInternal": false,
                            "initialize": true,
                            "servicename": ""
                        },
                        "ucmdb": {
                            "type": "postgres",
                            "expanded-type": "postgresql",
                            "host": "slcvp-hcm-d01.prd.glg.lcl",
                            "hosts": "",
                            "port": "5432",
                            "user": "hcmadmin",
                            "password": "Gr33nl1ght_",
                            "dbname": "ucmdb",
                            "isInternal": false,
                            "initialize": true,
                            "servicename": ""
                        },
                        "autopass": {
                            "type": "postgres",
                            "expanded-type": "postgres",
                            "host": "slcvp-hcm-d01.prd.glg.lcl",
                            "hosts": "",
                            "port": "5432",
                            "user": "hcmadmin",
                            "password": "Gr33nl1ght_",
                            "dbname": "autopass",
                            "isInternal": false,
                            "initialize": true,
                            "servicename": ""
                        },
                        "oodesigner": {
                            "type": "postgres",
                            "expanded-type": "postgresql",
                            "host": "slcvp-hcm-d01.prd.glg.lcl",
                            "hosts": "",
                            "port": "5432",
                            "user": "hcmadmin",
                            "password": "Gr33nl1ght_",
                            "dbname": "oodesigner",
                            "isInternal": false,
                            "initialize": true,
                            "servicename": ""
                        },
                        "csa": {
                            "type": "postgres",
                            "expanded-type": "postgresql",
                            "host": "slcvp-hcm-d01.prd.glg.lcl",
                            "hosts": "",
                            "port": "5432",
                            "user": "hcmadmin",
                            "password": "Gr33nl1ght_",
                            "dbname": "csa",
                            "isInternal": false,
                            "initialize": true,
                            "servicename": ""
                        },
                        "ara": {
                            "type": "postgres",
                            "expanded-type": "postgresql",
                            "host": "slcvp-hcm-d01.prd.glg.lcl",
                            "hosts": "",
                            "port": "5432",
                            "user": "hcmadmin",
                            "password": "Gr33nl1ght_",
                            "dbname": "ara",
                            "isInternal": false,
                            "initialize": true,
                            "servicename": ""
                        }
                    }
                }
            }
        ],
        "capabilitySelection": [
            { "name": "csa-cap" },
            { "name": "oo-cap" },
            { "name": "co-cap" },
            { "name": "ucmdb-cap" },
            { "name": "codar-cap" },
            { "name": "dma-cap" },
            { "name": "broker-cap" },
            { "name": "showback-cap" },
            { "name": "governance-cap" }
        ],
        "edition": "ULTIMATE",
        "version": "2019.08-156",
        "suite": "hcm",
        "installSize": "MEDIUM"
    },
    "workerNodes": [
        {
            "skipWarning": true,
            "thinpoolDevice": "/dev/mapper/docker-thinpool,/dev/mapper/bootstrap_docker-thinpool",
            "skipResourceCheck": true,
            "hostname": "slcvp-hcm-w01.prd.glg.lcl",
            "flannelIface": "",
            "user": "root",
            "password": "gr33nl!ght",
            "type": "standard"
        },
        {
            "skipWarning": true,
            "thinpoolDevice": "/dev/mapper/docker-thinpool,/dev/mapper/bootstrap_docker-thinpool",
            "skipResourceCheck": true,
            "hostname": "slcvp-hcm-w02.prd.glg.lcl",
            "flannelIface": "",
            "user": "root",
            "password": "gr33nl!ght",
            "type": "standard"
        },
        {
            "skipWarning": true,
            "thinpoolDevice": "/dev/mapper/docker-thinpool,/dev/mapper/bootstrap_docker-thinpool",
            "skipResourceCheck": true,
            "hostname": "slcvp-hcm-w03.prd.glg.lcl",
            "flannelIface": "",
            "user": "root",
            "password": "gr33nl!ght",
            "type": "standard"
        }
    ],
    "volumes": [
        {
            "host": "slcvp-hcm-n01.prd.glg.lcl",
            "name": "itom-vol-claim",
            "path": "/var/vols/itom/cdf/itom-vol-claim",
            "type": "NFS"
        },
        {
            "host": "slcvp-hcm-n01.prd.glg.lcl",
            "name": "hcm-vol-claim",
            "path": "/var/vols/itom/hcm",
            "type": "NFS"
        },
        {
            "host": "slcvp-hcm-n01.prd.glg.lcl",
            "name": "itom-logging-vol",
            "path": "/var/vols/itom/cdf/itom-logging-vol",
            "type": "NFS"
        },
        {
            "host": "slcvp-hcm-n01.prd.glg.lcl",
            "name": "db-backup-vol",
            "path": "/var/vols/itom/cdf/db-backup-vol",
            "type": "NFS"
        }
    ],
    "licenseAgreement": {
        "eula": true,
        "callHome": false
    },
    "database": {
        "type": "extpostgres",
        "param": {
            "dbHost": "slcvp-hcm-d01.prd.glg.lcl",
            "dbPort": "5432",
            "dbName": "cdfidmdb",
            "dbUser": "cdfidmuser",
            "dbPassword": "Gr33nl1ght_",
            "highAvailability": false
        }
    },
    "useCustomizedCert": false,
    "masterHA": false,
    "masterNodes": [],
    "allowWorkerOnMaster": false,
    "connection": {
        "port": "443",
        "externalHostname": "hcm.gitops.com"
    }
}
EOT
