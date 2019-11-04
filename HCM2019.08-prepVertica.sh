#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for Vertica DB host used for HCM on ITOM Platform
#
#  System Size:
#    CPU: 8
#    RAM: 32 (32768MB)
#    HDD: 50, 200
#

################################################################################
#####                           GLOBAL VARIABLES                           #####
################################################################################
IPADDR=$(ip address show scope global | grep 'inet' | head -n 1 | awk '{print $2}' | cut -d "/" -f 1)
ROOT_LVM_DEVICE=/dev/mapper/centos_glg--centos7-root

VDB_DEVICE=/dev/sdb
VDB_PART=1
VDB_VG=vertica
VDB_LV=vertica_lv
VDB_MP=/opt/vertica

# Hostname resolution and IP Address assignment
#Fix /etc/hosts entry from VMware adding hostname as 127.0.1.1
sed -i "s/127.0.1.1/$IPADDR/g" /etc/hosts
sed -i -e "1i$(head -$(grep -n $IPADDR /etc/hosts | awk -F: '{print $1}') /etc/hosts | tail -1)" -e "$(grep -n $IPADDR /etc/hosts | grep -v 1: | awk -F: '{print $1}')d" /etc/hosts
sed -i "/::1/c\::1\tlocalhost6 localhost6.localdomain6" /etc/hosts

## Add 1GB of Swap Space using swapfile
dd if=/dev/zero of=/swapfile bs=1024 count=1048576
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

################################################################################
#####                      SYSTEM DISK INFRASTRUCTURE                      #####
################################################################################
## Resize root disk if necessary
echo "d
2
n
p
2


t
2
8e
w
"|fdisk /dev/sda
partprobe
pvresize /dev/sda2
lvextend -l +100%FREE $ROOT_LVM_DEVICE
xfs_growfs $ROOT_LVM_DEVICE

## /var/vols/itom filesystem setup ##
echo "n
p
1


w
"|fdisk $VDB_DEVICE

pvcreate $VDB_DEVICE$VDB_PART
vgcreate $VDB_VG $VDB_DEVICE$VDB_PART
lvcreate -l +100%FREE -n $VDB_LV $VDB_VG

changevg -a y $VDB_VG
mkfs -t ext4 /dev/$VDB_VG/$VDB_LV

mkdir -p $VDB_MP
mount /dev/$VDB_VG/$VDB_LV $VDB_MP
echo "/dev/mapper/$VDB_VG-$VDB_LV $VDB_MP ext4 defaults 0 0" >> /etc/fstab



##Install required  software for Vertica DB Server
yum install -y dialog mcelog gstack mpstat iostat

groupadd verticadba
useradd dbadmin -g verticadba

su - dbadmin

##ECHO SSL CA Cert Request Config to file
cat <<EOT > openssl_req_CA.conf
# OpenSSL configuration to generate a new key with signing requst for a x509v3 
[ req ]
default_bits       = 4096
default_md         = sha512
default_keyfile    = key.pem
prompt             = no
encrypt_key        = no

# base request
distinguished_name = req_distinguished_name

# extensions
req_extensions     = v3_req

# distinguished_name
[ req_distinguished_name ]
countryName            = "US"                     # C=
stateOrProvinceName    = "Utah"                   # ST=
localityName           = "West Jordan"            # L=
organizationName       = "Greenlight Group, LLC." # O=
organizationalUnitName = "GLG IT"                 # OU=
commonName             = "`hostname -f`"          # CN=
EOT

##CREATE CA CERT for Vertica
openssl genrsa -out servercakey.pem
#openssl req -config openssl_req_CA.conf -new -x509 -key servercakey.pem -out serverca.crt 
openssl req -new -x509 -key servercakey.pem -out serverca.crt 

##ECHO SSL Server Cert Request Config to file
cat <<EOT > openssl_req_server.conf
# OpenSSL configuration to generate a new key with signing requst for a x509v3 
[ req ]
default_bits       = 4096
default_md         = sha512
default_keyfile    = key.pem
prompt             = no
encrypt_key        = no

# base request
distinguished_name = req_distinguished_name

# extensions
req_extensions     = v3_req

# distinguished_name
[ req_distinguished_name ]
countryName            = "US"                     # C=
stateOrProvinceName    = "Utah"                   # ST=
localityName           = "West Jordan"            # L=
postalCode             = "84088"                  # L/postalcode=
streetAddress          = "8846 S. Redwood Road"   # L/street=
organizationName       = "Greenlight Group, LLC." # O=
organizationalUnitName = "GLG IT"                 # OU=
commonName             = "`hostname -f`"          # CN=
emailAddress           = "webmaster@greenlightgroup.com"  # CN/emailAddress=

# req_extensions
[ v3_req ]
# The subject alternative name extension allows various literal values to be 
# included in the configuration file
# http://www.openssl.org/docs/apps/x509v3_config.html
#subjectAltName  = DNS:www.example.com,DNS:www2.example.com # multidomain certificate

# vim:ft=config
EOT

##CREATE SERVER CERT for Vertica
openssl genrsa -out server.key
#openssl req -config openssl_req_server.conf -new -key server.key -out server_reqout.txt
openssl req -new -key server.key -out server_reqout.txt
openssl x509 -req -in server_reqout.txt -days 3650 -sha1 -CAcreateserial -CA serverca.crt -CAkey servercakey.pem -out server.crt

##ECHO SSL Client Cert Request Config to file
cat <<EOT > openssl_req_client.conf
# OpenSSL configuration to generate a new key with signing requst for a x509v3 
[ req ]
default_bits       = 4096
default_md         = sha512
default_keyfile    = key.pem
prompt             = no
encrypt_key        = no

# base request
distinguished_name = req_distinguished_name

# extensions
req_extensions     = v3_req

# distinguished_name
[ req_distinguished_name ]
countryName            = "US"                     # C=
stateOrProvinceName    = "Utah"                   # ST=
localityName           = "West Jordan"            # L=
postalCode             = "84088"                  # L/postalcode=
streetAddress          = "8846 S. Redwood Road"   # L/street=
organizationName       = "Greenlight Group, LLC." # O=
organizationalUnitName = "GLG IT"                 # OU=
commonName             = "`hostname -f`"          # CN=
emailAddress           = "webmaster@greenlightgroup.com"  # CN/emailAddress=

# req_extensions
[ v3_req ]
# The subject alternative name extension allows various literal values to be 
# included in the configuration file
# http://www.openssl.org/docs/apps/x509v3_config.html
#subjectAltName  = DNS:www.example.com,DNS:www2.example.com # multidomain certificate

# vim:ft=config
EOT

##CREATE CLIENT CERT for Vertica
openssl genrsa -out client.key
#openssl req -config openssl_req_client.conf -new -key client.key -out client_reqout.txt
openssl req -new -key client.key -out client_reqout.txt
openssl x509 -req -in client_reqout.txt -days 3650 -sha1 -CAcreateserial -CA serverca.crt -CAkey servercakey.pem -out client.crt

################################################################################
#####                     SYSTEM / SECURITY / FIREWALL                     #####
################################################################################
# Ensure Firewalld is set to disabled and stopped
systemctl disable firewalld
systemctl stop firewalld
