#!/bin/bash

# filename: update-metrics.bash
# author: torrey jones

export version=0
export the_metrics_file=current_metrics.txt

showHelp() {
# `cat << EOF` This means that cat should stop reading when EOF is detected
cat << EOF
Usage: ./update-metrics.bash   [-hrVv]
Install Pre-requisites for EspoCRM with docker in Development mode

-h, -help,          --help                  Display help

-v, -version,       --version               display current version of script

-m, -metric,        --metric                the metric that will be updated; if not provided, all metrics will attempt to be updated. can be comman seperated list (no spaces)
-o, -output,        --output                the output file;  file created if does not exists; metrics will be written as metricname=value in this file

-V, -verbose,       --verbose               Run script in verbose mode. Will print out each step of execution.

-d, -dryrun,       --dryrun                 Run script and collect metrics - but do NOT publish the values

EOF
# EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
}

version() {
  echo $0 version ${version}
}



# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "help,version,verbose,metric:,output:,dryrun" -o "hvVm:o:d" -a -- "$@")

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

if [ -z ${verbose} ]
then
  echo options\=\=\>${options}
fi

while true
do
if [ -z ${verbose} ]
then
  echo 1=\"$1\"
fi
case $1 in
-h|--help)
    showHelp
    exit 0
    ;;
-d|--dryrun)
    export dryrun=1
    echo using dry run
    ;;
-v|--version)
    version
    ;;
-V|--verbose)
    set -xv  # Set xtrace and verbose mode.
    export verbose=1
    ;;
-o|--output)
    export the_metrics_file=$2
    shift
    echo using metrics file ${the_metrics_file}
    ;;
-m|--metric)
    export metric=$2
    shift
    echo using metric\(s\) ${metric}
    ;;
--)
    shift
    break;;
*)
    shift
    break;;
esac
shift
done

