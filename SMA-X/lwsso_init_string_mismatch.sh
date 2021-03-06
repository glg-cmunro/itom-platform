##Issues with login post DR may be due to LWSSO Init String
## Found the issue here to be the LWSSO init string was not in sync from the idm pod to the vault secret
## LWSSO Secret Key:  lwsso_init_string_secret_key

##Run the following as a script – idm.sh – to get the init_string idm is currently using
namespace=`sudo kubectl get ns | grep itsma | awk ‘{print $1}’`
idm_pod=`kubectl get pod -n $namespace -l itsmaService=itom-idm | grep idm | awk '{print $1}'`
tp_string=`kubectl exec -n $namespace $idm_pod -c idm -it  get_secret idm_transport_user_password_secret_key`
idm_transport_user_pass=${tp_string: 5: -1}
echo "Idm transport user passwod: "$idm_transport_user_pass

header="Authorization: Basic "`echo -n "idmTransportUser:"$idm_transport_user_pass| base64`
echo "Idm auth header: "$header

ap_string=`kubectl exec -n $namespace $idm_pod -c idm -it  get_secret idm_admin_password_secret_key`
idm_admin_password=${ap_string: 5: -1}
echo "Idm admin password: "$idm_admin_password

hostname=smax-dev.gitops.com

token=`curl -X POST -H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "$header" \
-d '{"passwordCredentials":{"username" : "admin", "password" : "'$idm_admin_password'"}, "tenantName" : "provider"}\' \
-k https://$hostname/idm-service/v2.0/tokens \
| /opt/kubernetes/bin/jq -r '.["token"]["id"]'`

echo "IDM token: "$token

init_string=`curl -X GET -k https://$hostname/idm-service/api/system/configurations/items/lwssoConfig.initString \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
-H "X-AUTH-TOKEN: $token"`

echo $init_string
Take the lwsso_init_string value and update the secret in vault using bo-ats pod as before
After reset the lwsso init string the following kubectl commands are run to restart all the necessary pods to get the containers using the updated/corrected lwsso init string

sudo kubectl delete pods -n itsma-ugivx  -l idm=reboot
sudo kubectl delete pods -n itsma-ugivx  -l on-sso-change=reboot
sudo kubectl delete pods -n itsma-ugivx  -l app=sm-chat




Finally,  The xruntime-update-tenant pod failed to run – kept crashloopbackoff
With logs showing attempt to access each tenant and stuck on each tenant set to inactive.

Solution:  Record the TENANTID for each inactive tenant, set them all to active
Pod completed successfully and the suite upgrade finished completely
Return each temporarily activated tenant back to inactive

