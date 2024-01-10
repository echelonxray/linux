#!/bin/sh

set -e
set -x

apt-get -y -q update
apt-get -y -q upgrade

exit 0
