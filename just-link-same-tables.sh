#!/bin/bash

set -ex

source remote-helper.sh

usage() {
    echo "Usage: $0 --sf <scale factor> --num_workers <# workers>"
    echo "  Connect to N workers and set them up"
}

ip_addr_arr=()
readarray ip_addr_arr < follower-ipaddrs.txt
scaling_factor="100"

# setup constraints for the shard tables
# first do all primary keys
for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    ip_addr=$(echo "$ip_addr" | xargs)

    ./create-remote-constraints-prim-sql.py remote_table/ repl_remote_table/ follower-ipaddrs.txt $ip_addr > rem_prim_${addr_idx}.sql
    copy $HOME/monetdb-cluster-tpch-analysis/rem_prim_${addr_idx}.sql ${ip_addr}:$HOME/monetdb-cluster-tpch-analysis/rem_prim_${addr_idx}.sql
    run $ip_addr "mclient -d SF-${scaling_factor} $HOME/monetdb-cluster-tpch-analysis/rem_prim_${addr_idx}.sql"
done

# then setup foreign keys
for addr_idx in "${!ip_addr_arr[@]}"; do
    ip_addr="${ip_addr_arr[$addr_idx]}"
    ip_addr=$(echo "$ip_addr" | xargs)

    ./create-remote-constraints-sql.py remote_table/ repl_remote_table/ follower-ipaddrs.txt $ip_addr > rem_${addr_idx}.sql
    copy $HOME/monetdb-cluster-tpch-analysis/rem_${addr_idx}.sql ${ip_addr}:$HOME/monetdb-cluster-tpch-analysis/rem_${addr_idx}.sql
    run $ip_addr "mclient -d SF-${scaling_factor} $HOME/monetdb-cluster-tpch-analysis/rem_${addr_idx}.sql"
done



# create merge/replica tables and run
./create-merge-repl-tables-sql.py remote_table/ repl_remote_table/ follower-ipaddrs.txt > generate-tables.sql
mclient -d leader-db < generate-tables.sql
