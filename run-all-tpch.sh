#!/bin/bash

set -ex

./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/12.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/13.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/14.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/15.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/16.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/17.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/18.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/19.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/20.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/21.sql
./run-query-w-profiling.sh SF-1 tpch-scripts/03_run/22.sql

#for i in $(ls tpch-scripts/03_run/??.sql); do
#    ./run-query-w-profiling.sh SF-1 $i
#done

