# Step by Step - Upgrade ITOM Cluster capability - AUDIT Service - 2023.05
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

## Deployment/Upgrade Steps for AUDIT Service
> - Backup Cluster before making ANY changes
> - Create AUDIT Upgrade working directory
> - Download and Extract OO helm charts
> - Update the helm values for OO
> - Perform the helm upgrade for OO
 
## Upgrade AUDIT Service - 2023.05

### Backup Cluster and SUITE before making any changes
> [AWS Backup Cluster](./AWS_BackupCluster.md)
    
### Download and extract Audit Charts  
```
mkdir -p ~/audit/2023.05
```

> AUDIT-Service_2023.05 Helm Chart
```
curl -kLs https://owncloud.gitops.com/index.php/s/Ew2ZINlZLY5l2S6/download -o ~/audit/2023.05/Audit_Helm_Chart-2023.05.zip
unzip ~/audit/2023.05/Audit_Helm_Chart-2023.05.zip -d ~/audit/2023.05
tar -zvxf ~/audit/2023.05/auditpkg-1.1.0+202305000.2.tgz -C ~/audit/2023.05
```
> AUDIT-Collector_2023.05 Helm Chart
```
curl -kLs https://owncloud.gitops.com/index.php/s/9QNLaOY2xPETh2L/download -o ~/audit/2023.05/Audit_Collector_Helm_Chart-2023.05.zip
unzip ~/audit/2023.05/Audit_Collector_Helm_Chart-2023.05.zip -d ~/audit/2023.05
tar -zvxf ~/audit/2023.05/auditcollectorpkg-1.1.0+202305000.1.tgz -C ~/audit/2023.05
```

> - One Time Image Download
```
/opt/cdf/tools/generate-download/generate_download_bundle.sh --chart ~/audit/2023.05/audit-helm-chart/audit/charts/audit-1.1.0+202305000.2.tgz -o hpeswitom -d ~/audit/2023.05/
```
```
unzip ~/audit/2023.05/offline-download.zip -d ~/audit/2023.05/
cp ~/audit/2023.05/offline-download/image-set.json /opt/glg/aws-smax/BYOK/2023.05/2023.05_audit-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=testing.dev.gitops.com -e region=us-east-1 -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_audit-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=smax-west.gitops.com -e region=us-west-2 -e prod=true -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_audit-image-set.json
```
```
/opt/cdf/tools/generate-download/generate_download_bundle.sh --chart ~/audit/2023.05/audit-collector-helm-chart/audit-collector/charts/audit-collector-1.1.0+202305000.1.tgz -o hpeswitom -d ~/audit/2023.05/
```
```
unzip ~/audit/2023.05/offline-download.zip -d ~/audit/2023.05/
cp ~/audit/2023.05/offline-download/image-set.json /opt/glg/aws-smax/BYOK/2023.05/2023.05_audit-collector-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=testing.dev.gitops.com -e region=us-east-1 -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_audit-collector-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=smax-west.gitops.com -e region=us-west-2 -e prod=true -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_audit-image-set.json
```

### Backup the helm values and Secrets for Audit
> Get currently deployed values
```
helm get values audit -n audit > ~/audit/2023.05/audit_values-2022.11.yaml.bak
```

> Get currently deployed secrets
```
kubectl get secret itom-audit-secret -n audit -o yaml > ~/audit/2023.05/audit_secret-2022.11.yaml.bak
```

### Perform the helm upgrade for Audit
```
helm upgrade audit ~/audit/2023.05/audit-helm-chart/audit/charts/audit-1.1.0+202305000.2.tgz -n audit -f ~/audit/2023.05/audit_values-2022.11.yaml.bak -f ~/audit/2023.05/audit_secret-2022.11.yaml.bak
```
