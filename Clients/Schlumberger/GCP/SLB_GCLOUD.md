![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

The GKE Cluster for SMAX @ SLB requires certain Kubernetes permissions.
These permissions are already associated with the compute@developer service account used to create the cluster
In order to support this environment each engineer should have the compute@developer service account, and only this account, in their profile on the Control Node
Follow the steps below to ensure that your profile is setup with the correct account and permissions

- Check your current list of gcloud accounts
- Set compute@developer account as the active account
- Use active account to configure kubectl and cluster access
- Validate cluster permissions with updated credentials
- Remove unnecessary accounts from your gcloud profile

### Check current list of gcloud accounts
```
gcloud auth list
```
<screenshot here>

### Set compute@developer account as the active account
```
gcloud config set account 813937687018-compute@developer.gserviceaccount.com
```
<screenshot here>

### Use active account to configure kubectl and cluster access
```
gcloud container clusters get-credentials --region europe-west1 gcp6133-dr-k8s01
```
<screenshot here>

### Validate cluster permissions with updated credentials
```
kubectl patch clusterroles microfocus:cdf:itom-kube-dashboard -p '{"metdata":{"labels":{"last-edit":"CMunro"}}}'
```
<screenshot here>

### Remove unnecessary accounts from your gcloud profile
```
gcloud auth revoke thoffa@slb.com
```
<screenshot here>
