#!/bin/bash

# copy files from server to server
# $1 - src
# $2 - dest
copy () {
    rsync -azp -e 'ssh' $1 $2
}

# run command over ssh
# $1 - server login (user@IP)
# $2 - command
run_impl () {
    SRVR=$1
    shift
    ssh -T -o "StrictHostKeyChecking no" $SRVR -- $@
}

# run command on build server
# $1 - command
run () {
    SRVR=$1
    shift
    run_impl $SRVR "$@"
}

# run script over ssh
# $1 - server login (user@IP)
# $2 - local script
# $3 - arguments to the script
run_script_impl () {
    SRVR=$1
    shift
    SCRPT=$1
    shift
    echo "$SRVR $SCRPT $@"
    ssh -T -o "StrictHostKeyChecking no" $SRVR 'bash -s -l' -- < $SCRPT "$@"
}

# run script on build server
# $1 - script
# $1 - arguments to the script
run_script () {
    SRVR=$1
    shift
    SCRPT=$1
    shift
    run_script_impl $SRVR $SCRPT $@
}
