##GCP Cluster Infrastructure Build

#Pre-requisite
# Ensure that the Google Kubernetes Engine API is enabled
# Ensure Google Cloud SDK is installed and configured for your project

# Create Cluster
gcloud beta container --project "gke-smax" clusters create "smaxgke1905" --region "us-west1" --username "admin" --cluster-version "1.15.12-gke.4000" --release-channel "None" --machine-type "e2-standard-4" --image-type "COS" --disk-type "pd-standard" --disk-size "100" --node-labels role=loadbalancer,cdfapiserver=true,node.type=worker,Worker=label --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/cloud-platform" --num-nodes "1" --enable-stackdriver-kubernetes --enable-private-nodes --enable-private-endpoint --master-ipv4-cidr "172.19.0.0/28" --enable-ip-alias --network "projects/gke-smax/global/networks/smaxdev-vpc" --subnetwork "projects/gke-smax/regions/us-west1/subnetworks/smaxdev-k8s-subnet" --cluster-ipv4-cidr "10.96.0.0/14" --services-ipv4-cidr "10.94.0.0/18" --default-max-pods-per-node "40" --enable-master-authorized-networks --master-authorized-networks 10.0.1.0/24 --addons HorizontalPodAutoscaling,HttpLoadBalancing --no-enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0
