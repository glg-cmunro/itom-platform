# OMT 2022.11.P3 Install
mkdir ~/omt
cd ~/omt
curl -gkLs https://owncloud.gitops.com/index.php/s/Ei0jXrIhw6eVLpS/download -o ~/omt/OMT2211P3-15001.zip
unzip ~/omt/OMT2211P3-15001.zip -d ~/omt/
unzip ~/omt/OMT_2022.11.P3-020.zip -d ~/omt/
~/omt/OMT_2022.11.P3-020/patch.sh --apply

#NOTE: Before applying the patch make sure the ECR registrypullsecret has a valid token for access to the repo images.  This is done with an ansible playbook

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
