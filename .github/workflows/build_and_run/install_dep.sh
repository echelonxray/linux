#!/bin/sh

set -e
set -x

apt-get -y -q install build-essential
apt-get -y -q install gcc-riscv64-linux-gnu
apt-get -y -q install llvm lld clang
apt-get -y -q install device-tree-compiler
apt-get -y -q install cpio
apt-get -y -q install qemu-system-misc
apt-get -y -q install opensbi

exit 0
