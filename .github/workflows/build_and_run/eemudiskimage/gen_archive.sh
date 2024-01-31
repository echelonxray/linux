#!/bin/bash

# Name: Generate Disk Image
# Author: Michael T. Kloos
# 
# Copyright: 
# (C) Copyright 2024 Michael T. Kloos (http://www.michaelkloos.com/).
# All Rights Reserved.

# Names Searched For
#      Kernel: kernel.bin
#         DTB: echelon_emu_v0.1.1.dtb
#   initramfs: initramfs.cpio.gz

set -x
set -e

set -o pipefail

cd $(dirname ${BASH_SOURCE[0]})
dtc -I dts -O dtb -o ./echelon_emu_v0.1.1.dtb ./echelon_emu_v0.1.1.dts
find . -print0 | cpio -o0 -H bin > ./../eemudiskimage.cpio

exit 0
