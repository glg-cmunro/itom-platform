##List configurations



## Production
gcloud config configurations activate slb-gke-p
gcloud compute start-iap-tunnel gcp6133prdapp01 22 --local-host-port=localhost:22001


## Non-Prod
gcloud config configurations activate slb-gke-np
gcloud compute start-iap-tunnel gcp6133tstapp04 22 --local-host-port=localhost:22002




##DR
curl -k https://owncloud.greenlightgroup.com/index.php/s/9DotY6EJsYcovlY/download -output SMA_Operation_Toolkit_2020.11.zip
unzip SMA_Operation_Toolkit_2020.11.zip
mkdir /opt/smax/2020.11/tools/disaster-recovery

mv SMA-disaster-recovery-2020.11.tar.gz /opt/smax/2020.11/tools/disaster-recovery/
cd /opt/smax/2020.11/tools/disaster-recovery
tar -zxvf SMA-disaster-recovery-2020.11.tar.gz

/opt/smax/2020.11/smax_2020.11_dr_restoreSUITE.sh

python3 dr_preaction.py
