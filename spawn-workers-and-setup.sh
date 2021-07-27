#!/bin/bash

set -ex

usage() {
    echo "Usage: $0 --sf <scale factor> --farm <worker farm path> --num_workers <# workers>"
    echo "  Connect to N workers and set them up"
}

# copy files from server to server
# $1 - src
# $2 - dest
copy () {
    rsync -avzp -e 'ssh' $1 $2
}

# run command over ssh
# $1 - server login (user@IP)
# $2 - command
run_impl () {
    ssh -o "StrictHostKeyChecking no" $1 $2
}

# run script over ssh
# $1 - server login (user@IP)
# $2 - local script
# $3 - arguments to the script
run_script_impl () {
    SERVER=$1
    shift
    SCRIPT=$1
    shift
    echo "$SERVER $SCRIPT $@"
    ssh -o "StrictHostKeyChecking no" $SERVER 'bash -s -l' -- < $SCRIPT "$@"
}

# build server calls

# run command on build server
# $1 - command
run () {
    SERVER=$1
    shift
    run_impl $SERVER "$@"
}

# run script on build server
# $1 - script
# $1 - arguments to the script
run_script () {
    SERVER=$1
    shift
    SCRIPT=$1
    shift
    run_script_impl $SERVER $SCRIPT $@
}

ip_addr_arr=()
scaling_factor=
worker_farm_path=
num_workers=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --sf)
            scaling_factor=$2
            shift
            shift
            ;;
        --farm)
            worker_farm_path=$2
            shift
            shift
            ;;
        --num_workers)
            num_workers=$2
            shift
            shift
            ;;

    esac
done

if [ -z "$scaling_factor" ]; then
    echo "Missing --sf"
    usage
    exit 1
fi
if [ -z "$worker_farm_path" ]; then
    echo "Missing --farm"
    usage
    exit 1
fi
if [ -z "$num_workers" ]; then
    echo "Missing --num_workers"
    usage
    exit 1
fi


echo "Scaling Factor: $scaling_factor"
echo "Farm Path: $worker_farm_path"

# in gbs
disk_space=$(($(($scaling_factor/$num_workers))+20))
echo "$disk_space GB of disk space per instance"

# TODO: replace with different service
# call spawn here
./gcp-spawn-followers.sh $num_workers $disk_space
readarray ip_addr_arr < temp-ipaddr.txt
rm -rf temp-ipaddr.txt

echo "IP Addrs:"
for addr_idx in "${!ip_addr_arr[@]}"; do
    echo "  $addr_idx: ${ip_addr_arr[$addr_idx]}"
done

rm -rf remote_table
mkdir -p remote_table

total_ip_addrs=${#ip_addr_arr[@]}
for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    run $ip_addr "echo \"Ping $ip_addr\""
    copy $HOME/monetdb-cluster-tpch-analysis/ $(echo "$ip_addr" | xargs):$HOME/monetdb-cluster-tpch-analysis
    run_script $ip_addr build-load-tpch-worker-nodes.sh --worker-id $((addr_idx+1)) --total-workers $total_ip_addrs --sf $scaling_factor --farm $worker_farm_path

    # copy back the fancy remote table stuff
    copy $(echo "$ip_addr" | xargs):$HOME/monetdb-cluster-tpch-analysis/remote_table.sql remote_table/remote_table_${addr_idx}.sql
done

echo "Done?"

# run the client and add the remote tables
#for
#    mclien5 -d mdb-master
