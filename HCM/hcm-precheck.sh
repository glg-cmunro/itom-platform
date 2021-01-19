#!/bin/bash
### Check CPU - Should be 16 CPU
echo "### Checking CPU Count ###"
cpucount="$(cat /proc/cpuinfo | grep -c processor)"
echo "Found $cpucount CPU - HCM Requires 16"
if [ "$cpucount" -lt "16" ]; then 
    echo "FAILED: CPU Count"
else
    echo "PASSED: CPU COUNT"
fi
echo ""

### Check RAM - Should be 32 GB
echo "### Checking Memory Size ###"
meminfo="$(expr `free -m | grep Mem: | awk '{print $2}'` / 1024)"
echo "Found $meminfo GB Memory - HCM Requires 32 GB"
if [ "$meminfo" -lt "32" ]; then 
    echo "FAILED: Memory"
else
    echo "PASSED: Memory"
fi
echo ""

### Check Installed Packages
### HCM Required Packages include:
###     lsof
###     device-mapper-libs
###     java-1.8.0-openjdk
###     libencrypt
###     iptables
###     libseccomp
###     libtool-ltdl
###     net-tools
###     nfs-utils
###     rpcbind
###     systemd-libs
###     unzip
###     bind-utils
###     httpd-tools - Only required on the first Master (Used for installation of the suite)

echo "### Checking Required Packages ###"
pkgLSOF="$(yum -t -C list lsof | grep Installed | awk '{print $1}')"
echo "  lsof:               $pkgLSOF"
pkgDEVM="$(yum -t -C list device-mapper-libs | grep Installed | awk '{print $1}')"
echo "  device-mapper-libs: $pkgDEVM"
pkgJAVA="$(yum -t -C list java-1.8.0-openjdk | grep Installed | awk '{print $1}')"
echo "  java-1.8.0-openjdk: $pkgJAVA"
pkgLENC="$(yum -t -C list libencrypt | grep Installed | awk '{print $1}')"
echo "  libencrypt:         $pkgLENC"
pkgIPTB="$(yum -t -C list iptables | grep Installed | awk '{print $1}')"
echo "  iptables:           $pkgIPTB"
pkgLSEC="$(yum -t -C list libseccomp | grep Installed | awk '{print $1}')"
echo "  libseccomp:         $pkgLSEC"
pkgLTDL="$(yum -t -C list libtool-ltdl | grep Installed | awk '{print $1}')"
echo "  libtool-ltdl:       $pkgLTDL"
pkgNETT="$(yum -t -C list net-tools | grep Installed | awk '{print $1}')"
echo "  net-tools:          $pkgNETT"
pkgNFSU="$(yum -t -C list nfs-utils | grep Installed | awk '{print $1}')"
echo "  nfs-utils:          $pkgNFSU"
pkgRPCB="$(yum -t -C list rpcbind | grep Installed | awk '{print $1}')"
echo "  rpcbind:            $pkgRPCB"
pkgSYSL="$(yum -t -C list systemd-libs | grep Installed | awk '{print $1}')"
echo "  systemd-libs:       $pkgSYSL"
pkgUZIP="$(yum -t -C list unzip | grep Installed | awk '{print $1}')"
echo "  unzip:              $pkgUZIP"
pkgBNDT="$(yum -t -C list bind-utils | grep Installed | awk '{print $1}')"
echo "  bind-utils:         $pkgBNDT"
pkgHTTP="$(yum -t -C list httpd-tools | grep Installed | awk '{print $1}')"
echo "  httpd-tools:        $pkgHTTP"

echo ""

### Check SELINUX - Should be set to PERMISSIVE or DISABLED
getenforce

### Check Firewall - Should be disabled and stopped
systemctl status firewalld

### Check Hostname
hostnamectl status
hostname -f
hostname -s
hostname -i

### Get Real IP Addressip
ip address show scope global | grep 'inet' | awk '{print $2}' | cut -d "/" -f 1

### Check Time Sync
chronyc tracking

### heck System Property vm.max_map_count - Should be set to 262144 (for etcd)
cat /etc/sysctl.conf | grep vm.max_map_count

### Check ITOM User - Should be either 1999, or 100000+
id itom

### Check Disk Space:
#	/ = 5GB Free
#	/tmp = 2GB Free
#	/opt = 5GB Free
#	/var = 5GB Free
#	/opt/kubernetes = 100GB Free
#	/var/vols/itom = 150GB Free

