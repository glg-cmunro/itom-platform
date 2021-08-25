#!/bin/bash
SECONDS=0
ab_path=$(dirname "$0")
cd ${ab_path}
export PATH=/usr/pgsql-11/bin/:$PATH
debug=N
skip=N
if [ $# -eq 0 ]; then
    $0 -R all
fi

if [ ! -d logs ]; then
  mkdir logs
fi

while [[ ! -z $1 ]] ; do
    case "$1" in
        --debug)
        case "$2" in
            *) debug=Y ; shift 1 ;;
        esac ;;
        -C|--creatuser)
        case "$2" in
            *)  creatuser=Y ; shift 1 ;;
        esac ;;
        -D|--delete)
        case "$2" in
            *)  deleteuser=Y ; shift 1 ;;
        esac ;;
        -R|--restore)
        case "$2" in
            *)  if [[ -z $2 ]] ; then echo "-R|--restore  requires a value. " ; exit 1 ; fi ; restore=$2 ; shift 2 ;;
        esac ;;
        *|-*|-h|--help|/?|help) echo "Usage: $0 -C|--creatuser"
            echo "       -R|--restore         To restore the db: value is idm/xservice/bo/smarta/dnd/cgro/sam/all"
            echo "       -C|--creatuser       Create user for new DB"
            echo "       -D|--delete          Delete database user"
            echo "       --debug              Enable debug mode"
            echo "       -h|--help            Show help." ; exit 1 ;;
    esac
done
if [[ $debug == Y ]]; then
    set -x
fi

function get_db_info() {
  ################# Modify below section to input new parameter ##################
  if [[ -f sys_env.sh ]]; then
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
    #get db_server name for interal DB
    export pgnode_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep pgnode | cut -f1 -d " " | tail -1`
    if [[ -z $pgnode_name ]]; then
      export pgnode_name=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") |grep singletonpg | cut -f1 -d " " | tail -1`
    fi

    db_server=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") -o wide |grep $pgnode_name  | awk '{print $6}' | tail -1`
    if [[ -z $db_server ]]; then
      db_server=`kubectl get cm -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") database-configmap -o yaml |grep idm |grep -i host |grep -v f: |grep -v apiVersion |awk '{print $2}' | head -1`
    fi

    db_port=`kubectl get pods -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") -o wide |grep $pgnode_name  | awk '{print $6}' | tail -1`
    if [[ -z $db_port ]]; then
      db_port=`kubectl get cm -n $(kubectl get namespace |grep itsma | cut -f1 -d " ") database-configmap -o yaml |grep idm |grep -i port |grep -v f: |grep -v apiVersion |awk '{print $2}'  |sed 's/"//g' | head -1`
    fi
  fi

  echo ---------------------------
  echo -e "db_server=$db_server\ndb_port=$db_port\nidm_pwd=$idm_pwd\nbo_pwd=$bo_pwd\npostgres_pwd=$postgres_pwd\nsmarta_pwd=$smarta_pwd\nxservices_pwd=$xservices_pwd\nautopass_pwd=$autopass_pwd\ndnd_pwd=$dnd_pwd\nsam_pwd=$sam_pwd\ncgro_pwd=$cgro_pwd"
  echo ---------------------------
  if [[ -z $idm_pwd ]] || [[ -z $bo_pwd ]] || [[ -z $smarta_pwd ]] || [[ -z $xservices_pwd ]] || [[ -z $autopass_pwd ]]; then
    echo -e "idm_pwd=$idm_pwd\nbo_pwd=$bo_pwd\nsmarta_pwd=$smarta_pwd\nxservices_pwd=$xservices_pwd\nautopass_pwd=$autopass_pwd\ndnd_pwd=$dnd_pwd\nsam_pwd=$sam_pwd\ncgro_pwd=$cgro_pwd"
    echo "Error: one of above password(s) is emtyp, exit ..."
    exit 1
  else
    echo -e "db_server=$db_server\ndb_port=$db_port\nidm_pwd=$idm_pwd\nbo_pwd=$bo_pwd\npostgres_pwd=$postgres_pwd\nsmarta_pwd=$smarta_pwd\nxservices_pwd=$xservices_pwd\nautopass_pwd=$autopass_pwd\ndnd_pwd=$dnd_pwd\nsam_pwd=$sam_pwd\ncgro_pwd=$cgro_pwd" > sys_env.sh
  fi
}

