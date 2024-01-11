#!/bin/sh

# Config: allnoconfig

set -e
set -x

qemu-system-riscv64 -M virt -m 128M -cpu rv64 -display none -serial stdio -no-reboot \
                    -bios "/usr/lib/riscv64-linux-gnu/opensbi/generic/fw_dynamic.bin" \
					-kernel "./arch/riscv/boot/Image" \
					-append "panic=1"

exit 0
