#!/bin/bash
# Script Name:  getLWSSOKey.sh

EXT_ACCESS_FQDN=ccc-evd.greenlightgroup.com

NS=`sudo kubectl get ns | grep itsma | awk '{print $1}'`

IDM_POD=`sudo kubectl get pod -n $NS -l itsmaService=itom-idm | grep idm | awk '{print $1}'`

tp_string=`sudo kubectl exec -n $NS $IDM_POD -c idm -it  get_secret idm_transport_user_password_secret_key`

idm_transport_user_pass=${tp_string: 5: -1}

echo "Idm transport user passwod: "$idm_transport_user_pass

header="Authorization: Basic "`echo -n "idmTransportUser:"$idm_transport_user_pass| base64`
echo "Idm auth header: "$header

ap_string=`sudo kubectl exec -n $NS $IDM_POD -c idm -it  get_secret idm_admin_password_secret_key`
idm_admin_password=${ap_string: 5: -1}
echo "Idm admin password: "$idm_admin_password

token=`curl -X POST -H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "$header" \
-d '{"passwordCredentials":{"username" : "admin", "password" : "'$idm_admin_password'"}, "tenantName" : "provider"}\' \
-k https://$EXT_ACCESS_FQDN/idm-service/v2.0/tokens \
| sudo /opt/smax/2019.05/bin/jq -r '.["token"]["id"]'`
echo "IDM token: "$token



init_string=`curl -X GET -k https://$EXT_ACCESS_FQDN/idm-service/api/system/configurations/items/lwssoConfig.initString \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "X-AUTH-TOKEN: $token"`

echo $init_string
