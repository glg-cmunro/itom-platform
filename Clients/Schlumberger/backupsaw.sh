#!/bin/bash
#suite pgnode
#ns=`kubectl get ns |grep itsma | cut -f1 -d " " `
#kubectl exec $(kubectl get pods -n $ns |grep idm | awk '{print $1}' | head -1) -n $ns -c idm get_secret itom_itsma_dba_password_secret_key | sed 's/PASS=//g'
ab_path=$(dirname "$0")
cd ${ab_path}
export PATH=/opt/db/PostgreSQL/10/bin:$PATH
debug=N
skip=N
while [[ ! -z $1 ]] ; do
    case "$1" in
        -L|--list)
        case "$2" in
            *) skip=Y ; shift 1 ;;
        esac ;;
        -V|--version)
        case "$2" in
            *)  if [[ -z $2 ]] ; then echo "-V|--version  requires a value. " ; exit 1 ; fi ; version=$2 ; shift 2 ;;
        esac ;;
        -D|--debug)
        case "$2" in
            *) debug=Y ; shift 1 ;;
        esac ;;
        *|-*|-h|--help|/?|help) echo "Usage: $0 -S|--skip"
            echo "       -L|--list            Only get information"
            echo "       -V|--version         SMAX version without dot, e.g 202102 stands for 2021.02"
            echo "       -L|--list            Only get information"
            echo "       -D|--debug           Enable debug mode"
            echo "       -h|--help            Show help." ; exit 1 ;;
    esac
done

if [[ $debug == Y ]]; then
    set -x
fi

if [[ -z $version ]]; then
  version=`kubectl get cm -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") itsma-common-configmap -o yaml |grep -v f: |grep itom_suite_version: | awk -F '"' '{print $2}'`
fi

#change version 202002 to 2020.02
#version=${version:0:4}.${version:4:2}

if [[ -f sys_env.sh ]] && [[ $skip != Y ]]; then
  source sys_env.sh
