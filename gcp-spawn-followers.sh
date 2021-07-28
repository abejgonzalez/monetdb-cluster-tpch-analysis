#!/bin/bash

set -ex

# Spawn up to N workers

usage() {
    echo "Usage: $0 <# worker nodes> <disk size gb per instance>"
}

total_workers=$1
bootdisk_sz_gb=$2

if [ -z "$total_workers" ]; then
    echo "Missing # of worker nodes"
    usage
    exit 1
fi

echo "Spawning $total_worker_nodes w/ $bootdisk_sz_gb GB disks"
STARTUP_SCRIPT=$PWD/monetdb-follower-machinelaunch-script.sh

for ((id=1; id<=$total_workers; id++))
do
    # taken from the GCP GUI
    IMAGE_FAMILY="debian-10"
    IMAGE_PROJECT="debian-cloud"
    ZONE="us-central1-a"
    INSTANCE_TYPE="c2-standard-8"
    INSTANCE_NAME="monetdb-worker-$id"
    gcloud compute instances create $INSTANCE_NAME \
        --zone=$ZONE \
        --image-family=$IMAGE_FAMILY \
        --image-project=$IMAGE_PROJECT \
        --maintenance-policy=TERMINATE \
        --machine-type=$INSTANCE_TYPE \
        --boot-disk-size=${bootdisk_sz_gb}GB \
        --metadata-from-file startup-script=$STARTUP_SCRIPT
done

echo "Done booting instances"

# return the list of IP addresses to attach to
list_output=""
while : ;
do
    list_output=$(gcloud compute instances list --format="value(networkInterfaces[0].networkIP)" --filter="name:monetdb-worker-*")
    [[ -z "$list_output" ]] || break
done

sleep 30

# should iterate through the list and wait until the setup is complete
for ip in $list_output;
do
    if ssh -o "StrictHostKeyChecking no" $ip cat /tmp/machine-launchstatus | grep -q 'completed'; then
        echo "Completed installing things on $ip"
        continue
    fi
done

echo "$list_output" > temp-ipaddr.txt
