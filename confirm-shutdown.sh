#!/bin/bash

set -e

# library of remote helper functions
source remote-helper.sh

DB_NAME=SF-100
REMOTE_WORK_DIR=$HOME/monetdb-cluster-tpch-analysis

ip_addr_arr=()
readarray ip_addr_arr < follower-ipaddrs.txt

# clean up profiling
pkill screen || true
rm -rf ps-log.txt
# wipe intermediate files that aren't cleaned
monetdb stop leader-db || true

for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    ip_addr=$(echo "$ip_addr" | xargs)
    # clean up profiling
    run $ip_addr "pkill screen || true"
    run $ip_addr "rm -rf $REMOTE_WORK_DIR/ps-log.txt"
    # wipe intermediate files that aren't cleaned
    run $ip_addr "monetdb stop $DB_NAME || true"
done
