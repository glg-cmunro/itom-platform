# Step by Step - Deploy ITOM Cluster w/ SMAX|HCMX|DnD|CGRO|OO|CMS

1. Ansible Playbook - aws-infra-cf-create-all.yaml
 > - Create VPC
 > - Create Subnets (3x Public, 3x Private, 2x Database)
 > - Create EKS Cluster
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
 > - Post Install - Deploy tools
 > - Configure GLG Profile on Control Node


# Install OO Containerized - 2022.11

> Backup Cluster and SUITE before making any changes
> ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-smax-upgrade-backup-all.yaml -e full_name=testing.dev.gitops.com -e backup_name=basesmaxdeploy -e snap_string=basesmaxdeploy --ask-vault-pass
> ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-smax-upgrade-backup-all.yaml -e full_name=optic.dev.gitops.com -e backup_name=postomt202205 -e snap_string=postomt202205 --ask-vault-pass
> ansible-playbook /opt/glg/aws-smax/ansible/playbooks/aws-smax-upgrade-backup-all.yaml -e full_name=smax-west.gitops.com -e backup_name=postomt202205 -e snap_string=postomt202205 --ask-vault-pass -e prod=true
    
    #Download and extract OO Charts
    #-OO_2022.11
    curl -kLs https://owncloud.gitops.com/index.php/s/PEPTDATZ0sOItVm/download -o ~/oo/oo-1.0.3-20221101.8.zip
    unzip ~/oo/oo-1.0.3-20221101.8.zip -d ~/oo/oo_chart
    #-OO_2022.11.P3
    curl -kLs https://owncloud.gitops.com/index.php/s/mvm0f4n2CwJ45Ia/download -o ~/oo/oo-helm-charts-1.0.3-20221101P3.1.zip
    unzip ~/oo/oo-helm-charts-1.0.3-20221101P3.1.zip -d ~/oo/oo_chart
    
    #Prepare EFS for OO
    sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_config_vol
    sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_data_vol
    sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_logs_vol
    sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_data_export_vol
    sudo mkdir -p /mnt/efs/var/vols/itom/oo/oo_ras_logs_vol
    sudo chmod -R 755 /mnt/efs/var/vols/itom/oo
    sudo chown -R 1999:1999 /mnt/efs/var/vols/itom/oo
    
    #Create OO Deployment
    /opt/smax/2022.11/scripts/cdfctl.sh deployment create -d oo -n oo
    
    #Prepare PV / PVC for OO
    #Edit oo-pv.yaml with proper EFS_Host, EFS_Path, StorageClassName information
    cp ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/samples/persistent_storage/eks/volumes.yaml ~/oo/oo-pv.yaml
    cp ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/samples/persistent_storage/eks/volumes.yaml ~/oo/testing_oo-pv.yaml
    vi ~/oo/testing_oo-pv.yaml
    kubectl create -f ~/oo/testing_oo-pv.yaml

    #Edit oo-pvc (one for all environments) with proper StorageClassName "itom-oo"
    cp ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/samples/persistent_storage/eks/claims.yaml ~/oo/oo-pvc.yaml
    vi ~/oo/oo-pvc.yaml
    kubectl create -f ~/oo/oo-pvc.yaml
    
    #Create OO DBs
    export PGHOST=`kubectl get cm -n core default-database-configmap -ojson | jq -r .data.DEFAULT_DB_HOST`
    export PGUSER=`kubectl get cm -n core default-database-configmap -ojson | jq -r .data.DEFAULT_DB_USERNAME`
    psql -d maas_admin -W
    
    <CREATE DB SCRIPT>
    
    CREATE ROLE "oocentraldbuser" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
    CREATE DATABASE "oocentraldb"; 
    ALTER DATABASE "oocentraldb" OWNER TO "oocentraldbuser";
    CREATE ROLE "oouidbuser" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
    CREATE DATABASE "oouidb"; 
    ALTER DATABASE "oouidb" OWNER TO "oouidbuser";
    CREATE ROLE "oocontrollerdbuser" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
    CREATE DATABASE "oocontrollerdb"; 
    ALTER DATABASE "oocontrollerdb" OWNER TO "oocontrollerdbuser";
    CREATE ROLE "ooscheduler" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
    CREATE DATABASE "ooschedulerdb"; 
    ALTER DATABASE "ooschedulerdb" OWNER TO "ooscheduler";
    CREATE ROLE "aplsdbuser" LOGIN ENCRYPTED PASSWORD 'Gr33nl1ght_' NOSUPERUSER INHERIT;
    CREATE DATABASE "aplsdb"; 
    ALTER DATABASE "aplsdb" OWNER TO "aplsdbuser";
    \q

    #Add the SCHEMA for oo_sch_core (Must be the ooscheduler user)
    psql -U ooscheduler -d ooschedulerdb -W
    
    CREATE SCHEMA IF NOT EXISTS oo_sch_core AUTHORIZATION ooscheduler;
    \q

    
    #Create OO IDM Admin account
    https://recovery2.dev.gitops.com/idm-admin
    https://optic.dev.gitops.com/idm-admin
    https://smax-west.gitops.com/idm-admin
    https://testing.dev.gitops.com/idm-admin
    Username: oo-integration-admin
    Pass: <Keep track of this for the oo-secrets>
    #Add OO IDM Admin account to administrators group
    
    #Prepare oo-secrets
    export SMAX_IDM_POD=$(echo `kubectl get pods -n $NS | grep -m1 idm- | head -1 | awk '{print $1}'`) && echo $SMAX_IDM_POD
    export IDM_SIGNING_KEY=$(kubectl exec -it $SMAX_IDM_POD -n $NS -c idm -- bash -c "/bin/get_secret idm_token_signingkey_secret_key itom-bo" | awk -F= '{print$2}') 
    export TRANSPORT_PASS=$(kubectl exec -it $SMAX_IDM_POD -n $NS -c idm -- bash -c "/bin/get_secret idm_transport_admin_password_secret_key" | awk -F= '{print$2}')
    echo $IDM_SIGNING_KEY
    echo $TRANSPORT_PASS
    
    #Generate OO secrets
    /opt/smax/2022.11/scripts/gen_secrets.sh -n oo -c ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/charts/oo-1.0.3+20221101.8.tgz
    
    #Create OO Values
    cp ~/oo/oo_chart/oo-1.0.3+20221101.8/oo-helm-charts/samples/sizing/oo_default_sizing.yaml ~/oo/oo_size_values.yaml
    #vi ~/oo/oo_size_values.yaml

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

    helm upgrade oo -n oo ~/oo/oo_2022.11.P3/oo-helm-charts-1.0.3-20221101P3.1/oo-helm-charts/charts/oo-1.0.3+20221101P3.1.tgz -f ~/oo/oo_2022.11.P3-values.yaml --set global.deploymentType="upgrade" --timeout 30m

    helm upgrade oo -n oo ~/oo/oo_2022.11.P3/oo-helm-charts-1.0.3-20221101P3.1/oo-helm-charts/charts/oo-1.0.3+20221101P3.1.tgz -f ~/oo/oo_2022.11.P3-values.yaml --set global.deploymentType="install" --timeout 30m
