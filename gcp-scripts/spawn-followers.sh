#!/bin/bash

set -e

usage() {
    echo "Usage: $0 --num_nodes <# follower nodes> --disk_sz_gb <disk size gb per instance> --ipaddr_file <output ipaddr file>"
    echo "  Spawn N follower nodes with a certain GB of disk. Additionally store all IP addrs of instances to a file"
}

script_dir="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-${(%):-%x}}")")"
num_nodes=
bootdisk_sz_gb=
ipaddr_file=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --num_nodes)
            num_nodes=$2
            shift
            shift
            ;;
        --disk_sz_gb)
            bootdisk_sz_gb=$2
            shift
            shift
            ;;
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

if [ -z "$num_nodes" ]; then
    echo "Missing --num_nodes"
    usage
    exit 1
fi
if [ -z "$bootdisk_sz_gb" ]; then
    echo "Missing --disk_sz_gb"
    usage
    exit 1
fi
if [ -z "$ipaddr_file" ]; then
    echo "Missing --ipaddr_file"
    usage
    exit 1
fi

echo "Spawning $num_nodes w/ $bootdisk_sz_gb GB disks"

# create list of names w/ proper ids
all_nodes=""
for ((id=1; id<=$num_nodes; id++))
do
    all_nodes="$all_nodes monetdb-worker-$id"
done

# bulk spawn all instances
STARTUP_SCRIPT=$(dirname $script_dir)/monetdb-follower-machinelaunch-script.sh
IMAGE_FAMILY="debian-10"
IMAGE_PROJECT="debian-cloud"
ZONE="us-central1-a"
INSTANCE_TYPE="c2-standard-8"
gcloud compute instances create $all_nodes \
    --zone=$ZONE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --maintenance-policy=TERMINATE \
    --machine-type=$INSTANCE_TYPE \
    --boot-disk-size=${bootdisk_sz_gb}GB \
    --metadata-from-file startup-script=$STARTUP_SCRIPT

echo "Done booting instances"

# return the list of IP addresses to attach to
list_output=""
while : ;
do
    list_output=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name:monetdb-worker-*")
    [[ -z "$list_output" ]] || break
done

sleep 30

echo "Storing IP addresses in $ipaddr_file"
echo "$list_output" > $ipaddr_file

# should iterate through the instances and wait until the setup is complete
for ip in $list_output;
do
    until ssh -o "StrictHostKeyChecking no" $ip cat /tmp/machine-launchstatus | grep -q 'completed'; do
        sleep 5
    done
    echo "Completed installing things on $ip"
done
