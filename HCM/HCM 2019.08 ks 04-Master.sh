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
#HOST_NFS=slcvp-hcm-n01.prd.glg.lcl
#HOST_POSTGRES=slcvp-hcm-d01.prd.glg.lcl
#HOST_VERTICA=slcvp-hcm-v01.prd.glg.lcl
#HOST_MASTER01=slcvp-hcm-m01.prd.glg.lcl
#HOST_WORKER01=slcvp-hcm-w01.prd.glg.lcl
#HOST_WORKER02=slcvp-hcm-w02.prd.glg.lcl
#HOST_WORKER03=slcvp-hcm-w03.prd.glg.lcl
#EXT_HOSTNAME=hcm.gitops.com

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
mv /tmp/hcm-*.tgz /tmp/sInstall
## Create Silent Install file 'hcm-silentInstall-config.json' in /tmp/sInstall


cd /tmp
unzip CDF1908-00132-15001-installer.zip
unzip ITOM_Suite_Foundation_2019.08.00132.zip
/tmp/ITOM_Suite_Foundation_2019.08.00132/tools/generate-download/generate_download_bundle.sh -s hcm -m /tmp/sInstall/hcm-2019.08-metadata.tgz -c /tmp/sInstall/hcm-silentInstall-config.json

cd /tmp/sInstall
unzip /tmp/ITOM_Suite_Foundation_2019.08.00132/tools/generate-download/offline-download.zip
/tmp/sInstall/offline-download/downloadimages.sh -d /tmp/sInstall/images -u jcthepcguy -p Cmandm42181 -y

/tmp/ITOM_Suite_Foundation_2019.08.00132/install -m /tmp/sInstall/hcm-2019.08-metadata.tgz -c /tmp/sInstall/hcm-silentInstall-config.json -P Gr33nl1ght_ --nfs-server slcvu-hcm-n01.uat.glg.lcl --nfs-folder /var/vols/itom/cdf/itom-vol-claim -e suite -i /tmp/sInstall/images --skip-warning -t 180
