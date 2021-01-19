#!/bin/bash
# ============================================================================ #
#
# title       :
# description : 
# author      : chris@greenlightgroup.com
# version     : v2.1
# date        : 
# notes       : To clean up and reuse the Vertica DB Server with a new install
#               Need to drop the HCMDB Vertica Database and re-create it
#               Need to re-add the SSL Certificates and re-enable SSL
#
# ============================================================================ #
<< COMMENT
    *** For use with systems built from SA Kickstart Template 20191101 ***
     HCM Suite: 2019.08-156
     Vertica DB Version: 9.2.0-7
COMMENT 

su - dbadmin

##Drop the existing HCM Database
/opt/vertica/bin/adminTools -t stop_db -d hcmdb -p dbadmin -F
/opt/vertica/bin/adminTools -t drop_db -d hcmdb

##Create new HCM Database
/opt/vertica/bin/adminTools -t create_db \
-d hcmdb -p dbadmin --hosts=`hostname -f` --policy=always
/opt/vertica/bin/adminTools -t logrotate -d hcmdb -r daily -k7

##Install the SSL Certificates and Enable SSL
vsql -U dbadmin -w dbadmin -c \
"SELECT SET_CONFIG_PARAMETER('SSLPrivateKey','`cat server.key`');"
vsql -U dbadmin -w dbadmin -c \
"SELECT SET_CONFIG_PARAMETER('SSLCertificate','`cat server.crt`');"
vsql -U dbadmin -w dbadmin -c \
"SELECT SET_CONFIG_PARAMETER('EnableSSL','1');"

/opt/vertica/bin/adminTools -t stop_db -d hcmdb -p dbadmin -F
/opt/vertica/bin/adminTools -t start_db -d hcmdb -p dbadmin -F
