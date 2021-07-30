#!/bin/bash

set -e

# library of remote helper functions
source remote-helper.sh

# Run query in DBNAME=$1 SQL_QUERY=$2.
#  - Delete the profiling logs from before
#  - Run query
#  - Copy back results of profiling and put it in unique folder

usage() {
    echo "Usage: $0 -d <remote DB name> [-v] [-np] -q <sql query>"
    echo "Run SQL query on TPC-H cluster"
    echo ""
    echo "Options:"
    echo "  -h                  Print this help"
    echo "  -d <remote DB name> Remote DB name to attach the profiler to"
    echo "  -v                  Enable verbose logging"
    echo "  -np                 Disable profiling"
    echo "  -q                  SQL to run"
}

QUERY_FILE=
DB_NAME=
VERBOSE=
PROFILE_DISABLE=

while [ "$#" -gt 0 ]; do
    case "$1" in
        -d)
            DB_NAME=$2
            shift
            shift
            ;;
        -v)
            VERBOSE="true"
            shift
            ;;
        -np)
            PROFILE_DISABLE="true"
            shift
            ;;
        -q)
            QUERY_FILE=$2
            shift
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "$0: Unknown parameter $1"
            usage
            exit 1
            ;;
    esac
done

if [ ! -z "$verbose" ]; then
    set -x
fi

# clean up profiling
# wipe intermediate files that aren't cleaned
run_remote_profiling_cleanup () {
    SRVR=$1
    shift
    DB=$1
    shift
    FILE_PATH=$1
    # clean up profiling
    run $SRVR "pkill screen || true"
    run $SRVR "rm -rf $FILE_PATH"
    # wipe intermediate files that aren't cleaned
    run $SRVR "monetdb stop $DB"
    run $SRVR "monetdb start $DB"
}

# TODO: for some reason cant do -dm in screen (leads to dead session)
run_remote_ps () {
    SRVR=$1
    shift
    DB=$1
    shift
    FILE_PATH=$1
    expect -c "spawn ssh -t $SRVR screen -m -S ps-session \"pystethoscope -d $DB -o $FILE_PATH\"
    sleep 0.5
    send -- \"d\"
    expect eof"
}

REMOTE_WORK_DIR=$HOME/monetdb-cluster-tpch-analysis
BASE_NAME=$(basename $QUERY_FILE .sql)

ip_addr_arr=()
readarray ip_addr_arr < follower-ipaddrs.txt

# clean up profiling
rm -rf ps-log.txt
pkill screen || true
# wipe intermediate files that aren't cleaned
monetdb stop leader-db
monetdb start leader-db

# create results area
mkdir -p results/$BASE_NAME

if [ -z "$PROFILE_DISABLE" ]; then
    screen -dmS ps-screen pystethoscope -d leader-db -o ps-log.txt
fi

for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    ip_addr=$(echo "$ip_addr" | xargs)
    run_remote_profiling_cleanup $ip_addr $DB_NAME $REMOTE_WORK_DIR/ps-log.txt

    if [ -z "$PROFILE_DISABLE" ]; then
        run_remote_ps $ip_addr $DB_NAME $REMOTE_WORK_DIR/ps-log.txt
    fi
done

mclient -d leader-db -f raw -w 80 -i < $QUERY_FILE > results/$BASE_NAME/out

sleep 5

if [ -z "$PROFILE_DISABLE" ]; then
    for addr_idx in "${!ip_addr_arr[@]}"; do
        ip_addr="${ip_addr_arr[$addr_idx]}"
        ip_addr=$(echo "$ip_addr" | xargs)
        copy $ip_addr:$REMOTE_WORK_DIR/ps-log.txt results/$BASE_NAME/${addr_idx}-ps-log.txt
    done
    cp ps-log.txt results/$BASE_NAME/leader-ps-log.txt
fi

echo "Done running $QUERY_FILE"
