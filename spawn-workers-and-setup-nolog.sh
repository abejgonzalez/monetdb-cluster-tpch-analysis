#!/bin/bash

set -e

source remote-helper.sh

usage() {
    echo "Usage: $0 --platform <gcp,aws> --sf <scale factor> --num_workers <# workers>"
    echo "  Connect to N workers and set them up on a specific platform"
}

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-${(%):-%x}}")")"
ip_addr_arr=()
scaling_factor=
num_workers=
platform=gcp

while [ "$#" -gt 0 ]; do
    case "$1" in
        --sf)
            scaling_factor=$2
            shift
            shift
            ;;
        --num_workers)
            num_workers=$2
            shift
            shift
            ;;
        --platform)
            platform=$2
            shift
            shift
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [ -z "$scaling_factor" ]; then
    echo "Missing --sf"
    usage
    exit 1
fi
if [ -z "$num_workers" ]; then
    echo "Missing --num_workers"
    usage
    exit 1
fi

# in GBs (need enough space on the workers)
disk_space=$(($(($scaling_factor/$num_workers))*3+20))
echo "$disk_space GB of disk space per instance"

IP_ADDR_FILE=$script_dir/follower-ipaddrs.txt
case "$platform" in
    gcp)
        $script_dir/gcp-scripts/spawn-followers.sh --num_nodes $num_workers --disk_sz_gb $disk_space --ipaddr_file $IP_ADDR_FILE
        ;;
    aws)
        echo "AWS platform not implemented yet"
        exit 1
        ;;
    *)
        echo "$platform unsupported"
        usage
        exit 1
        ;;
esac

# keep track of IP addresses
readarray ip_addr_arr < $IP_ADDR_FILE

echo "IP Addrs:"
for addr_idx in "${!ip_addr_arr[@]}"; do
    echo "  $addr_idx: ${ip_addr_arr[$addr_idx]}"
done

rm -rf remote_table
mkdir -p remote_table
rm -rf repl_remote_table
mkdir -p repl_remote_table

worker-setup() {
    local ip_addr=$1
    local addr_idx=$2
    {
    run $ip_addr "echo \"Ping $ip_addr\""
    copy $HOME/monetdb-cluster-tpch-analysis/ ${ip_addr}:$HOME/monetdb-cluster-tpch-analysis
    run_script $ip_addr build-load-tpch-worker-nodes.sh --worker-id $((addr_idx+1)) --total-workers $total_ip_addrs --sf $scaling_factor

    # copy back the fancy remote table stuff
    copy ${ip_addr}:$HOME/monetdb-cluster-tpch-analysis/remote_table.sql remote_table/remote_table_${addr_idx}.sql
    copy ${ip_addr}:$HOME/monetdb-cluster-tpch-analysis/replicated.txt repl_remote_table/replicated_${addr_idx}.txt
    } 2>&1 | tee logs/${ip_addr}.log
}

mkdir -p logs

total_ip_addrs=${#ip_addr_arr[@]}
for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    ip_addr=$(echo "$ip_addr" | xargs)
    worker-setup $ip_addr $addr_idx &
done
wait

# create the dbfarm
monetdbd stop ~/leader-dbfarm || true
rm -rf ~/leader-dbfarm
monetdbd create ~/leader-dbfarm
monetdbd start ~/leader-dbfarm
# create the db
monetdb create leader-db
monetdb release leader-db

echo "DEBUG: Early exit"
exit 0

# setup constraints for the shard tables
for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    ip_addr=$(echo "$ip_addr" | xargs)

    ./create-remote-constraints-sql.py remote_table/ repl_remote_table/ follower-ipaddrs.txt $ip_addr > rem_${addr_idx}.sql
    copy $HOME/monetdb-cluster-tpch-analysis/rem_${addr_idx}.sql ${ip_addr}:$HOME/monetdb-cluster-tpch-analysis/rem_${addr_idx}.sql
    run "mclient -d SF-${scaling_factor} < $HOME/monetdb-cluster-tpch-analysis/rem_${addr_idx}.sql"
done

# create merge/replica tables and run
./create-merge-repl-tables-sql.py remote_table/ repl_remote_table/ follower-ipaddrs.txt > generate-tables.sql
mclient -d leader-db < generate-tables.sql