function deleteuser()
{
  export PATH=/usr/pgsql-11/bin/:$PATH

  export PGPASSWORD=${idm_pwd}
  psql -U idm -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'idm';"
  dropdb idm  --port $db_port  -h ${db_server}  -U idm -w

  export PGPASSWORD=${bo_pwd}
  psql -U bo_db_user -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'bo_ats';"
  psql -U bo_db_user -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'bo_user';"
  psql -U bo_db_user -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'bo_config';"
  psql -U bo_db_user -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'bo_license';"
  dropdb bo_ats --port $db_port -h ${db_server} -U bo_db_user -w
  dropdb bo_user  --port $db_port -h ${db_server} -U bo_db_user -w
  dropdb bo_config --port $db_port -h ${db_server}  -U bo_db_user -w
  dropdb bo_license --port $db_port -h ${db_server}  -U bo_db_user -w

  export PGPASSWORD=${xservices_pwd}
  psql -U maas_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'xservices_rms';"
  psql -U maas_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'xservices_ems';"
  psql -U maas_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'xservices_mng';"
  psql -U maas_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'xservices_admin';"
  psql -U maas_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'maas_template';"
  psql -U maas_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'sxdb';"
  dropdb xservices_rms  --port $db_port  -h ${db_server}  -U maas_admin -w
  dropdb xservices_mng  --port $db_port -h ${db_server}  -U maas_admin -w
  dropdb xservices_ems  --port $db_port -h ${db_server}  -U maas_admin -w
  dropdb maas_admin  --port $db_port  -h ${db_server}  -U maas_admin -w
  dropdb maas_template  --port $db_port  -h ${db_server}  -U maas_admin -w
  dropdb sxdb  --port $db_port  -h ${db_server}  -U maas_admin -w

  export PGPASSWORD=${smarta_pwd}
  psql -U smarta -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'smartadb';"
  dropdb smartadb  --port $db_port  -h ${db_server}  -U smarta -w

  export PGPASSWORD=${autopass_pwd}
  psql -U autopass -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'autopassdb';"
  dropdb autopassdb  --port $db_port  -h ${db_server}  -U autopass -w

  export PGPASSWORD=${sam_pwd}
  psql -U sam -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'sam';"
  dropdb sam  --port $db_port  -h ${db_server}  -U sam -w

  export PGPASSWORD=${cgro_pwd}
  psql -U cgro -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'cgro';"
  dropdb cgro  --port $db_port  -h ${db_server}  -U cgro -w

  export PGPASSWORD=${dnd_pwd}
  psql -U hcm_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'oo';"
  dropdb oo --port $db_port  -h ${db_server}  -U hcm_admin -w
  psql -U hcm_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'dnd';"
  dropdb dnd  --port $db_port  -h ${db_server}  -U hcm_admin -w
  psql -U hcm_admin -h $db_server -p $db_port -d postgres -c "SELECT pg_terminate_backend(pid) FROM  pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = 'oodesigner';"
  dropdb oodesigner  --port $db_port  -h ${db_server}  -U hcm_admin -w


  export PGPASSWORD=${postgres_pwd}
  dropuser idm --port $db_port -h ${db_server} -U postgres -w
  dropuser bo_db_user --port $db_port -h ${db_server} -U postgres -w
  dropuser maas_admin --port $db_port -h ${db_server} -U postgres -w
  dropuser smarta --port $db_port -h ${db_server} -U postgres -w
  dropuser autopass --port $db_port -h ${db_server} -U postgres -w
  dropuser sam --port $db_port -h ${db_server} -U postgres -w
  dropuser cgro --port $db_port -h ${db_server} -U postgres -w
  dropuser hcm_admin --port $db_port -h ${db_server} -U postgres -w
}

