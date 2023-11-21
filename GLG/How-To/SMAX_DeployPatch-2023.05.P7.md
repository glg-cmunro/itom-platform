### GITOpS Deployment Documentation: SMAX 2023.05 Patch 7 
![alt text](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png "GreenLight Logo")
#### Apply Patches to both OMT 2023.05 and SMAX 2023.05(.P1)

---

## Deployment Steps
> - Backup Cluster before making ANY changes
> - Create OMT Upgrade working directory
> - Download and Extract OMT patch
> - Apply the OMT Patch
> - Download and Extract SMAX patch metadata
> - Upload SMAX patch metadata
> - Apply SMAX Patch



# OMT 2022.11.P3 Install
mkdir ~/omt
cd ~/omt
curl -gkLs https://owncloud.gitops.com/index.php/s/Ei0jXrIhw6eVLpS/download -o ~/omt/OMT2211P3-15001.zip
unzip ~/omt/OMT2211P3-15001.zip -d ~/omt/
unzip ~/omt/OMT_2022.11.P3-020.zip -d ~/omt/
cd ~/omt/OMT_2022.11.P3-020
~/omt/OMT_2022.11.P3-020/patch.sh --apply


# OMT 2023.05.P3 Install
mkdir -p ~/omt/2023.05.P3
curl -gkLs https://owncloud.gitops.com/index.php/s/MhaCClFppEL6EhD/download -o ~/omt/2023.05.P3/OMT2305P3-15001.zip
unzip ~/omt/2023.05.P3/OMT2305P3-15001.zip -d ~/omt/2023.05.P3/
unzip ~/omt/2023.05.P3/OMT_2023.05.P3-30.zip -d ~/omt/2023.05.P3/

#OneTimeOnly - Upload Images
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=testing.dev.gitops.com -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_omt.P3-image-set.json
ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=smax-west.gitops.com -e prod=true -e aws_region=us-west-2 -e region=us-west-2 -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_omt.P3-image-set.json

cd ~/omt/2023.05.P3/OMT_2023.05.P3-30/
~/omt/2023.05.P3/OMT_2023.05.P3-30/patch.sh --apply


ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-config-ecr-images.yaml -e full_name=testing.dev.gitops.com -e image_set_file=/opt/glg/aws-smax/BYOK/2023.05/2023.05_suite.P7-image-set.json
