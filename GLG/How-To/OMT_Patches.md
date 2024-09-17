# OMT 2022.11.P3 Install
mkdir ~/omt
cd ~/omt
curl -gkLs https://owncloud.gitops.com/index.php/s/Ei0jXrIhw6eVLpS/download -o ~/omt/OMT2211P3-15001.zip
unzip ~/omt/OMT2211P3-15001.zip -d ~/omt/
unzip ~/omt/OMT_2022.11.P3-020.zip -d ~/omt/
~/omt/OMT_2022.11.P3-020/patch.sh --apply

#NOTE: Before applying the patch make sure the ECR registrypullsecret has a valid token for access to the repo images.  This is done with an ansible playbook