else
  #idm
  #Get IDM pod name
  export idm_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep idm |grep idm |grep -v controller |cut -f1 -d " " |  tail -1`
  #get idm db password
  if [[ ! -z $idm_pod_name ]]; then
    idm_pwd=`kubectl exec  $idm_pod_name  -n $(kubectl get namespace |grep itsma | cut -f1 -d " ")  -c idm  --  get_secret  itom_itsma_db_password_secret_key | sed 's/PASS=//g'`
  fi

  #autopass
  #Get autopassdb pod name
  export autopass_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep autopass |grep -v controller |cut -f1 -d " " |  tail -1`
  #get autopass db password
  if [[ ! -z $autopass_pod_name ]]; then
    autopass_pwd=`kubectl exec  $autopass_pod_name  -n $(kubectl get namespace |grep itsma | cut -f1 -d " ")  -c autopass-lm  -- get_secret  itom_itsma_db_password_secret_key | sed 's/PASS=//g'`
  fi

  #BO
  #Get BO pod name
  export login_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep bo-login | cut -f1 -d " " | tail -1`
  #Get bo database password commands
  if [[ ! -z $login_pod_name ]]; then
    bo_pwd=`kubectl exec $login_pod_name -n $(kubectl get namespace |grep itsma | cut -f1 -d " ")  -c itom-bo-login  -- get_secret itom_itsma_db_password_secret_key itom-bo | sed 's/PASS=//g'`
  fi

  #postgres
  #Get IDM pod name
  export idm_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep idm |grep idm |grep -v controller |cut -f1 -d " " |  tail -1`
  #get idm db password
  if [[ ! -z $idm_pod_name ]]; then
    postgres_pwd=`kubectl exec  $idm_pod_name  -n $(kubectl get namespace |grep itsma | cut -f1 -d " ")  -c idm   -- get_secret  itom_itsma_dba_password_secret_key | sed 's/PASS=//g'`
  fi

  #smarta
  #Get BO pod name
  export login_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep bo-login | cut -f1 -d " "|tail -1`
  #Get bo database password commands
  if [[ ! -z $login_pod_name ]]; then
    smarta_pwd=`kubectl exec $login_pod_name -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") -c itom-bo-login  -- get_secret itom_itsma_db_password_secret_key itom-smartanalytics | sed 's/PASS=//g'`
  fi

  #xservice
  #Get BO pod name
  export login_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep bo-login | cut -f1 -d " "| tail -1`
  #Get bo database password commands
  if [[ ! -z $login_pod_name ]]; then
    xservices_pwd=`kubectl exec $login_pod_name -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") -c itom-bo-login  -- get_secret itom_itsma_db_password_secret_key itom-xruntime-infra | sed 's/PASS=//g'`
  fi

  #dnd
  #Get dnd pod name
  export dnd_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep itom-dnd-instance-management | cut -f1 -d " "| tail -1`
  #Get dnd database password commands
  if [[ ! -z $dnd_pod_name ]]; then
    dnd_pwd=`kubectl exec $dnd_pod_name -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") -c itom-dnd-instance-management -- get_secret itom_itsma_db_password_secret_key itom-dnd | sed 's/PASS=//g'`
  fi

  if [[ -z $dnd_pwd ]]; then
    dnd_pwd=$xservices_pwd
  fi

  #cgro
  #Get cgro pod name
  export cgro_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep itom-cmp-accounts | cut -f1 -d " "| tail -1`
  #Get cgro database password commands
  if [[ ! -z $cgro_pod_name ]]; then
    cgro_pwd=`kubectl exec $cgro_pod_name -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") -c itom-cmp-accounts -- get_secret itom_itsma_db_password_secret_key itom-cgro | sed 's/PASS=//g'`
  fi

  if [[ -z $cgro_pwd ]]; then
    cgro_pwd=$xservices_pwd
  fi

  #sam
  #Get sam pod name
  export sam_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep sam-backend-deployment | cut -f1 -d " "| tail -1`
  #Get sam database password commands
  if [[ ! -z $sam_pod_name ]]; then
    sam_pwd=`kubectl exec $sam_pod_name -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") -c sam-service -- get_secret itom_itsma_db_password_secret_key itom-sam | sed 's/PASS=//g'`
  fi

  if [[ -z $sam_pwd ]]; then
    sam_pwd=$xservices_pwd
  fi

  db_server=`kubectl get cm -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") database-configmap -o yaml |grep idm |grep -i host |grep -v f: |grep -v apiVersion |awk '{print $2}' | head -1`
  if [[ -z $db_server ]]; then
    echo "Error: Cannot get DB Server, exit ..."
    exit 1
  fi

  db_port=`kubectl get cm -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") database-configmap -o yaml |grep idm |grep -i port |grep -v f: |grep -v apiVersion |awk '{print $2}'  |sed 's/"//g' | head -1`
  if [[ -z $db_port ]]; then
    echo "Error: Cannot get DB Port, exit ..."
    exit 1
  fi
  if [[ -z $idm_pwd ]] || [[ -z $bo_pwd ]] || [[ -z $postgres_pwd ]] || [[ -z smarta_pwd ]] || [[ -z xservices_pwd ]] || [[ -z autopass_pwd ]]; then
    echo "Fata error: Password is empty!"
  else
    echo -e "db_server=$db_server\ndb_port=$db_port\nidm_pwd=$idm_pwd\nbo_pwd=$bo_pwd\npostgres_pwd=$postgres_pwd\nsmarta_pwd=$smarta_pwd\nxservices_pwd=$xservices_pwd\nautopass_pwd=$autopass_pwd\ndnd_pwd=$dnd_pwd\nsam_pwd=$sam_pwd\ncgro_pwd=$cgro_pwd" > sys_env.sh
  fi
fi

echo ---------------------------
echo -e "db_server=$db_server\ndb_port=$db_port\nidm_pwd=$idm_pwd\nbo_pwd=$bo_pwd\npostgres_pwd=$postgres_pwd\nsmarta_pwd=$smarta_pwd\nxservices_pwd=$xservices_pwd\nautopass_pwd=$autopass_pwd\ndnd_pwd=$dnd_pwd\nsam_pwd=$sam_pwd\ncgro_pwd=$cgro_pwd"
echo ---------------------------
if [[ $skip == Y ]]; then
  exit 0
fi

if [[ -z $idm_pwd ]] || [[ -z $bo_pwd ]] || [[ -z $postgres_pwd ]] || [[ -z smarta_pwd ]] || [[ -z xservices_pwd ]] || [[ -z autopass_pwd ]]; then
  echo "Fata error: one of above password is empty, please set the password correctly and continue"
  exit 1
fi

pg_dump_file=$(rpm -qa|grep postgres|xargs rpm -ql|grep bin|grep pg_dump|grep -v all|head -1)
export PATH=$PATH:`dirname ${pg_dump_file}`