function creatuser()
{
  export PGPASSWORD=${postgres_pwd}
  psql -U postgres -h $db_server -p $db_port -d postgres -c "CREATE USER idm login PASSWORD '$idm_pwd';"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER idm CREATEDB;"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER idm CREATEROLE;"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "CREATE USER maas_admin login PASSWORD '$xservices_pwd';"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER maas_admin CREATEDB;"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "CREATE USER bo_db_user login PASSWORD '$bo_pwd';"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER bo_db_user CREATEDB;"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "CREATE USER autopass login PASSWORD '$autopass_pwd';"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER autopass CREATEDB;"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "CREATE USER smarta login PASSWORD '$smarta_pwd';"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER smarta CREATEDB;"

  psql -U postgres -h $db_server -p $db_port -d postgres -c "CREATE USER hcm_admin login PASSWORD '$dnd_pwd';"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER hcm_admin CREATEDB;"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "CREATE USER sam login PASSWORD '$sam_pwd';"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER sam CREATEDB;"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "CREATE USER cgro login PASSWORD '$cgro_pwd';"
  psql -U postgres -h $db_server -p $db_port -d postgres -c "ALTER USER cgro CREATEDB;"
}

function printdt()
{
  if [ ! -d logs ]; then
    mkdir logs
  fi
  DATE=`date '+%Y-%m-%d %H:%M:%S'`
  echo $1 $DATE
}

function restore_idm()
{
  export PGPASSWORD=${idm_pwd}
  printdt "Begin restore idm databases.." >logs/idm.log
  psql -h ${db_server} -p $db_port -U idm -d postgres -c 'drop database idm'
  psql -h ${db_server} -p $db_port -U idm -d postgres -c 'create database idm with owner idm'
  pg_restore  -j 8  -h ${db_server} -p $db_port -U idm -Fc idm.dump -d idm >/dev/null 2>>logs/idm.log
  printdt "end restore idm at " >>logs/idm.log
}

function restore_autopass()
{
  export PGPASSWORD=${autopass_pwd}
  printdt "Begin restore autopass databases.." >logs/autopass.log
  psql -h ${db_server} -p $db_port -U autopass -d postgres -c 'drop database autopassdb'
  psql -h ${db_server} -p $db_port -U autopass -d postgres -c 'create database autopassdb with owner autopass'
  pg_restore  -j 8  -h ${db_server} -p $db_port -U autopass -Fc autopass.dump -d autopassdb >/dev/null 2>>logs/autopass.log
  printdt "end restore autopass at " >>logs/autopass.log
}


function restore_bo()
{
  #bo_db_user has no "Create DB" priviledge.
  #bo_db_user granted to postgres (grant bo_db_user to postgres). postgres can created db with owner bo_db_user.
  #Feb:db-owner: bo_db_user; schema-owner(public):postgres; tables-owner: bo_db_users;

  export PGPASSWORD=${bo_pwd}

  psql -h ${db_server} -p $db_port -U bo_db_user -d bo_ats -c 'drop database bo_ats'
  psql -h ${db_server} -p $db_port -U bo_db_user -d bo_config -c 'drop database bo_config'
  psql -h ${db_server} -p $db_port -U bo_db_user -d bo_license -c 'drop database bo_license'
  psql -h ${db_server} -p $db_port -U bo_db_user -d bo_user -c 'drop database bo_user'

  psql -h ${db_server} -p $db_port -U bo_db_user -d postgres -c 'create database bo_ats with owner bo_db_user'
  psql -h ${db_server} -p $db_port -U bo_db_user -d postgres -c 'create database bo_config with owner bo_db_user'
  psql -h ${db_server} -p $db_port -U bo_db_user -d postgres -c 'create database bo_license with owner bo_db_user'
  psql -h ${db_server} -p $db_port -U bo_db_user -d postgres -c 'create database bo_user with owner bo_db_user'

  export PGDATABASE=bo_ats
  printdt "Begin restore bo_ats databases.." >logs/bo_ats.log
  pg_restore  -j 8  -h ${db_server} -p $db_port -Fc bo_ats.dump  -d bo_ats -U bo_db_user >/dev/null 2>>logs/bo_ats.log
  printdt "End restore bo_ats databases.." >>logs/bo_ats.log

  printdt "Begin restore bo_config databases.." >logs/bo_config.log
  export PGDATABASE=bo_config
  pg_restore -j 8 -h ${db_server} -p $db_port -Fc bo_config.dump  -d bo_config -U bo_db_user >/dev/null 2>>logs/bo_config.log
  printdt "End restore bo_config databases.." >>logs/bo_config.log

  printdt "Begin restore bo_license databases.." >logs/bo_license.log
  export PGDATABASE=bo_license
  pg_restore  -j 8  -h ${db_server} -p $db_port -Fc bo_license.dump  -d bo_license -U bo_db_user >/dev/null 2>>logs/bo_license.log
  printdt "End restore bo_config databases.." >>logs/bo_license.log

  printdt "Begin restore bo_user databases.." >logs/bo_user.log
  export PGDATABASE=bo_user
  pg_restore  -j 8  -h ${db_server} -p $db_port -Fc bo_user.dump  -d bo_user -U bo_db_user >/dev/null 2>>logs/bo_user.log
  printdt "end restore bo database at " >>logs/bo_user.log
}

