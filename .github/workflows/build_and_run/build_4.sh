#!/bin/bash

# Config: rv32_defconfig

set -e
set -x

if [ "$1" = "llvm" ]; then
	# llvm
	#llvm=1
	llvm=-15 # Temporarily using version ?-15 to work around bugs in current default LLVM version on Ubuntu (Version ?-14)
	ARCH=riscv LLVM=$llvm make clean
	ARCH=riscv LLVM=$llvm make mrproper
	ARCH=riscv LLVM=$llvm make rv32_defconfig
	ARCH=riscv LLVM=$llvm make -j$(nproc) all
else
	# gcc
	ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make clean
	ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make mrproper
	ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make rv32_defconfig
	ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- make -j$(nproc) all
fi

cd echelon_sbi
CROSS_COMPILE=riscv64-linux-gnu- make -j$(nproc) all
cd ..

exit 0
