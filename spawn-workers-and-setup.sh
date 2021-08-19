#!/bin/bash

set -e
set -o pipefail

mkdir -p logs/
./spawn-workers-and-setup-nolog.sh "$@" 2>&1 | tee logs/spawn.log
