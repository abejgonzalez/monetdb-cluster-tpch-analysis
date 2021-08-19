#!/bin/bash

usage() {
    echo "Usage: $0 --ipaddr_file <input ipaddr file>"
    echo "  Delete N follower nodes based on the ip addr file"
}

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-${(%):-%x}}")")"
ipaddr_file=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --ipaddr_file)
            ipaddr_file=$2
            shift
            shift
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [ -z "$ipaddr_file" ]; then
    echo "Missing --ipaddr_file"
    usage
    exit 1
fi

num_nodes=$(wc -l $ipaddr_file | awk '{ print $1 }')
echo "Deleting $num_nodes instances based on $ipaddr_file"

# create list of names w/ proper ids
all_nodes=""
for ((id=1; id<=$num_nodes; id++))
do
    all_nodes="$all_nodes monetdb-worker-$id"
done

# bulk delete all nodes (use expect to handle prompts)
expect -c "spawn gcloud compute instances delete $all_nodes
expect \"*Y/n*\"
send \"\r\"
expect \"*Y/n*\"
send \"\r\"
expect eof"

echo "Deleted instances. Now deleting $ipaddr_file"
rm $ipaddr_file