function restore_xservice()
{
  export PGPASSWORD=${xservices_pwd}

  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'grant maas_admin to postgres'

  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'drop database maas_admin'
  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'drop database xservices_ems'
  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'drop database xservices_rms'
  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'drop database xservices_mng'

  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'create database maas_admin with owner maas_admin'
  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'create database xservices_ems with owner maas_admin'
  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'create database xservices_rms with owner maas_admin'
  psql -h ${db_server}   -p $db_port -U maas_admin -d postgres -c 'create database xservices_mng with owner maas_admin'

  printdt "Begin restore maas_admin databases.." > logs/maas_admin.log
  export PGDATABASE=maas_admin
  pg_restore  -j 8  -h ${db_server} -p $db_port -U maas_admin -d maas_admin -Fc maas_admin.dump >/dev/null 2>>logs/maas_admin.log
  printdt "end restore maas_admin at" >>logs/maas_admin.log

  export PGDATABASE=xservices_ems
  printdt "Begin restore xservices_ems databases.." >logs/xservices_ems.log
  pg_restore  -j 8  -h ${db_server} -p $db_port -U maas_admin -d xservices_ems -Fc xservices_ems.dump >/dev/null 2>>logs/xservices_ems.log
  printdt "end restore xservice_ems at" >>logs/xservices_ems.log

  export PGDATABASE=xservices_rms
  printdt "Begin restore xservices_rms databases.." >logs/xservices_rms.log
  pg_restore  -j 8  -h ${db_server} -p $db_port -U maas_admin -d xservices_rms -Fc xservices_rms.dump >/dev/null 2>>logs/xservices_rms.log
  printdt "end restore xservice_rms at" >>logs/xservices_rms.log

  export PGDATABASE=xservices_mng
  printdt "Begin restore xservices_mng databases.." >logs/xservices_mng.log
  pg_restore  -j 8  -h ${db_server} -p $db_port -U maas_admin -d xservices_mng -Fc xservices_mng.dump >/dev/null 2>>logs/xservices_mng.log
  printdt "end restore xservice_mng at" >>logs/xservices_mng.log

}

function restore_smarta()
{
  export PGPASSWORD=${smarta_pwd}
  printdt "Begin restore smarta databases.." >logs/smarta.log
  psql -h ${db_server}   -p $db_port -U smarta -d postgres -c 'drop database smartadb'
  psql -h ${db_server}   -p $db_port -U smarta -d postgres -c 'create database smartadb with owner smarta'
  pg_restore  -j 8  -h ${db_server} -p $db_port -U smarta -Fc smartadb.dump -d smartadb >/dev/null 2>>logs/smarta.log
  printdt "end restore smarta at " >>logs/smarta.log
}


