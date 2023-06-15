# OMT 2022.11 P3 Install
mkdir ~/omt
cd ~/omt
curl -gkLs https://owncloud.gitops.com/index.php/s/Ei0jXrIhw6eVLpS/download -o OMT2211P3-15001.zip
unzip OMT2211P3-15001.zip
unzip OMT_2022.11.P3-020.zip
cd OMT_2022.11.P3-020
patch.sh --apply