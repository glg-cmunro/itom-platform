#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for NFS Server host used for HCM on ITOM Platform
# *** For use with systems built from SA Kickstart Template ***
#
#  System Size:
#    CPU: 8
#    RAM: 16 (16384MB)
#    HDD: 50, 200
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)

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
