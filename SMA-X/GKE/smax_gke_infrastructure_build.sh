##GCP Cluster Infrastructure Build
GKE_CLUSTER=smax115-1905
GKE_REGION=us-west1
GKE_ZONE=us-west1-b
GKE_MASTER_CIDR="10.0.10.0/28"
GKE_CLUSTER_CIDR="10.0.16.0/21"
GKE_SERVICES_CIDR="10.0.32.0/24"
GKE_MASTER_AUTH_NET="10.0.1.0/24"

#Pre-requisite
# Ensure that the Google Kubernetes Engine API is enabled
# Ensure Google Cloud SDK is installed and configured for your project

# Create Cluster
gcloud container --project "gke-smax" clusters create "$GKE_CLUSTER" \
--region "$GKE_REGION" --username "admin" --cluster-version "1.15.12-gke.6002" \
--release-channel "stable" --machine-type "n1-standard-8" --image-type "COS" \
--disk-type "pd-standard" --disk-size "100" --node-labels role=loadbalancer,cdfapiserver=true,node.type=worker,Worker=label \
--metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/cloud-platform" \
--num-nodes "1" --enable-stackdriver-kubernetes --enable-private-nodes \
--enable-private-endpoint --master-ipv4-cidr "$GKE_MASTER_CIDR" --enable-ip-alias \
--network "projects/gke-smax/global/networks/smaxdev-vpc" \
--subnetwork "projects/gke-smax/regions/us-west1/subnetworks/smaxdev-k8s-subnet" \
--cluster-ipv4-cidr "$GKE_CLUSTER_CIDR" --services-ipv4-cidr "$GKE_SERVICES_CIDR" \
--default-max-pods-per-node "40" --enable-master-authorized-networks \
--master-authorized-networks "$GKE_MASTER_AUTH_NET" --addons HorizontalPodAutoscaling,HttpLoadBalancing \
--enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0

# Add Kubeconfig for access to Cluster
sudo gcloud container clusters get-credentials --region "$GKE_REGION" "$GKE_CLUSTER"
gcloud container clusters get-credentials --region "$GKE_REGION" "$GKE_CLUSTER"
