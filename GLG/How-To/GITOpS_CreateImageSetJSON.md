# Create the image-set.json files required for OpenText ITOM Suites and Modules


To create an image-set.json file with only the delta images you will need to use an existing cluster with OMT and the SUITE / Module you want to create images for
You will need an active token for the cluster to check with the ECR repository for existing images.  For this you will need to update the kubernetes registrypullsecret
```
#For GreenLight Non-Prod ECR
/usr/local/bin/ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-refresh-secret.yaml -e region=us-east-1

#For GreenLight Production ECR
/usr/local/bin/ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-refresh-secret.yaml -e region=us-west-2 -e prod=true
```

## 2023.05
### OMT
### SMAX
### CMS
### OO
```
$CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart ~/oo/2023.05/oo-helm-charts-1.1.0-20230501.15/oo-helm-charts/charts/oo-1.1.0+20230501.15.tgz -o hpeswitom -d ~/oo/2023.05/
```
```
unzip ~/oo/2023.05/offline-download.zip -d ~/oo/2023.05/
cp ~/oo/2023.05/offline-download/image-set.json /opt/glg/aws-smax/BYOK/2023.05/2023.05_oo-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=testing.dev.gitops.com -e region=us-east-1 -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_oo-image-set.json
```
### AUDIT
```
$CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart ~/oo/2023.05/oo-helm-charts-1.1.0-20230501.15/oo-helm-charts/charts/oo-1.1.0+20230501.15.tgz -o hpeswitom -d ~/oo/2023.05/
```
```
unzip ~/oo/2023.05/offline-download.zip -d ~/oo/2023.05/
cp ~/oo/2023.05/offline-download/image-set.json /opt/glg/aws-smax/BYOK/2023.05/2023.05_oo-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=testing.dev.gitops.com -e region=us-east-1 -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_oo-image-set.json
```



## 2022.11
### OMT

### SMAX


### CMS
```
$CDF_HOME/tools/generate-download/generate_download_bundle.sh --chart ~/cms/cms-helm-charts/charts/cms-1.7.0+20221100.256.tgz -o hpeswitom -d ~/cms/cms_images
```

##### one-time get required cms images
$CDF_HOME/scripts/refresh-ecr-secret.sh -r us-east-1
unzip ~/cms/cms_images/offline-download.zip -d ~/cms/cms_images
> copy image-set.json to BYOK folder for Ansible

ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-smax-images.yaml --ask-vault-pass -e image_set_file=/opt/glg/aws-smax/BYOK/2022.11/2022.11_cms-image-set.json -e region=us-east-1

### OO
### AUDIT
### OpsB
### NOM