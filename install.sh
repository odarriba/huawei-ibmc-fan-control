#!/bin/bash

set -e

if [[ "$(whoami)" != "root" ]]; then
    echo "You need to run this script as root."
    exit 1
fi

TARGETDIR="/opt/fancontrol"
if [ ! -z "$1" ]; then
    TARGETDIR="$1"
fi

echo "*** Installing packaged dependencies..."
if [ -x "$(command -v apt-get)" ]; then
	apt-get update
	apt-get install -y lm-sensors jq snmp
fi

echo "*** Creating folder '$TARGETDIR'..."
if [ ! -d "$TARGETDIR" ]; then
    mkdir -p "$TARGETDIR"
fi

cp fancontrol.sh "$TARGETDIR/"

echo "*** Creating, (re)starting and enabling SystemD service..."
cp fancontrol.service /etc/systemd/system/fancontrol.service
sed -i "s#{TARGETDIR}#$TARGETDIR#g" /etc/systemd/system/fancontrol.service
systemctl daemon-reload
systemctl restart fancontrol
systemctl enable fancontrol

echo "*** Waiting for the service to start..."
sleep 3

echo -e "*** All done! Check the service's output below:\n"
systemctl status fancontrol

set +e
