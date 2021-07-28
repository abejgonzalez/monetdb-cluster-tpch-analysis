#!/bin/bash

# Adapted from https://www.monetdb.org/downloads/deb/

set -ex
set -o pipefail

echo "machine launch script started" > /tmp/machine-launchstatus

{
SUITE_NAME=$(lsb_release -cs)
DEB_SW_FILE=/etc/apt/sources.list.d/monetdb.list

sudo apt-get install -y wget

# overwrite then append
sudo echo "deb https://dev.monetdb.org/downloads/deb/ $SUITE_NAME monetdb" > $DEB_SW_FILE
sudo echo "deb-src https://dev.monetdb.org/downloads/deb/ $SUITE_NAME monetdb" >> $DEB_SW_FILE
sudo wget --output-document=/etc/apt/trusted.gpg.d/monetdb.gpg https://www.monetdb.org/downloads/MonetDB-GPG-KEY.gpg

sudo apt-key finger
sudo apt update -y
sudo apt install -y monetdb5-sql monetdb-client
for USER_ID in $(cat /etc/passwd | grep /home | cut -d ':' -f1); do
    sudo usermod -a -G monetdb $USER_ID
done

# install other needed things
sudo apt install -y git make rsync build-essential screen

# install pystethoscope
sudo apt install -y python3-pip python3
pip3 install monetdb-pystethoscope
} 2>&1 | tee /tmp/machine-launchstatus.log

echo "export PATH=/home/abegonzalez/.local/bin:\$PATH" >> /home/abegonzalez/.bashrc

echo "machine launch script completed" >> /tmp/machine-launchstatus