function printdt()
{
  if [ ! -d logs ]; then
    mkdir logs
  fi
  DATE=`date '+%Y-%m-%d %H:%M:%S'`
  if [ ! -f ./logs/backup.log ]; then
    touch ./logs/backup.log
  fi
  echo $1 $DATE >>./logs/backup.log
}

function backupidm()
{
  export PGDATABASE=autopassdb
  export PGPASSWORD=${autopass_pwd}
  printdt "autopass begin at"
  pg_dump -U autopass -h ${db_server} -p $db_port -F c -w autopassdb -f autopass.dump
  if [[ $? != 0 ]]; then
    rm -rf autopass.dump
    echo "Error to export autopass.dump, exit ..."
    exit 1
  fi
  printdt "autopass end at"
}

function backupautopass()
{
  export PGDATABASE=idm
  export PGPASSWORD=${idm_pwd}
  printdt "idm begin at"
  #psql -U postgres -c "alter user idm with password 'Idm_1234'"
  pg_dump -U idm -h ${db_server} -p $db_port -F c -w idm -f idm.dump
  if [[ $? != 0 ]]; then
    rm -rf idm.dump
    echo "Error to export idm.dump, exit ..."
    exit 1
  fi
  printdt "idm end at"
}

function backupbo()
{
  printdt "Begin Dump bo databases.."
  export PGPASSWORD=${bo_pwd}

  export PGDATABASE=bo_ats
  printdt "bo_ats begin at"
  psql -U bo_db_user  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U bo_db_user  -h ${db_server} -p $db_port -F c -w bo_ats -f bo_ats.dump
  if [[ $? != 0 ]]; then
    rm -rf bo_ats.dump
    echo "Error to export bo_ats.dump, exit ..."
    exit 1
  fi
  printdt "bo_ats end at"

  printdt "bo_config begin at "
  export PGDATABASE=bo_config
  psql -U bo_db_user  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U bo_db_user  -h ${db_server} -p $db_port -F c -w bo_config -f bo_config.dump
  if [[ $? != 0 ]]; then
    rm -rf bo_config.dump
    echo "Error to export bo_config.dump, exit ..."
    exit 1
  fi
  printdt "bo_config end at"

  printdt "bo_license begin at"
  export PGDATABASE=bo_license
  psql -U bo_db_user  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U bo_db_user  -h ${db_server} -p $db_port -F c -w bo_license -f bo_license.dump
    if [[ $? != 0 ]]; then
    rm -rf bo_license.dump
    echo "Error to export bo_license.dump, exit ..."
    exit 1
  fi
  printdt "bo_license end at"

  printdt "bo_user begin at"
  export PGDATABASE=bo_user
  psql -U bo_db_user  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U bo_db_user  -h ${db_server} -p $db_port -F c -w bo_user -f bo_user.dump
    if [[ $? != 0 ]]; then
    rm -rf bo_user.dump
    echo "Error to export bo_user.dump, exit ..."
    exit 1
  fi
  printdt "bo_user end at"
}

function backupdnd()
{
  printdt "Begin Dump dnd databases.."
  export PGPASSWORD=${dnd_pwd}

  export PGDATABASE=oo
  printdt "oo begin at"
  psql -U hcm_admin  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U hcm_admin  -h ${db_server} -p $db_port -F c -w oo -f oo.dump
    if [[ $? != 0 ]]; then
    rm -rf oo.dump
    echo "Error to export oo.dump, exit ..."
    exit 1
  fi
  printdt "dnd end at"

  printdt "dnd begin at "
  export PGDATABASE=dnd
  psql -U hcm_admin  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U hcm_admin  -h ${db_server} -p $db_port -F c -w dnd -f dnd.dump
  if [[ $? != 0 ]]; then
    rm -rf dnd.dump
    echo "Error to export dnd.dump, exit ..."
    exit 1
  fi
  printdt "dnd end at "

  printdt "oodesigner begin at"
  export PGDATABASE=oodesigner
  psql -U hcm_admin  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U hcm_admin  -h ${db_server} -p $db_port -F c -w oodesigner -f oodesigner.dump
  if [[ $? != 0 ]]; then
    rm -rf oodesigner.dump
    echo "Error to export oodesigner.dump, exit ..."
    exit 1
  fi
  printdt "oodesigner end at"
}

function backupsam()
{
  printdt "Begin Dump sam databases.."
  export PGPASSWORD=${sam_pwd}

  export PGDATABASE=sam
  printdt "sam begin at"
  psql -U sam  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U sam  -h ${db_server} -p $db_port -F c -w sam -f sam.dump
  if [[ $? != 0 ]]; then
    rm -rf sam.dump
    echo "Error to export sam.dump, exit ..."
    exit 1
  fi
  printdt "sam end at"
}


