#!/bin/bash

# Config: [Custom_Config]

set -x
set -e

set -o pipefail

timeout --foreground --kill-after=60s --signal=SIGTERM 120s \
    qemu-system-riscv32 -M virt -m 128M -cpu rv32 -display none -serial stdio --no-reboot \
    -bios "./.github/workflows/build_and_run/opensbi-1.4-ilp32.bin" \
    -kernel "./arch/riscv/boot/Image" \
    -initrd "./.github/workflows/build_and_run/test_initramfs_32.cpio.gz" \
    -append "console=ttyS0 panic=1 rdinit=/dumb-init /testprogram" | \
        tee /dev/stderr | grep -F "TRACEOUTPUT8107519475109" > /dev/null

timeout --foreground --kill-after=60s --signal=SIGTERM 120s \
    qemu-system-riscv32 -M virt -m 128M -cpu rv32 -display none -serial stdio --no-reboot \
    -bios "./echelon_sbi/esbi-qemu_virt.elf.strip.bin" \
    -kernel "./arch/riscv/boot/Image" \
    -initrd "./.github/workflows/build_and_run/test_initramfs_32.cpio.gz" \
    -append "console=ttyS0 panic=1 rdinit=/dumb-init /testprogram" | \
        tee /dev/stderr | grep -F "TRACEOUTPUT8107519475109" > /dev/null

timeout --foreground --kill-after=60s --signal=SIGTERM 120s \
    ./rv32iasu_emulator/echelon_xray_emu.out.strip ./echelon_sbi/esbi-echelon_emu.elf.strip.bin ./.github/workflows/build_and_run/eemudiskimage.cpio --no-reboot | \
        tee /dev/stderr | grep -F "TRACEOUTPUT8107519475109" > /dev/null

exit 0
