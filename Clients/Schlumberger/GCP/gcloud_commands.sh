################################################################################
#####                       GCloud SDK Commands List                       #####
################################################################################

#LOGIN to GCloud environment
gcloud init
gcloud auth login

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

## Non-Prod
gcloud config configurations activate slb-gke-np
gcloud compute start-iap-tunnel gcp6133tstapp04 22 --local-host-port=localhost:22004 --zone=europe-west1-b --project=us107795-np-sis-bsys-6133
gcloud compute start-iap-tunnel gcp6133tstapp05 3389 --local-host-port=localhost:53389 --zone=europe-west1-b --project=us107795-np-sis-bsys-6133



##DR
# EVT: 
curl -k https://owncloud.greenlightgroup.com/index.php/s/9DotY6EJsYcovlY/download -o SMA_Operation_Toolkit_2020.11.zip
unzip SMA_Operation_Toolkit_2020.11.zip
mkdir -p /opt/smax/2020.11/tools/disaster-recovery

mv SMA-disaster-recovery-2020.11.tar.gz /opt/smax/2020.11/tools/disaster-recovery/
cd /opt/smax/2020.11/tools/disaster-recovery
tar -zxvf SMA-disaster-recovery-2020.11.tar.gz

/opt/smax/2020.11/smax_2020.11_dr_restoreSUITE.sh

python3 dr_preaction.py





