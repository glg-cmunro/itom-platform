# OMT 2022.11.P3 Install
mkdir ~/omt
cd ~/omt
curl -gkLs https://owncloud.gitops.com/index.php/s/Ei0jXrIhw6eVLpS/download -o ~/omt/OMT2211P3-15001.zip
unzip ~/omt/OMT2211P3-15001.zip -d ~/omt/
unzip ~/omt/OMT_2022.11.P3-020.zip -d ~/omt/
cd ~/omt/OMT_2022.11.P3-020
~/omt/OMT_2022.11.P3-020/patch.sh --apply
