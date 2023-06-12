################################################################################
#####                       GCloud SDK Commands List                       #####
################################################################################

#Install gcloud sdk
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-423.0.0-linux-x86_64.tar.gz
tar -xf google-cloud-cli-423.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh --quiet --additional-components gke-gcloud-auth-plugin --path-update true

#kubectl exec -ti -n gitops $(kubectl get pods -n gitops --no-headers | awk {'print $1'}) -c monitoring -- bash


#LOGIN to GCloud environment
gcloud init
gcloud auth login

## For Activation in MobaXTerm
gcloud auth login --no-launch-browser

## List configurations
gcloud config configurations list

## Get Compute Instances from current config
gcloud compute instances list

## Set the active project
gcloud config configurations activate slb-gke-np
gcloud config configurations activate slb-gke-p


## Production
gcloud config configurations activate slb-gke-p
gcloud compute start-iap-tunnel gcp6133prdapp01 22 --local-host-port=localhost:22001 --zone=europe-west1-b --project=us102173-p-sis-bsys-6133
gcloud compute start-iap-tunnel gcp6133prdapp02 3389 --local-host-port=localhost:23389 --zone=europe-west1-b --project=us102173-p-sis-bsys-6133

gcloud compute ssh gcp6133prdapp01

## Non-Prod
gcloud config configurations activate slb-gke-np
gcloud compute start-iap-tunnel gcp6133tstapp04 22 --local-host-port=localhost:22004 --zone=europe-west1-b --project=us107795-np-sis-bsys-6133
gcloud compute start-iap-tunnel gcp6133tstapp05 3389 --local-host-port=localhost:53389 --zone=europe-west1-b --project=us107795-np-sis-bsys-6133



##DR
curl -k https://owncloud.greenlightgroup.com/index.php/s/9DotY6EJsYcovlY/download -o SMA_Operation_Toolkit_2020.11.zip
unzip SMA_Operation_Toolkit_2020.11.zip
mkdir -p /opt/smax/2020.11/tools/disaster-recovery

mv SMA-disaster-recovery-2020.11.tar.gz /opt/smax/2020.11/tools/disaster-recovery/
cd /opt/smax/2020.11/tools/disaster-recovery
tar -zxvf SMA-disaster-recovery-2020.11.tar.gz

/opt/smax/2020.11/smax_2020.11_dr_restoreSUITE.sh

python3 dr_preaction.py


gcrpwd=$(gcloud auth print-access-token)
sudo python3 /opt/smax/2020.11/scripts/smax-image-transfer.py -sr registry.hub.docker.com -su dockerhubglg -sp Gr33nl1ght_ -so hpeswitom -tr 'gcr.io' -tu oauth2accesstoken -tp $gcrpwd -to us107795-np-sis-bsys-6133 -p /opt/smax/offline-download/image-set.json


# Add Kubeconfig for access to Cluster
gcloud container clusters get-credentials --region europe-west1 smaxgke1905
gcloud container clusters get-credentials --region europe-west1 gcp6133-p-k8s01
gcloud container clusters get-credentials --region europe-west1 gcp6133-p-k8s02
gcloud container clusters get-credentials --region europe-west1 gcp6133-dr-k8s01

gcloud container clusters get-credentials --region $REGION $SMAX_CLUSTER


Change FQDN:
./fqdn-replace.sh -nf www.ccc3.evt.slb.com -of ccc.greenlightgroup.com -nd slb.com -od greenlightgroup.com -u admin -p GbGeRv2oozgZv0Ei71a! -c ../../../resource/cccevt.cer -k ../../../resource/cccevtNew.key -t ../../../resource/cccevt_inter.cer -y -o
/var/toolkit/config/toolkit/toolkit/change_fqdn/

fqdn-replace.sh was trying to use helm and SLB cluster does not have apphub deployed - have to comment out the lines that include a call to the helm update commands

#Reset Windows RDP user password
gcloud beta compute --project "us102173-p-sis-bsys-6133" reset-windows-password "gcp6133prdapp02" --zone "europe-west1-b" --user jjr109
gcloud beta compute --project "us107795-np-sis-bsys-6133" reset-windows-password "gcp6133tstapp05" --zone "europe-west1-b" --user jjr109

gcloud beta compute --project "us107795-np-sis-bsys-6133" reset-windows-password "gcp6133tstapp05" --zone "europe-west1-b" --user bbowden2