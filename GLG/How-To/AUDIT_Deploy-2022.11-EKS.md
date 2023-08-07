# Step by Step - Deploy AUDIT 'feature' on SMAX Cluster 2022.11 in AWS EKS
![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)

---

OpenText doc steps: [Install Audit Service]
1. Download the Audit Helm chart (EKS)
2. Download and Upload images for Audit service (EKS)
3. Configure EFS for Audit service
4. Prepare persistent volumes for Audit service
5. Launch RDS for Audit service
6. Create new deployment for Audig service
7. Configure load balancer for Audit service
8. Create application load balancer for Audit service
9. Configure values.yaml for Audit service (EKS)
10. Deploy Audit on AWS (EKS)

[Enable Audit]

[Install Audit Collector (EKS)]
1. PRE-REQ: Completed installation of SMAX 2022.11 on EKS
2. Download AUDIT helm chart for EKS

 > - Backup cluster before making ANY changes
 > - Download and Extract AUDIT Service helm chart for EKS
 > - Download and Extract AUDIT Collector helm chart for EKS
 > - Create EKS Nodes
 > - Create EFS
 > - Create RDS
 > - Create Bastion Host
 > - - Configure Bastion Host
 > - Create Control Node
 > - - Configure Control Node
 > - Silent Install OMT / SMAX
 > - Setup ALB Controller
 > - Add ingress for UIs 3000,5443,443
 > - Post Install - Deploy to
 > - Configure GLG Profile on Control Node

# Install AUDIT - 2022.11

