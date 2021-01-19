#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Clean and Worker Server for reinstallation of HCM on ITOM Platform
#

##Uninstall Kubernetes
/opt/kubernetes/uninstall.sh -y

##Reboot

##Clear out TMP directory if artifacts remain
rm -rf /tmp/ITOM_Suite_Foundation_Node*
rm -rf /tmp/kubernetes.*
rm -rf /tmp/nodec*

echo vm.max_map_count=262144 >> /etc/sysctl.conf
sysctl -p

##Clean Thinpool