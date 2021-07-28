#!/bin/bash

usage() {
    echo "Usage: $0 <# worker nodes>"
}

total_workers=$1

if [ -z "$total_workers" ]; then
    echo "Missing # of worker nodes"
    usage
    exit 1
fi

echo "Deleting $total_worker"

all_nodes=""
for ((id=1; id<=$total_workers; id++))
do
    all_nodes="$all_nodes monetdb-worker-$id"
done

expect -c "spawn gcloud compute instances delete $all_nodes
expect \"*Y/n*\"
send \"\r\"
expect \"*Y/n*\"
send \"\r\"
expect eof"
