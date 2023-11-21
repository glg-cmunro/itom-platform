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
cd ~/omt/2023.05.P3/OMT_2023.05.P3-30/
~/omt/2023.05.P3/OMT_2023.05.P3-30/patch.sh --apply
