#!/bin/sh

set -e
set -x

apt-get -y -q install build-essential flex bison
apt-get -y -q install gcc-riscv64-linux-gnu
apt-get -y -q install llvm lld clang
apt-get -y -q install llvm-15 lld-15 clang-15 # Temporary for working around bugs in current default LLVM version on Ubuntu (Version ?-14)
apt-get -y -q install device-tree-compiler
apt-get -y -q install cpio
apt-get -y -q install qemu-system-misc
apt-get -y -q install opensbi

exit 0
