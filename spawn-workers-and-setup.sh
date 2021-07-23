#!/bin/bash

set -ex

# TODO: Make this spawn the worker nodes (platform specific)

usage() {
    echo "Usage: $0 --sf <scale factor> --farm <worker farm path> --ip_addrs <WORKER-IP-1> <WORKER-IP-2> ..."
    echo "  Connect to N workers and set them up"
}

# run command over ssh
# $1 - server login (user@IP)
# $2 - command
run_impl () {
    ssh -t $1 $2
}

# run script over ssh
# $1 - server login (user@IP)
# $2 - local script
# $2 - arguments to the script
run_script_impl () {
    ssh -t $1 'bash -s -l' < $2 "$3"
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
    run_script_impl $SERVER $1 $2
}

ip_addr_arr=()
scaling_factor=
worker_farm_path=

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
        --ip_addrs)
            echo "Reading $# IP addrs:"
            shift
            while [ "$#" -gt 0 ]; do
                ip_addr_arr+=($1)
                echo "Added $1"
                shift
                echo "Now $# left"
            done
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

echo "Scaling Factor: $scaling_factor"
echo "Farm Path: $worker_farm_path"
echo "IP Addrs:"
for addr_idx in "${!ip_addr_arr[@]}"; do
    echo "  $addr_idx: ${ip_addr_arr[$addr_idx]}"
done

total_ip_addrs=${#ip_addr_arr[@]}
for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    run_script $ip_addr monetdb-install.sh
    run_script $ip_addr build-load-tpch-worker-nodes.sh --worker-id $((addr_idx+1)) --total-workers $total_ip_addrs --sf $scaling_factor --farm $worker_farm_path
done
