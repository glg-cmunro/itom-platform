# Step by Step - Deploy OO RAS for Containerized OO

> Tasks below are to be performed on the API Tools server (location to install/run OO RAS)
mkdir -p ~/oo/23.4/ras
curl https://owncloud.gitops.com/index.php/s/u6MB5mO1eVzFN75/download -o ~/oo/23.4/ras/installer-ras-linux-23.4.0.zip
unzip ~/oo/23.4/ras/installer-ras-linux-23.4.0.zip -d ~/oo/23.4/ras



########################################
#### Silent Install Config for OO RAS
root.dir=/opt/opentext/ooras/462039570
central.url=https://testing-oo.dev.gitops.com:443/oo/?tenantId=462039570
central.username=dnd-int-462039570
central.password=Gr33nl1ght_
ssl.client.certificate=false




########################################
#### OO RAS Upgrade to 23.4
mkdir -p ~/oo/23.4/ras
curl https://owncloud.gitops.com/index.php/s/k30scYCVidyVu2u/download -o ~/oo/23.4/ras/upgrader-ras-23.4.0.zip
#unzip ~/oo/23.4/ras/upgrader-ras-23.4.0.zip -d ~/oo/23.4/ras/upgrader

#### Upgrade Tenant 269014623 - GreenLight Production
sudo unzip ~/oo/23.4/ras/upgrader-ras-23.4.0.zip -d /opt/opentext/ooras/269014623/
cd /opt/opentext/ooras/269014623/upgrade/23.4.0/bin
sudo chmod a+x ../java/linux64/bin/java
sudo ./apply-upgrade
