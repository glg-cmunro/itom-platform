#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# Clean and re-Prep NFS Server reinstallation of HCM on ITOM Platform
#

rm -rf /var/vols/itom/cdf/*/*
rm -rf /var/vols/itom/hcm/*

mkdir -p /var/vols/itom/hcm/certs/ca
scp root@slcvp-hcm-v01.prd.glg.lcl:/home/dbadmin/serverca.crt /var/vols/itom/hcm/certs/ca
chown -R 1999:1999 /var/vols/itom
