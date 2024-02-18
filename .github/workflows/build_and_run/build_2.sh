#!/bin/bash

# Config: defconfig

set -e
set -x

if [ "$1" = "llvm" ]; then
	# llvm
	ARCH=riscv LLVM=1 make clean
	ARCH=riscv LLVM=1 make mrproper
	ARCH=riscv LLVM=1 make defconfig
	ARCH=riscv LLVM=1 make -j$(nproc) all
else
	# gcc
	ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make clean
	ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make mrproper
	ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make defconfig
	ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make -j$(nproc) all
fi

exit 0
