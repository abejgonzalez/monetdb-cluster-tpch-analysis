#!/bin/bash

set -ex

# Run query in DBNAME=$1 SQL_QUERY=$2.
#  - Delete the profiling logs from before
#  - Run query
#  - Copy back results of profiling and put it in unique folder

# copy files from server to server
# $1 - src
# $2 - dest
copy () {
    rsync -azp -e 'ssh' $1 $2
}

# run command over ssh
# $1 - server login (user@IP)
# $2 - command
run_impl () {
    ssh -t -o "StrictHostKeyChecking no" $1 $2
}

# run command on build server
# $1 - command
run () {
    SERVER=$1
    shift
    run_impl $SERVER "$@"
}

# TODO: for some reason cant do -dm in screen (leads to dead session)
run_ps () {
    SRVR=$1
    shift
    DB=$1
    shift
    FILE_PATH=$1
    run $SRVR "rm -rf $FILE_PATH"
    expect -c "spawn ssh -t $SRVR screen -m -S ps-session \"pystethoscope -d $DB -o $FILE_PATH\"
    sleep 0.5
    send -- \"d\"
    expect eof"
}

REMOTE_WORK_DIR=$HOME/monetdb-cluster-tpch-analysis
QUERY_FILE=$2
DB_NAME=$1
BASE_NAME=$(basename $QUERY_FILE .sql)

ip_addr_arr=()
readarray ip_addr_arr < follower-ipaddrs.txt

rm -rf ps-log.txt
screen -dmS ps-screen pystethoscope -d leader-db -o ps-log.txt
for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    ip_addr=$(echo "$ip_addr" | xargs)
    run_ps $ip_addr $DB_NAME $REMOTE_WORK_DIR/ps-log.txt
done

mkdir -p results/$BASE_NAME

mclient -d leader-db -f raw -w 80 -i < $QUERY_FILE > results/$BASE_NAME/out

for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    ip_addr=$(echo "$ip_addr" | xargs)
    copy $ip_addr:$REMOTE_WORK_DIR/ps-log.txt results/$BASE_NAME/${addr_idx}-ps-log.txt
    run $ip_addr "pkill screen"
done
cp ps-log.txt results/$BASE_NAME/leader-ps-log.txt
pkill screen

echo "Done running $1"
