#!/bin/bash

# Config: allnoconfig

set -e
set -x

ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make clean
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make mrproper
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make allnoconfig
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make -j$(nproc) all

exit 0