function update_the_metrics_file() {
  #set -x
  #echo $1
  #str=$1
  #delimiter=::
  #s=$str$delimiter
  #echo $s
  #array=();
  #while [[ $s ]]; do
      #array+=( "${s%%"$delimiter"*}" );
      #s=${s#*"$delimiter"};
  #done;
  #declare -p array

  IFS='::' read -a myArray <<< "$1"
  #echo ${myArray}
  arrayLength=${#values[@]}
  #for i in {0..${arrayLength}..1} ; do
  #for ((i=0; i<=$arrayLength; i++)); do
  #  echo "i:${i} is ${myArray[i]}"
  #done
  for line in ${myArray[@]}; do
    the_metric_value_pair=${line}
    #need to splie the metric value pair
    the_metric=`echo ${the_metric_value_pair} | awk -F^ {'print $1'}`
    the_value=`echo ${the_metric_value_pair} | awk -F^ {'print $2'}`

    if [ -z ${dryrun} ]
    then
      grep "${the_metric} " ${the_metrics_file} && sed -i "/${the_metric} /c${the_metric} ${the_value}" ${the_metrics_file} || echo ${the_metric} ${the_value} >> ${the_metrics_file}
      if [ -z ${verbose} ]
      then
        echo $?
      fi
    else
      echo no action taken due to dry run
    fi
    echo ${the_metric} ${the_value}
  done
}

function getprovisionUsersStateCount () {
  myMetric=$1
  echo "in getprovisionUsersStateCount ()"
  retString=""
  #need to set PGPASSWORD env variable!!! in kuberenetes pod spec
  #need to set PGUSER env variable!!! in kuberenetes pod spec
  #value=`psql -U $PGUSER -h $DB_HOST -d xservices_ems -c "select relname, n_dead_tup, last_vacuum, last_autovacuum from pg_catalog.pg_stat_all_tables where n_dead_tup > 0 order by n_dead_tup desc limit 5;"`
  #not sure why original/OBM monitoring was running query twice???
  #value2=`psql -U $PGUSER -h $DB_HOST -d xservices_rms -c "select relname, n_dead_tup, last_vacuum, last_autovacuum from pg_catalog.pg_stat_all_tables where n_dead_tup > 0 order by n_dead_tup desc limit 5;"`

  #get list of tenants:
  tenants=$(psql -U maas_admin -h $DB_HOST -d xservices_rms -c "SELECT table_name  FROM information_schema.tables where table_schema = 'maas_admin' and table_name like 'ProvisionUsersState_%'" | grep ProvisionUsersState | awk -F_ '{print $2}')

  for t in $tenants; do
    t_name=ProvisionUsersState_${t}

    sql="select count (*) from maas_admin.\"${t_name}\""
    echo using sql: ${sql}

    IFS=$'\n' read -r -d '' -a values < <(psql -U ${PGUSER} -h ${DB_HOST} -d xservices_rms -c "${sql}")

    tmp=${#values[@]}
    echo tmp: $tmp
    arraylength=$(($tmp-1))
    #start at i=2 because the 1st 2 lines are headers
    #xservices_rms=> SELECT table_name  FROM information_schema.tables where table_schema = 'maas_admin' and table_name like '%ProvisionUser%' ;
          #table_name
    # -------------------------------
    # ProvisionUsersState_983633794
    # WQProvisionUsers_983633794
    # ProvisionUsersState_848749363
    # WQProvisionUsers_848749363
    # ProvisionUsersState_913600845
    # ProvisionUsersState_100000002
    # ProvisionUsersState_328716926
    # ProvisionUsersState_688751407
    # ProvisionUsersState_857561481
    # WQProvisionUsers_913600845
    for ((i=2; i<${arraylength}; i++)); do
      echo "index: $i value:${values[i]}"
      count=`echo ${values[i]} | awk -F \| '{print $1}'| sed 's/ //g'`
      #last_vacuum=`echo ${values[i]} | awk -F \| '{print $4}'| sed 's/\'//g' | sed 's/ /_/g'`
      #last_autovacuum=`echo ${values[i]} | awk -F \| '{print $4}'| sed 's/\'//g' | sed 's/ /_/g'`
      #retString=`echo "${retString}::${myMetric}{table=\"${table}\" last_vacuum=\"${last_vacuum}\" last_autovacuum=\"${last_autovacuum}\"}^${n_dead_tup}"`

      retString=`echo "${retString}::${myMetric}{table=\"${t_name}\"}^${count}"`
    done
  done

    echo ${retString};
    export getprovisionUsersStateCount_RESULT="${retString}"
}

function getSLTsizes () {
  myMetric=$1
  echo "in getSLTsizes()"
  retString=""
  #need to set PGPASSWORD env variable!!! in kuberenetes pod spec
  #need to set PGUSER env variable!!! in kuberenetes pod spec
  #value=`psql -U $PGUSER -h $DB_HOST -d xservices_ems -c "select relname, n_dead_tup, last_vacuum, last_autovacuum from pg_catalog.pg_stat_all_tables where n_dead_tup > 0 order by n_dead_tup desc limit 5;"`
  #not sure why original/OBM monitoring was running query twice???
  #value2=`psql -U $PGUSER -h $DB_HOST -d xservices_rms -c "select relname, n_dead_tup, last_vacuum, last_autovacuum from pg_catalog.pg_stat_all_tables where n_dead_tup > 0 order by n_dead_tup desc limit 5;"`

  #get list of tenants:
  tenants=$(psql -U $PGUSER -h $DB_HOST -d xservices_ems -c "SELECT table_name  FROM information_schema.tables where table_schema = 'maas_admin' and table_name like 'ProvisionUsersState_%'" | grep relations | awk -F_ '{print $2}')

  for t in tenants; do

    sql="select schemaname as table_schema, relname as table_name, pg_size_pretty(pg_total_relation_size(relid)) as total_size, pg_size_pretty(pg_relation_size(relid)) as data_size, pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as external_size from pg_catalog.pg_statio_user_tables where relname LIKE 'slt%' and pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) LIKE '%MB' and pg_size_pretty(pg_total_relation_size(relid)) LIKE '%MB' and pg_size_pretty(pg_relation_size(relid)) LIKE '%MB' order by table_name;"
    echo using sql: ${sql}

    IFS=$'\n' read -r -d '' -a values < <(psql -U ${PGUSER} -h ${DB_HOST} -d xservices_ems -c "${sql}")

    tmp=${#values[@]}
    echo tmp: $tmp
    arraylength=$(($tmp-1))
    #start at i=2 because the 1st 2 lines are headers
    #xservices_rms=> SELECT table_name  FROM information_schema.tables where table_schema = 'maas_admin' and table_name like '%ProvisionUser%' ;
          #table_name
    # -------------------------------
    # ProvisionUsersState_983633794
    # WQProvisionUsers_983633794
    # ProvisionUsersState_848749363
    # WQProvisionUsers_848749363
    # ProvisionUsersState_913600845
    # ProvisionUsersState_100000002
    # ProvisionUsersState_328716926
    # ProvisionUsersState_688751407
    # ProvisionUsersState_857561481
    # WQProvisionUsers_913600845
    for ((i=2; i<${arraylength}; i++)); do
      echo "index: $i value:${values[i]}"
      table=`echo ${values[i]} | awk -F \| '{print $2}'| sed 's/ //g'`
      total_size=`echo ${values[i]} | awk -F \| '{print $3}'| sed 's/ //g'`
      data_size=`echo ${values[i]} | awk -F \| '{print $4}'| sed 's/ //g'`
      external_size=`echo ${values[i]} | awk -F \| '{print $5}'| sed 's/ //g'`
      #last_vacuum=`echlo ${values[i]} | awk -F \| '{print $4}'| sed 's/\'//g' | sed 's/ /_/g'`
      #last_autovacuum=`echo ${values[i]} | awk -F \| '{print $4}'| sed 's/\'//g' | sed 's/ /_/g'`
      #retString=`echo "${retString}::${myMetric}{table=\"${table}\" last_vacuum=\"${last_vacuum}\" last_autovacuum=\"${last_autovacuum}\"}^${n_dead_tup}"`

      retString=`echo "${retString}::${myMetric}{table=\"${table}\" metric=\"total_size\"}^${total_size}"`
      retString=`echo "${retString}::${myMetric}{table=\"${table}\" metric=\"data_size\"}^${data_size}"`
      retString=`echo "${retString}::${myMetric}{table=\"${table}\" metric=\"external_size\"}^${external_size}"`
    done
  done

    echo ${retString};
    export getSLTsizes_RESULT="${retString}"
}

function deadTuplesRMS () {
  myMetric=$1
  #echo ""
  retString=""

  IFS=$'\n' read -r -d '' -a values < <(psql -t -U ${PGUSER} -h ${DB_HOST} -d xservices_rms -c "SELECT relname, n_dead_tup, last_vacuum, last_autovacuum FROM pg_catalog.pg_stat_all_tables WHERE n_dead_tup > 0 ORDER BY n_dead_tup DESC limit 5;")

  tmp=${#values[@]}
  arraylength=$(($tmp-1))

  for ((i=0; i<${arraylength}; i++)); do
    echo "index: $i value:${values[i]}"
    table=`echo ${values[i]} | awk -F \| '{print $1}'| sed 's/ //g'`
    n_dead_tup=`echo ${values[i]} | awk -F \| '{print $2}'| sed 's/ //g'`
    #last_vacuum=`echo ${values[i]} | awk -F \| '{print $4}'| sed 's/\'//g' | sed 's/ /_/g'`
    #last_autovacuum=`echo ${values[i]} | awk -F \| '{print $4}'| sed 's/\'//g' | sed 's/ /_/g'`
    #retString=`echo "${retString}::${myMetric}{table=\"${table}\" last_vacuum=\"${last_vacuum}\" last_autovacuum=\"${last_autovacuum}\"}^${n_dead_tup}"`

    retString=`echo "${retString}::${myMetric}{table=\"${table}\"}^${n_dead_tup}"`
  done

  echo ${retString};
  export deadTuplesRMS_RESULT="${retString}"
}

function getdeadTuples () {
  myMetric=$1
  echo ""
  retString=""
  #need to set PGPASSWORD env variable!!! in kuberenetes pod spec
  #need to set PGUSER env variable!!! in kuberenetes pod spec
  #value=`psql -U $PGUSER -h $DB_HOST -d xservices_ems -c "select relname, n_dead_tup, last_vacuum, last_autovacuum from pg_catalog.pg_stat_all_tables where n_dead_tup > 0 order by n_dead_tup desc limit 5;"`
  #not sure why original/OBM monitoring was running query twice???
  #value2=`psql -U $PGUSER -h $DB_HOST -d xservices_rms -c "select relname, n_dead_tup, last_vacuum, last_autovacuum from pg_catalog.pg_stat_all_tables where n_dead_tup > 0 order by n_dead_tup desc limit 5;"`

  IFS=$'\n' read -r -d '' -a values < <(psql -U ${PGUSER} -h ${DB_HOST} -d xservices_ems -c "select relname, n_dead_tup, last_vacuum, last_autovacuum from pg_catalog.pg_stat_all_tables where n_dead_tup > 0 order by n_dead_tup desc limit 5;")

  tmp=${#values[@]}
  arraylength=$(($tmp-1))
  #start at i=2 because the 1st 2 lines are headers
  #[tjones@smax-west.gitops.com:instrumentation]$ psql -U glgreadonly -h smax-west-rds.gitops.com -d xservices_ems -c "select relname, n_dead_tup, last_vacuum, last_autovacuum from pg_catalog.pg_stat_all_tables where n_dead_tup > 0 order by n_dead_tup desc limit 5;"
        ##relname        | n_dead_tup | last_vacuum |        last_autovacuum
 #-----------------------+------------+-------------+-------------------------------
 #pg_attribute          |      21648 |             | 2021-12-16 00:04:18.367716+00
 #slt_targets_741900393 |      17134 |             | 2022-01-06 16:34:41.401187+00
 #slt_targets_328716926 |       8916 |             | 2022-01-06 16:46:04.582435+00
 #entities_741900393    |       8023 |             | 2021-12-30 22:40:43.691626+00
 #relations_384306602   |       4678 |             | 2021-11-27 16:16:52.59595+00
 #(5 rows)
  for ((i=2; i<${arraylength}; i++)); do
    echo "index: $i value:${values[i]}"
    table=`echo ${values[i]} | awk -F \| '{print $1}'| sed 's/ //g'`
    n_dead_tup=`echo ${values[i]} | awk -F \| '{print $2}'| sed 's/ //g'`
    #last_vacuum=`echo ${values[i]} | awk -F \| '{print $4}'| sed 's/\'//g' | sed 's/ /_/g'`
    #last_autovacuum=`echo ${values[i]} | awk -F \| '{print $4}'| sed 's/\'//g' | sed 's/ /_/g'`
    #retString=`echo "${retString}::${myMetric}{table=\"${table}\" last_vacuum=\"${last_vacuum}\" last_autovacuum=\"${last_autovacuum}\"}^${n_dead_tup}"`

    retString=`echo "${retString}::${myMetric}{table=\"${table}\"}^${n_dead_tup}"`
  done

    echo ${retString};
    export getdeadTuples_RESULT="${retString}"
}

function getBurstCreditBalance() {
  myMetric=$1
  echo ""
  now=
  endtime=`date '+%s'`
  starttime=$(($endtime-300))

  #/usr/local/bin/aws cloudwatch get-metric-data --cli-input-json "{\"MetricDataQueries\": [{\"Id\": \"m1\",\"MetricStat\": {\"Metric\": {\"Namespace\": \"AWS/EFS\",\"MetricName\": \"BurstCreditBalance\",\"Dimensions\": [{\"Name\": \"FileSystemId\",\"Value\": \"fs-22a99b27\"}]},\"Period\": 300,\"Stat\": \"Minimum\"},\"Label\": \"MyLabel1\",\"ReturnData\": true}],\"StartTime\": $starttime, \"EndTime\": $endtime,\"ScanBy\": \"TimestampAscending\",\"MaxDatapoints\": 10}"
  #/usr/lolcal/bin/aws cloudwatch get-metric-statistics --metric-name BurstCreditBalance --start-time $starttime --end-time $endtime --period 300 --namespace AWS/EFS --statistics Minimum --dimensions Name=FileSystemId,Value=fs-22a99b27 --region us-west-2
  #/usr/local/bin/aws cloudwatch get-metric-statistics --metric-name BurstCreditBalance --start-time $starttime --end-time $endtime --period 300 --namespace AWS/EFS --statistics Minimum --dimensions Name=FileSystemId,Value=$AWS_EFS_FILESYSTEM_ID --region us-west-2

  retString=""

  for i in Minimum Maximum Average ; do
      value=`/usr/local/bin/aws cloudwatch get-metric-statistics --metric-name BurstCreditBalance --start-time $starttime --end-time $endtime --period 300 --namespace AWS/EFS --statistics $i --dimensions Name=FileSystemId,Value=$AWS_EFS_FILESYSTEM_ID --region us-west-2 | jq .Datapoints[0].${i} `
      #should come out to 'BurstCreditBalance{stat=Minimum} 2'
      retString=`echo "${retString}::${myMetric}\{stat=${i}\}^${value}"`
      if [ -z ${verbose} ]
      then
        echo value=${value}
        echo updated retString to ${retString}
      fi
  done
    if [ -z ${verbose} ]
    then
      echo ""
    fi
    echo final retString ${retString}

    echo ${retString};
    export getBurstCreditBalance_RESULT="${retString}"
}

function update_metric() {
  the_metric=$1
  value=-1
  echo in function the_metric is ${the_metric}
  case ${the_metric} in
    some2)
      echo we have \"some2\"
      value=1
      retVal=${the_metric} ${value}
      ;;
    some)
      echo we have \"some\"
      value=`echo 1`
      ;;
    BurstCreditBalance)
      echo getBurstCreditBalance
      getBurstCreditBalance ${the_metric}
      retVal=${getBurstCreditBalance_RESULT}
      echo retVal=${retVal}
      if [ -z ${verbose} ]
      then
        echo ""
      fi
      ;;
    deadTuplesRMS)
      deadTuplesRMS ${the_metric}
      retVal=${deadTuplesRMS_RESULT}
      if [ -z ${verbose} ]
      then
        echo getDeadTuplesRMS ${the_metric}
        echo retVal ${retVal}
      fi
      ;;
    deadTuples)
      echo getdeadTuples ${the_metric}
      getdeadTuples ${the_metric}
      #echo here1
      echo ${getdeadTuples_RESULT}
      retVal=${getdeadTuples_RESULT}
      #echo here2
      echo retVal ${retVal}
      #echo here3
      if [ -z ${verbose} ]
      then
        echo ""
      fi
      ;;
    SLTsizes)
      echo getSLTsizes ${the_metric}
      getSLTsizes ${the_metric}
      echo here ${getSLTsizes_RESULT}
      retVal=${getSLTsizes_RESULT}
      echo retVal ${retVal}
      if [ -z ${verbose} ]
      then
        echo ""
      fi
      ;;
    provisionUsersStateCount)
      echo getprovisionUsersStateCount ${the_metric}
      getprovisionUsersStateCount ${the_metric}
      echo here ${getprovisionUsersStateCount_RESULT}
      retVal=${getprovisionUsersStateCount_RESULT}
      echo retVal ${retVal}
      if [ -z ${verbose} ]
      then
        echo ""
      fi
      ;;
    *)
      ;;
  esac

  #echo retval2 ${retVal}
  #for i in 1 2 3 4 5 6 7; do
    #echo foo $i
  #done

  update_the_metrics_file "${retVal[@]}"
  #for fruit in "${retVal[@]}"; do
    #echo bar ${fruit}
    #update_the_metrics_file ${fruit}
  #done
}

for m in `echo ${metric//,/ } `; do
  echo working on metric ${m}
  update_metric ${m}
done
