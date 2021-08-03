#!/bin/bash

set -x

DB=SF-100
# prior = 3m
TIMEOUT=6m


timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/01.sql
#./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/02.sql
#./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/03.sql
#./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/04.sql
timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/05.sql
#./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/06.sql
#./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/07.sql
timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/08.sql
timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/09.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/10.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/11.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/12.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/13.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/14.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/15.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/16.sql
timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/17.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/18.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/19.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/20.sql
timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/21.sql
#timeout $TIMEOUT ./run-query-w-profiling.sh -d $DB -q tpch-scripts/03_run/22.sql

#for i in $(ls tpch-scripts/03_run/??.sql); do
#    ./run-query-w-profiling.sh -d $DB -q $i
#done