> Backup Cluster and SUITE before making any changes  
> [AWS Backup Cluster](./AWS_BackupCluster.md)
    
    #Download and extract AUDIT Charts
    ```
    mkdir -p ~/audit/2022.11
    ```
    #-AUDIT_Service_2022.11
    curl -kLs https://owncloud.gitops.com/index.php/s/3qqilJPGGPvur9j/download -o ~/audit/audit-2022.11.zip
    unzip ~/audit/audit-2022.11.zip -d ~/audit/2022.11
    tar -xvf ~/audit/2022.11/auditpkg-1.0.0+202211008.1.tgz -C ~/audit/2022.11/
    cp ~/audit/2022.11/audit-helm-chart/audit/samples/itom-audit-pv.yaml ~/audit/

    #-AUDIT_Collector_2022.11
    curl -kLs https://owncloud.gitops.com/index.php/s/QKczOElXkZCB86P/download -o ~/audit/audit-collector-2022.11.zip
    unzip ~/audit/audit-collector-2022.11.zip -d ~/audit/2022.11/
    tar -xvf ~/audit/2022.11/auditcollectorpkg-1.0.0+202211008.2.tgz -C ~/audit/2022.11/

    #DOWNLOAD Images if not already downloaded

    #Prepare EFS for AUDIT
    sudo mkdir -p /mnt/efs/var/vols/itom/audit/vault
    sudo mkdir -p /mnt/efs/var/vols/itom/audit/log
    sudo chmod -R g+ws /mnt/efs/var/vols/itom/audit
    sudo chown -R 1999:1999 /mnt/efs/var/vols/itom/audit
    
    #Prepare PV / PVC for AUDIT
    #Edit itom-audit-pv.yaml with proper EFS_Host, EFS_Path, Namespace information
    cp ~/audit/2022.11/audit-helm-chart/audit/samples/itom-audit-pv.yaml ~/audit/testing_audit-pv.yaml
    vi ~/audit/testing_audit-pv.yaml
    kubectl create -f ~/audit/testing_audit-pv.yaml
    
    
    #Create AUDIT DB
    export PGHOST=`kubectl get cm -n core default-database-configmap -ojson | jq -r .data.DEFAULT_DB_HOST`
    export PGUSER=`kubectl get cm -n core default-database-configmap -ojson | jq -r .data.DEFAULT_DB_USERNAME`
    psql -d maas_admin -W
    
    <CREATE DB SCRIPT>
    
    CREATE USER auditdbuser ENCRYPTED PASSWORD 'Gr33nl1ght_';
    GRANT auditdbuser TO dbadmin;
    CREATE DATABASE "auditdb" OWNER auditdbuser; 
    \q

    #Create AUDIT Deployment
    /opt/smax/2022.11/scripts/cdfctl.sh deployment create -d audit -n audit -t helm
    
    #Create AUDIT public ingress
    vi ~/audit/testing_audit_ingress.yaml
    kubectl create -f ~/audit/testing_audit_ingress.yaml

    #Create AUDIT internal ingress
    vi ../oo/testing_int-ingress.yaml
    kubectl create -f ../oo/testing_int-ingress.yaml

    #Create AUDIT Values
    cp ~/audit/2022.11/audit-helm-chart/audit/samples/values.yaml ~/audit/audit_values.yaml
    vi ~/audit/audit_values.yaml
        global.isDemo: false
        ADD :: global.persistence.enabled: true
        ADD :: global.persistence.logVolumeClaim: as-log-vol-claim
        global.externalAccessHost: <audit FQDN>
        global.externalAccessPort: 443
        global.nginx.httpsPort: 443
        global.docker.registry: <ECR Repo URL>
        global.idm.idmSvcHost: <SMAX FQDN>
        global.vaultInit.certname: <audit FQDN>
        auditService.database.user: auditdbuser
        auditService.databsae.jdbcUrl: jdbc:postgresql://<RDSDBInstance>:5432/auditdb?ssl=false
        auditService.idm.superUser: suite-admin
        auditService.idm.superUserOrgName: sysbo
        auditService.idm.internalIdmHost: <SMAX Integration FQDN>
        auditService.idm.internalIdmPort: 2443
        auditService.idm.publicIdmHost: <SMAX FQDN>
        auditGateway.deployment.internalIdmHost: <SMAX Integration FQDN>
        auditGateway.deployment.internalIdmPort: 2443
        auditGateway.deployment.publicIdmHost: <SMAX FQDN>
        auditGateway.deployment.auditTransportUser: 
        auditGateway.deployment.auditEndPoint: https://<SMAX Integration FQDN>:31050

    #Create AUDIT Secret
    /opt/smax/2022.11/scripts/gen_secrets.sh -n audit -c ~/audit/2022.11/audit-helm-chart/audit/charts/audit-1.0.0+202211008.1.tgz -o ~/audit/audit_secret.yaml


    #Deploy AUDIT
    helm install audit ~/audit/2022.11/audit-helm-chart/audit/charts/audit-1.0.0+202211008.1.tgz -n audit -f ~/audit/audit_values.yaml -f ~/audit/audit_secret.yaml --set-file "caCertificates.RE_ca_intAlb"=~/testing.dev.gitops.com.cer --set-file "caCertificates.RE_ca_idmcrt"=~/testing.dev.gitops.com.cer
    
    helm upgrade audit ~/audit/2022.11/audit-helm-chart/audit/charts/audit-1.0.0+202211008.1.tgz -n audit --reuse-values --set-file "caCertificates.RE_ca_intAlb"=/home/cmunro/testing.dev.gitops.com.cer --set-file "caCertificates.RE_ca_idmcrt"=/home/cmunro/testing.dev.gitops.com.cer
    
    #Create AUDIT IDM Admin account
    https://recovery2.dev.gitops.com/idm-admin
    https://optic.dev.gitops.com/idm-admin
    https://smax-west.gitops.com/idm-admin
    https://testing.dev.gitops.com/idm-admin
    Username: audit-integration-admin
    Pass: <Keep track of this for the audit-engine-secret>
    #Add ADMIN IDM Admin account to audit-management role
    
    #Prepare audit_engine_-_secret
    vi ~/audit/audit_engine_secret.yaml
    kubectl create -f ~/audit/audit_engine_secret.yaml

    
    #Restart ITOM Platform and IDM pods
    kubectl rollout restart deployment -n $NS itom-xruntime-platform
    kubectl rollout restart deployment -n $NS idm

    #Setup audit-client-cfg.properties
    kubectl exec -ti -n $NS $(kubectl get pods -n $NS | grep platform | head -n1 | awk {'print $1'}) -c itom-xruntime-platform -- bash
    
    
    #Generate OO secrets
    /opt/smax/2022.11/scripts/gen_secrets.sh -n oo -c ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz
    

    cd ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/
    tar -xvf oo-1.0.3+20221101.8.tgz
    cp ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo/values.yaml  ~/oo/testing_oo-values.yaml
    cd ~/oo
    vi ~/oo/testing_oo-values.yaml

    #Install OO
    helm install oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --namespace oo -f ~/oo/testing_oo-values.yaml -f ~/oo/oo_size_values.yaml
    helm install oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --namespace oo -f oo_values.smax-west.yaml -f oo_size_values.yaml
    helm upgrade oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --reuse-values --namespace oo -f ~/oo_values.optic.yaml -f ~/oo_size_values.yaml
    helm upgrade oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --reuse-values --namespace oo -f ~/oo_values.smax-west.yaml -f ~/oo_size_values.yaml
    
    #Add oo-ingress for LoadBalancer
    kubectl create -f ~/oo-ingress.yaml

    helm upgrade oo ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz --reuse-values --namespace oo --set-file "caCertificates.oo_lb\.crt"=~/oo/testing_lb.crt --set-file "caCertificates.integration_lb\.crt"=~/oo/testing_lb.crt

    ##Install OO 2022.05.P1
    curl -k https://owncloud.gitops.com/index.php/s/Bbo8xNuDHQtWim6/download -o ~/oo-helm-charts-1.0.2+20220501P1-1.zip
    unzip ~/oo-helm-charts-1.0.2+20220501P1-1.zip -d ~/oo_2022.05.P1
    APLSDBNAME=$(echo `/opt/cdf/bin/yq e '.autopass.deployment.database.dbName' ~/oo_values.smax-west.yaml`) && echo $APLSDBNAME
    APLSDBUSER=$(echo `/opt/cdf/bin/yq e '.autopass.deployment.database.user' ~/oo_values.smax-west.yaml`) && echo $APLSDBUSER
    /opt/cdf/bin/yq e '.autopass-migration.deployment.database.dbName = "'${APLSDBNAME}'"' -i ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/values/202205_P1.yaml
    /opt/cdf/bin/yq e '.autopass-migration.deployment.database.user = "'${APLSDBUSER}'"' -i ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/values/202205_P1.yaml
    /opt/cdf/bin/yq e '.global.idm.idmServiceUrl = "https://smax-west.gitops.com:443/idm-service"' -i ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/values/202205_P1.yaml
    helm upgrade oo -n oo --reuse-values -f ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/values/202205_P1.yaml ~/oo_2022.05.P1/oo-1.0.2+20220501P1-1/oo-helm-charts/charts/oo-1.0.2+20220501P1.1.tgz --timeout 30m


    ## Upgrade OO 2022.11.P3
    curl -gkLs https://owncloud.gitops.com/index.php/s/mvm0f4n2CwJ45Ia/download -o ~/oo/oo-helm-charts-1.0.3-20221101P3.1.zip
    unzip ~/oo/oo-helm-charts-1.0.3-20221101P3.1.zip -d ~/oo/oo_2022.11.P3
    /opt/smax/2022.11/bin/helm get values -n oo oo > ~/oo/oo_2022.11-values.yaml
    cp ~/oo/oo_2022.11-values.yaml ~/oo/oo_2022.11.P3-values.yaml
    
    /opt/smax/2022.11/bin/yq eval 'del(.global.busybox)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.global.opensuse)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.global.vaultRenew)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.global.vaultInit)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.. | select(has("image")).image)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.. | select(has("imageTag")).imageTag)' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval 'del(.ootenants-sync.version)' -i ~/oo/oo_2022.11.P3-values.yaml

    /opt/smax/2022.11/bin/yq eval '.global.idm.idmServiceUrl = "https://testing-int.dev.gitops.com:2443/idm-service"' -i ~/oo/oo_2022.11.P3-values.yaml

    APLSDBNAME=$(echo `/opt/smax/2022.11/bin/yq eval '.autopass.deployment.database.dbName' ~/oo/oo_2022.11.P3-values.yaml`) && echo $APLSDBNAME
    APLSDBUSER=$(echo `/opt/smax/2022.11/bin/yq eval '.autopass.deployment.database.user' ~/oo/oo_2022.11.P3-values.yaml`) && echo $APLSDBUSER
    APLSMIGRATIONDBNAME=$(echo `/opt/smax/2022.11/bin/yq eval '.autopass-migration.deployment.database.dbName' ~/oo/oo_2022.11.P3-values.yaml`) && echo $APLSMIGRATIONDBNAME 
    APLSMIGRATIONDBUSER=$(echo `/opt/smax/2022.11/bin/yq eval '.autopass-migration.deployment.database.user' ~/oo/oo_2022.11.P3-values.yaml`) && echo $APLSMIGRATIONDBUSER
    [[ $APLSDBNAME == $APLSMIGRATIONDBNAME ]] && echo "Values of autopass db name and autopass migration db name is same. "
    [[ $APLSDBUSER == $APLSMIGRATIONDBUSER ]] && echo "Values of autopass db user and autopass migration db user is same. "

    /opt/smax/2022.11/bin/yq eval '.autopass-migration.deployment.database.dbName = "'${APLSDBNAME}'"' -i ~/oo/oo_2022.11.P3-values.yaml
    /opt/smax/2022.11/bin/yq eval '.autopass-migration.deployment.database.user = "'${APLSDBUSER}'"' -i ~/oo/oo_2022.11.P3-values.yaml

    helm upgrade oo -n oo ~/oo/oo_2022.11.P3/oo-helm-charts-1.0.3-20221101P3.1/oo-helm-charts/charts/oo-1.0.3+20221101P3.1.tgz -f ~/oo/oo_2022.11.P3-values.yaml --set global.deploymentType="upgrade" --set global.secretStorageType="null" --timeout 30m

    helm upgrade oo -n oo ~/oo/oo_2022.11.P3/oo-helm-charts-1.0.3-20221101P3.1/oo-helm-charts/charts/oo-1.0.3+20221101P3.1.tgz -f ~/oo/oo_2022.11.P3-values.yaml --set global.deploymentType="install" --set global.secretStorageType="null" --timeout 30m


##### Enable OO RAS and Designer downloads from Endpoint Manager
[OpenText DOC: Customize OO Download Link](https://docs.microfocus.com/doc/SMAX/2022.11/CustomizeOODownloadLinks)
> NOTE: Requires SMA Toolkit  
Example used for testing.dev.gitops.com
```
python3 ~/toolkit/enable_download/enable_download.py testing.dev.gitops.com 462039570 bo-integration@dummy.com Gr33nl1ght_ https://testing-oo.dev.gitpps.com:443/oo/downloader OO_DOWNLOAD_SERVICE
```

##### Install OO RAS Server (External RAS)
- NOTE: CMS Gateway (RAS Server) needs xorg-x11-auth, bzip2, gtk2 packages installed for OO RAS Installer
