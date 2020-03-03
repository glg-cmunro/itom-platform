#!/bin/bash
#
# AUTHOR : chris@greenlightgroup.com
# 
# System prep for Vertica DB host used for HCM on ITOM Platform
# *** For use with systems built from SA Kickstart Template ***
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
VDB_PKG=MicroFocus_HCM_2019_08_Vertica_Installation.zip
VDB_RPM=vertica-9.2.0-7.x86_64.RHEL6.rpm

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

groupadd verticadba
useradd dbadmin -g verticadba

##COPY Vertica Bits to Server - place in /tmp
##Install steps from MF Docs
cd /tmp
unzip $VDB_PKG
rpm -Uvh $VDB_RPM
/opt/vertica/sbin/install_vertica --hosts `hostname -f` --rpm $VDB_RPM --dba-user dbadmin --data-dir /opt/vertica --accept-eula --license /tmp/itom-hcm.key

su - dbadmin
##Install License Key itom-hcm.key
#/opt/vertica/bin/adminTools


/opt/vertica/bin/adminTools -t create_db -d hcmdb -p dbadmin --hosts=`hostname -f` --policy=always
/opt/vertica/bin/adminTools -t logrotate -d hcmdb -r daily -k7

###SSL SETUP

##ECHO SSL CA Cert Request Config to file
cat <<EOT > openssl_req_CA.conf
# OpenSSL configuration to generate a new key with signing requst for a x509v3 
[ req ]
default_bits       = 4096
prompt             = no
distinguished_name = VDB_CACert
req_extensions     = v3_req

# extensions
[ VDB_CACert ]
countryName            = "US"                                 # C=
stateOrProvinceName    = "UT"                                 # ST=
localityName           = "West Jordan"                        # L=
organizationName       = "Greenlight Group, LLC."             # O=
organizationalUnitName = "GLG IT - CA Cert"                   # OU=
commonName             = "HCM Vertica CACert - `hostname -f`" # CN=

[ v3_req ]
basicConstraints    = CA:TRUE
subjectAltName      = @alt_names

[ alt_names ]
DNS.1   = `hostname -f`
DNS.2   = `hostname`
DNS.3   = *.`hostname -d`
IP      = `hostname -i`
EOT

##CREATE CA CERT for Vertica
openssl genrsa -out servercakey.pem
openssl req -config openssl_req_CA.conf -new -x509 -key servercakey.pem -out serverca.crt 

##ECHO SSL Server Cert Request Config to file
cat <<EOT > openssl_req_server.conf
[ req ]
prompt             = no
req_extensions     = v3_req
distinguished_name = VDB_Server
policyConstraints = requireExplicitPolicy:3

[ VDB_Server ]
countryName            = "US"                     # C=
stateOrProvinceName    = "Utah"                   # ST=
localityName           = "West Jordan"            # L=
organizationName       = "Greenlight Group, LLC." # O=
organizationalUnitName = "GLG IT - Server Cert"   # OU=
commonName             = "`hostname -f`"          # CN=

[ v3_req ]
basicConstraints    = CA:FALSE
policyConstraints = requireExplicitPolicy:3
keyUsage            = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName      = @alt_names

[ alt_names ]
DNS.1   = `hostname -f`
DNS.2   = `hostname`
DNS.3   = *.`hostname -d`
IP      = `hostname -i`
EOT

##CREATE SERVER CERT for Vertica
openssl genrsa -out server.key
openssl req -config openssl_req_server.conf -new -key server.key -out server_reqout.txt
openssl x509 -req -in server_reqout.txt -days 3650 -sha256 -CAcreateserial -CA serverca.crt -CAkey servercakey.pem -out server.crt

##Add SSL Private Key and Cert to Vertica Database
vsql -U dbadmin -w dbadmin -c "SELECT SET_CONFIG_PARAMETER('SSLPrivateKey','`cat server.key`');"
vsql -U dbadmin -w dbadmin -c "SELECT SET_CONFIG_PARAMETER('SSLCertificate','`cat server.crt`');"
vsql -U dbadmin -w dbadmin -c "SELECT SET_CONFIG_PARAMETER('EnableSSL','1');"

##STOP and RESTART Vertica Database
/opt/vertica/bin/adminTools -t stop_db -d hcmdb -p dbadmin -F
/opt/vertica/bin/adminTools -t start_db -d hcmdb -p dbadmin -F
