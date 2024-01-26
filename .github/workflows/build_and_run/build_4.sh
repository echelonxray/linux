#!/bin/bash

# Config: rv32_defconfig

set -e
set -x

ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make clean
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make mrproper
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make rv32_defconfig
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make -j$(nproc) all

cd echelon_sbi
CROSS_COMPILE=riscv64-linux-gnu- make -j$(nproc) all
cd ..

exit 0
