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

for ((id=1; id<=$total_workers; id++))
do
    # taken from the GCP GUI
    IMAGE_FAMILY="debian-10"
    ZONE="us-central1-a"
    INSTANCE_TYPE="c2-standard-8"
    INSTANCE_NAME="monetdb-worker-$id"
    gcloud compute instances create $INSTANCE_NAME \
        --zone=$ZONE \
        --image-family=$IMAGE_FAMILY \
        --maintenance-policy=TERMINATE \
        --machine-type=$INSTANCE_TYPE \
        --boot-disk-size=${bootdisk_sz_gb}GB
done

echo "Done booting instances"

# TODO: Get the ips and return them (filter by the names)
