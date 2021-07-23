#!/bin/bash

set -ex

# Derived from https://www.monetdb.org/downloads/deb/

SUITE_NAME=$(lsb_release -cs)
DEB_SW_FILE=/etc/apt/sources.list.d/monetdb.list

# overwrite then append
touch $DEB_SW_FILE
echo "deb https://dev.monetdb.org/downloads/deb/ $SUITE_NAME monetdb" > $DEB_SW_FILE
echo "deb-src https://dev.monetdb.org/downloads/deb/ $SUITE_NAME monetdb" >> $DEB_SW_FILE
wget --output-document=/etc/apt/trusted.gpg.d/monetdb.gpg https://www.monetdb.org/downloads/MonetDB-GPG-KEY.gpg
apt-key finger
apt update -y
apt install -y monetdb5-sql monetdb-client
usermod -a -G monetdb $USER
