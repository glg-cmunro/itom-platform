# Step by Step - Upgrade ITOM Cluster capability - OO Containerized - 2023.05
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

## Deployment Steps
> - Backup Cluster before making ANY changes
> - Create OO Upgrade working directory
> - Download and Extract OO helm charts
> - Update the helm values for OO
> - Perform the helm upgrade for OO
 
## Upgrade OO Containerized - 2023.05

### Backup Cluster and SUITE before making any changes
> [AWS Backup Cluster](./AWS_Cluster-Backup.md)

### Download and extract OO Charts  
```
mkdir -p ~/oo/2023.05
```

> OO_2023.05 Helm Chart
```
curl -kLs https://owncloud.gitops.com/index.php/s/VJki0PQfb9qmK2E/download -o ~/oo/2023.05/oo-1.1.0-20230501.15.zip
unzip ~/oo/2023.05/oo-1.1.0-20230501.15.zip -d ~/oo/2023.05
```

> - One Time Image Download
```
/opt/cdf/tools/generate-download/generate_download_bundle.sh --chart ~/oo/2023.05/oo-helm-charts-1.1.0-20230501.15/oo-helm-charts/charts/oo-1.1.0+20230501.15.tgz -o hpeswitom -d ~/oo/2023.05/
```
```
unzip ~/oo/2023.05/offline-download.zip -d ~/oo/2023.05/
cp ~/oo/2023.05/offline-download/image-set.json /opt/glg/aws-smax/BYOK/2023.05/2023.05_oo-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=testing.dev.gitops.com -e region=us-east-1 -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_oo-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=smax-west.gitops.com -e region=us-west-2 -e prod=true -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_oo-image-set.json
```

### Update the helm values for OO
> Get currently deployed values
```
helm get values oo -n oo > ~/oo/2023.05/oo_values-2022.11.yaml.bak
```

> Remove outdated values
```
/opt/cdf/bin/yq eval 'del(.global.busybox)' -i ~/oo/2023.05/oo_values-2022.11.yaml.bak
/opt/cdf/bin/yq eval 'del(.global.opensuse)' -i ~/oo/2023.05/oo_values-2022.11.yaml.bak
/opt/cdf/bin/yq eval 'del(.global.vaultRenew)' -i ~/oo/2023.05/oo_values-2022.11.yaml.bak
/opt/cdf/bin/yq eval 'del(.global.vaultInit)' -i ~/oo/2023.05/oo_values-2022.11.yaml.bak
/opt/cdf/bin/yq eval 'del(.. | select(has("image")).image)' -i ~/oo/2023.05/oo_values-2022.11.yaml.bak
/opt/cdf/bin/yq eval 'del(.. | select(has("imageTag")).imageTag)' -i ~/oo/2023.05/oo_values-2022.11.yaml.bak
/opt/cdf/bin/yq eval 'del(.ootenants-sync.version)' -i ~/oo/2023.05/oo_values-2022.11.yaml.bak
```

### Perform the helm upgrade for OO
```
helm upgrade oo -n oo ~/oo/2023.05/oo-helm-charts-1.1.0-20230501.15/oo-helm-charts/charts/oo-1.1.0+20230501.15.tgz -f ~/oo/2023.05/oo_values-2022.11.yaml.bak --timeout 30m
```


### Enable OO Bits Download for Tenant
> Required:  
> - SMAX FQDN
> - TENANT_ID
> - INTEGRATION PASSWORD (for bo-integration user)
> - OO FQDN
```
kubectl exec -ti -n $NS deploy/itom-toolkit -c itom-toolkit -- bash
cd /toolkit && python3 /toolkit/enable_download/enable_download.py <SMAX FQDN> <TENANT_ID> bo-integration@dummy.com <INTEGRATION PASSWORD> https://<OO FQDN>:443/oo/downloader OO_DOWNLOAD_SERVICE
```
*Example command from the SMA Support Assistant for SMAX-WEST GreenLight Prod Tenant*
> cd /toolkit && python3 /toolkit/enable_download/enable_download.py smax-west.gitops.com 269014623 bo-integration@dummy.com Gr33nl1ght_ https://smax-west-oo.gitops.com:443/oo/downloader OO_DOWNLOAD_SERVICE
