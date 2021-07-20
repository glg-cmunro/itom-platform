##List configurations



## Production
gcloud config configurations activate slb-gke-p
gcloud compute start-iap-tunnel gcp6133prdapp01 22 --local-host-port=localhost:22001


## Non-Prod
gcloud config configurations activate slb-gke-np
gcloud compute start-iap-tunnel gcp6133tstapp04 22 --local-host-port=localhost:22002




##DR
python3 dr_preaction.py