function restore_sam()
{
  export PGPASSWORD=${sam_pwd}
  printdt "Begin restore sam databases.." >logs/sam.log
  psql -h ${db_server}   -p $db_port -U sam -d postgres -c 'drop database sam'
  psql -h ${db_server}   -p $db_port -U sam -d postgres -c 'create database sam with owner sam'
  export PGPASSWORD=${postgres_pwd}
  pg_restore  -j 8  -h ${db_server} -p $db_port -U postgres -Fc sam.dump -d sam >/dev/null 2>>logs/sam.log
  printdt "end restore sam at " >>logs/sam.log
}


function restore_cgro()
{
  export PGPASSWORD=${cgro_pwd}
  printdt "Begin restore cgro databases.." >logs/cgro.log
  psql -h ${db_server}   -p $db_port -U cgro -d postgres -c 'drop database cgro'
  psql -h ${db_server}   -p $db_port -U cgro -d postgres -c 'create database cgro with owner cgro'
  export PGPASSWORD=${postgres_pwd}
  pg_restore  -j 8  -h ${db_server} -p $db_port -U postgres -Fc cgro.dump -d cgro >/dev/null 2>>logs/cgro.log
  printdt "end restore cgro at " >>logs/cgro.log
}


function restore_dnd()
{
  export PGPASSWORD=${dnd_pwd}
  printdt "Begin restore dnd databases.." >logs/dnd.log
  psql -h ${db_server}   -p $db_port -U hcm_admin -d postgres -c 'drop database oo'
  psql -h ${db_server}   -p $db_port -U hcm_admin -d postgres -c 'create database oo with owner hcm_admin'
  pg_restore  -j 8  -h ${db_server} -p $db_port -U hcm_admin -Fc oo.dump -d oo >/dev/null 2>>logs/dnd.log

  psql -h ${db_server}   -p $db_port -U hcm_admin -d postgres -c 'drop database dnd'
  psql -h ${db_server}   -p $db_port -U hcm_admin -d postgres -c 'create database dnd with owner hcm_admin'
  pg_restore  -j 8  -h ${db_server} -p $db_port -U hcm_admin -Fc dnd.dump -d dnd >/dev/null 2>>logs/dnd.log

  psql -h ${db_server}   -p $db_port -U hcm_admin -d postgres -c 'drop database oodesigner'
  psql -h ${db_server}   -p $db_port -U hcm_admin -d postgres -c 'create database oodesigner with owner hcm_admin'
  pg_restore  -j 8  -h ${db_server} -p $db_port -U hcm_admin -Fc oodesigner.dump -d oodesigner >/dev/null 2>>logs/dnd.log

  printdt "end restore dnd at " >>logs/dnd.log

}

function restore_all()
{
  ./backsaw.sh -L
  $0 -D
  $0 -D
  sleep 1
  $0 -D
  $0 -C
  restore_smarta
  restore_idm
  restore_xservice
  restore_bo
  restore_autopass
  restore_sam
  restore_cgro
  restore_dnd
  echo "DB is restored successfully"
}

function restore()
{
  arg=$1
  if [[ $arg == smartadb ]]; then
    get_db_info
    restore_smarta
  elif [[ $arg == idm ]]; then
    get_db_info
    restore_idm
  elif [[ $arg == autopass ]]; then
    get_db_info
    restore_autopass
  elif [[ $arg == xservice ]]; then
    get_db_info
    restore_xservice
  elif [[ $arg == bo ]]; then
    get_db_info
    restore_bo
  elif [[ $arg == smarta ]]; then
    get_db_info
    restore_smarta
  elif [[ $arg == sam ]]; then
    get_db_info
    restore_sam
  elif [[ $arg == cgro ]]; then
    get_db_info
    restore_cgro
  elif [[ $arg == dnd ]]; then
    get_db_info
    restore_dnd
  elif [[ $arg == all ]]; then
    get_db_info
    restore_all
  else
    echo "Error: wrong parameter for restore!"
    $0 help
    exit;
  fi
}
# main function
if [[ $creatuser == Y ]]; then
  get_db_info
  creatuser
  exit 0
fi

if [[ $deleteuser == Y ]]; then
  get_db_info
  deleteuser
  exit 0
fi

if [[ ! -z $restore ]]; then
  restore $restore
fi

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
