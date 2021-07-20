#!/bin/bash

set -ex

# scale factor needed to generate data
SCALE_FACTOR=1
# number of shards for the worker
NUM_SHARDS=10

# output data dir
OUT_DIR=gen-data-sf$SCALE_FACTOR-sh$NUM_SHARDS

# output data
mkdir -p $OUT_DIR

for (( idx=1; idx<=$NUM_SHARDS; idx++ )); do
    ./dbgen -vf -s $SCALE_FACTOR -C $NUM_SHARDS -S $idx
    mkdir -p $OUT_DIR/
    mv *.tbl *.tbl.* $OUT_DIR/
done
