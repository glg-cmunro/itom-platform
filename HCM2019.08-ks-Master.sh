#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for CDF Master host used for HCM on ITOM Platform
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

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts
sed -i "/::1/c\#::1\tlocalhost6 localhost6.localdomain6" /etc/hosts


## TO RUN CDF INSTALLER
## Copy CDF Installation bits to Master and unzip to /tmp
#cd /tmp
#unzip CDF1908-00132-15001-installer.zip
#unzip ITOM_Suite_Foundation_2019.08.00132.zip
#cd /tmp/ITOM_Suite_Foundation_2019.08.00132
#sed -e "/#THINPOOL_DEVICE=\"\"/c\THINPOOL_DEVICE=\"/dev/mapper/docker-thinpool\"" -i ./install.properties
#./install -m ../hcm-2019.08-metadata.tgz --nfs-server slcvp-hcm-n01.prd.glg.lcl --nfs-folder /var/vols/itom/core -p ./install.properties