function backupcgro()
{
  printdt "Begin Dump sam databases.."
  export PGPASSWORD=${cgro_pwd}

  export PGDATABASE=cgro
  printdt "cgro begin at"
  psql -U cgro  -h ${db_server} -p $db_port  -c 'COMMENT ON EXTENSION plpgsql IS null'
  pg_dump -U cgro  -h ${db_server} -p $db_port -F c -w cgro -f cgro.dump
  if [[ $? != 0 ]]; then
    rm -rf cgro.dump
    echo "Error to export cgro.dump, exit ..."
    exit 1
  fi
  printdt "cgro end at"
}

function backupsaw()
{
  printdt "Begin Dump SAW databases.."
  export PGPASSWORD=${xservices_pwd}

  #psql -U postgres  -h ${db_server} -p $db_port  -c "alter user maas_admin with password 'propeldbUse_1erpassword'"
  export PGDATABASE=maas_admin
  printdt "maas_admin begin at"
  pg_dump -U maas_admin  -h ${db_server} -p $db_port -F c -w maas_admin -f maas_admin.dump
  if [[ $? != 0 ]]; then
    rm -rf maas_admin.dump
    echo "Error to export maas_admin.dump, exit ..."
    exit 1
  fi
  printdt "maas_admin end at"

  printdt "xservices_ems begin at"
  export PGDATABASE=xservices_ems
  pg_dump -U maas_admin  -h ${db_server} -p $db_port -F c -w xservices_ems -f xservices_ems.dump
  if [[ $? != 0 ]]; then
    rm -rf xservices_ems.dump
    echo "Error to export xservices_ems.dump, exit ..."
    exit 1
  fi
  printdt "xservices_ems end at"

  printdt "xservices_mng begin at"
  export PGDATABASE=xservices_mng
  pg_dump -U maas_admin  -h ${db_server} -p $db_port -F c -w xservices_mng -f xservices_mng.dump
  if [[ $? != 0 ]]; then
    rm -rf xservices_mng.dump
    echo "Error to export xservices_mng.dump, exit ..."
    exit 1
  fi
  printdt "xservices_mng end at"

  printdt "xservices_rms begin at"
  export PGDATABASE=xservices_rms
  pg_dump -U maas_admin  -h ${db_server} -p $db_port -F c -w xservices_rms -f xservices_rms.dump -T "public.\"Audit_100000002\"" -T "public.\"Audit_857561481\"" -T "public.\"Audit_355598545\"" -T "public.\"Audit_EmptyTenant\"" -T "public.\"Audit_TenantForUpgrade\""
  if [[ $? != 0 ]]; then
    rm -rf xservices_rms.dump
    echo "Error to export xservices_rms.dump, exit ..."
    exit 1
  fi
  printdt "xservices_rms end at"
}

function backupsmarta()
{
  printdt "Begin Dump smarta databases.."
  export PGPASSWORD=${smarta_pwd}
  export PGDATABASE=smartadb
  pg_dump -U smarta -h ${db_server} -p $db_port -F c -w smartadb -f smartadb.dump
  if [[ $? != 0 ]]; then
    rm -rf smartadb.dump
    echo "Error to export smartadb.dump, exit ..."
    exit 1
  fi
  printdt "smarta end at "
}

#main function
backupidm
backupautopass
backupsaw
backupsmarta
backupbo
dnd_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep itom-dnd-instance-management | cut -f1 -d " "| tail -1`
if [[ ! -z $dnd_pod_name ]]; then
  backupdnd
fi
cgro_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep itom-cmp-accounts | cut -f1 -d " "| tail -1`
if [[ ! -z $cgro_pod_name ]]; then
  backupcgro
fi
sam_pod_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep sam-backend-deployment | cut -f1 -d " "| tail -1`
if [[ ! -z $sam_pod_name ]]; then
  backupsam
fi

#package the db dump file
datest=`date +%Y%m%d%H%M`

tar -cvzf db_dump_${version}_${datest}.tgz *.dump

#Move package file to relevant path
if [[ $CONTAINER == true ]]; then
  mv db_dump_${version}_${datest}.tgz /var/log
  echo "The package located at /var/log/db_dump_${version}_${datest}.tgz"
else
  mv db_dump_${version}_${datest}.tgz ~/
  echo "The package located at ~/db_dump_${version}_${datest}.tgz"
fi
