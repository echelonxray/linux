#!/bin/bash

# Config: defconfig

set -x
set -e

set -o pipefail

timeout --foreground --kill-after=60s --signal=SIGTERM 120s \
    qemu-system-riscv64 -M virt -m 128M -cpu rv64 -display none -serial stdio -no-reboot \
    -bios "/usr/lib/riscv64-linux-gnu/opensbi/generic/fw_dynamic.bin" \
    -kernel "./arch/riscv/boot/Image" \
    -initrd "./.github/workflows/build_and_run/test_initramfs.cpio.gz" \
    -append "console=ttyS0 panic=1 rdinit=/dumb-init /testprogram" | \
        grep -F "TRACEOUTPUT8107519475109"

exit 0
