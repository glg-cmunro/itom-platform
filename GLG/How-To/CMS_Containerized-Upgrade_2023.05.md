# Step by Step - Deploy ITOM Cluster capability - CMS Containerized - 2022.11
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

## Deployment/Upgrade Steps
> - Create CMS Upgrade Working Directory
> - Backup current CMS Configuration
> - Download / Extract CMS helm chart package
> - Prepare EFS / NFS directories for CMS
> - Prepare CMS helm chart values
> - Create CMS Databases in RDS Instance
> - Create CMS Integration Admin user in SMAX IdM
> - Create OMT Deployment for CMS
> - Generate CMS vault secrets
> - Install CMS
> - Associate CMS SuperAdmin role

## Upgrade instructions for CMS Containerized in SMAX cluster 2022.11 to 2023.05

> Environment Variables to assist with installation
```
export CLUSTER_NAME=qa
export CDF_HOME=/opt/cdf
export CDF_NAMESPACE=core
export ECR_REPO=`kubectl get deployment -n $NS idm -o json | jq -r .spec.template.spec.containers[0].image | awk -F/ {'print $1'}`
```

1. Create CMS Upgrade Working Directory
```
mkdir -p ~/cms/2023.05
#cd ~/cms
```

2. Backup current CMS Configuration
```
kubectl get secret cms-secret -o yaml -n cms > ~/cms/2023.05/cms-secrets.yaml.bak
helm get values -n cms cms > ~/cms/2023.05/cms-values.yaml.bak
```

3. Download / Extract CMS helm chart package  
```
curl -kLs https://owncloud.gitops.com/index.php/s/QzLk7irrHLgReft/download -o ~/cms/CMS_Helm_Chart-2023.05.zip
unzip ~/cms/CMS_Helm_Chart-2023.05.zip -d ~/cms/2023.05/
tar -zxvf ~/cms/2023.05/CMS_Helm_Chart-2023.05/cms-helm-charts-2023.05.tgz -C ~/cms/2023.05
rm -rf ~/cms/2023.05/CMS_Helm_Chart-2023.05
```

> - One Time Image Download
```
/opt/cdf/tools/generate-download/generate_download_bundle.sh --chart ~/cms/2023.05/cms-helm-charts/charts/cms-1.8.0+20230500.279.tgz -o hpeswitom -d ~/cms/2023.05/
unzip ~/cms/2023.05/offline-download.zip -d ~/cms/2023.05/
cp ~/cms/2023.05/offline-download/image-set.json /opt/glg/aws-smax/BYOK/2023.05/2023.05_cms-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=testing.dev.gitops.com -e region=us-east-1 -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_cms-image-set.json
```

4. Perform the helm upgrade for CMS
```
helm upgrade cms ~/cms/2023.05/cms-helm-charts/charts/cms-1.8.0+20230500.279.tgz -n cms -f ~/cms/2023.05/cms-values.yaml.bak
```

5. Clean up SOLR  
- Stop UCMDB solr  
```
kubectl scale deployment itom-ucmdb-solr -n cms --replicas=0
```

- Delete the old solr data
```
cd /mnt/efs/var/vols/itom/cms/data-volume/ucmdb/solr
rm -rf ./data
```

- Restart UCMDB solr
```
kubectl scale deployment itom-ucmdb-solr -n cms --replicas=1
```

- Restart UCMDB
```
kubectl scale sts -n cms itom-ucmdb --replicas=0
```
> wait until UCMDB is stopped
```
kubectl scale sts -n cms itom-ucmdb --replicas=2
```