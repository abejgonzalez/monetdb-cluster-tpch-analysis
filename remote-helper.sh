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
    ssh -t -o "StrictHostKeyChecking no" $SRVR $@
}

# run command on build server
# $1 - command
run () {
    SERVER=$1
    shift
    run_impl $SERVER "$@"
}
