#!/usr/bin/bash
#### smax_byok_install_Vertica


#Download Vertica RPM


#Install required pre-Requisites
sudo yum install dialog mcelog gstack -y

#Set SYSTEM Parameters for Vertica
echo '''
vm.swappiness = 1
''' | sudo tee /etc/sysctl.d/10-glgVertica.conf
sudo sysctl -p /etc/sysctl.d/10-glgVertica.conf

echo '''
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
    echo always > /sys/kernel/mm/transparent_hugepage/enabled
fi
''' | sudo tee -a /etc/rc.local
sudo chmod +x /etc/rc.d/rc.local

sudo su
echo always > /sys/kernel/mm/transparent_hugepage/enabled
exit

sudo /sbin/blockdev --setra 2048 /dev/nvme0n1

sudo dd if=/dev/zero of=/var/vertica-swap bs=1M count=4096
sudo chmod 0600 /var/vertica-swap
sudo mkswap /var/vertica-swap
sudo swapon /var/vertica-swap

echo '''
/var/vertica-swap    swap        swap    defaults        0 0
''' | sudo tee -a /etc/fstab

#Install RPM
sudo rpm -Uhv vertica-10.0.1-3.x86_64.RHEL6.rpm


#Install Vertica
DB_HOST=$(hostname -i)
sudo /opt/vertica/sbin/install_vertica --hosts $DB_HOST --rpm vertica-10.0.1-3.x86_64.RHEL6.rpm

sudo su - dbadmin

DB_HOST=$(hostname -i)
/opt/vertica/bin/adminTools -t create_db -d cgro -p Gr33nl1ght_ --hosts=$DB_HOST --policy=always
/opt/vertica/bin/adminTools -t logrotate -d cgro -r daily -k7
vsql -U dbadmin -w Gr33nl1ght_ -c 'select display_license();'

openssl genrsa -out servercakey.pem
openssl req -new -x509 -key servercakey.pem -out serverca.crt 

openssl genrsa -out server.key
openssl req -new -key server.key -out server_reqout.txt

openssl x509 -req -in server_reqout.txt -days 3650 -sha1 -CAcreateserial -CA serverca.crt -CAkey servercakey.pem -out server.crt

openssl genrsa -out client.key
openssl req -new -key client.key -out client_reqout.txt
openssl x509 -req -in client_reqout.txt -days 3650 -sha1 -CAcreateserial -CA serverca.crt -CAkey servercakey.pem -out client.crt



#####
{
    "kind": "Service",
    "apiVersion": "v1",
    "metadata": {
        "name": "slcv-vmvc01.glg.lcl",
        "namespace": "default"
    },
    "spec": {
        "type": "ExternalName",
        "externalName": "vcenter.greenlightgroup.com",
        "ports": [{ "port": 443 }]
    }
}