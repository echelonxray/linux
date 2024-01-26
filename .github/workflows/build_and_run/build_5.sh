#!/bin/bash

# Config: [Custom_Config]

set -e
set -x

ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make clean
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make mrproper
cp .github/workflows/build_and_run/config_5.config .config
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make olddefconfig
ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make -j$(nproc) all

cd rv32iasu_emulator
./build.sh
cd ..

cd echelon_sbi
CROSS_COMPILE=riscv64-linux-gnu- make -j$(nproc) all
cd ..

cp arch/riscv/boot/Image .github/workflows/build_and_run/eemudiskimage/kernel.bin
cp .config .github/workflows/build_and_run/eemudiskimage/kernel.config
cd .github/workflows/build_and_run/eemudiskimage
cp ../test_initramfs_32.cpio.gz initramfs.cpio.gz
./gen_image.sh
cd ../../../..

exit 0
