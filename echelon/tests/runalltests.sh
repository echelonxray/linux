#!/bin/sh

set -e

cd "$(dirname $0)"
cd "../../"

if [ ! -d "./echelon_sbi" ]; then
	echo "Error: Missing for test: [PROJECTROOT]/echelon_sbi"
	exit 1
fi
echo -n "Checking out echelon_sbi..."
cd "echelon_sbi"
git checkout ghactions_test_version-0.3 1> /dev/null 2> /dev/null
cd ".."
echo "Done"

if [ ! -d "./rv32iasu_emulator" ]; then
	echo "Error: Missing for test: [PROJECTROOT]/rv32iasu_emulator"
	exit 1
fi
echo -n "Checking out rv32iasu_emulator..."
cd "rv32iasu_emulator"
git checkout ghactions_test_version-0.2 1> /dev/null 2> /dev/null
cd ".."
echo "Done"

set +e

tryTest() {
	local testcmd="$1"
	local testname=""
	if [ -z "$2" ]; then
		testname="[NOT SPECIFIED]"
	else
		testname="$2"
	fi
	$testcmd
	local exitcode=$?
	if [ "$exitcode" != "0" ]; then
		echo "Failed Test: $testname"
		echo "Used Command: $testcmd"
		exit $exitcode
	fi
}

tryTest ".github/workflows/build_and_run/build_1.sh gcc" "Build: allnoconfig, With: gcc"
tryTest ".github/workflows/build_and_run/run_1.sh"

tryTest ".github/workflows/build_and_run/build_2.sh gcc" "Build: defconfig, With: gcc"
tryTest ".github/workflows/build_and_run/run_2.sh" "Run: defconfig (gcc), With: qemu"

tryTest ".github/workflows/build_and_run/build_3.sh gcc" "Build: allyesconfig, With: gcc"
tryTest ".github/workflows/build_and_run/run_3.sh"

tryTest ".github/workflows/build_and_run/build_4.sh gcc" "Build: rv32_defconfig, With: gcc"
tryTest ".github/workflows/build_and_run/run_4.sh" "Run: rv32_defconfig (gcc), With: qemu"

tryTest ".github/workflows/build_and_run/build_5.sh gcc" "Build: custom config, With: gcc"
tryTest ".github/workflows/build_and_run/run_5.sh" "Run: custom config (gcc), With: qemu + rv32iasu_emulator"

tryTest ".github/workflows/build_and_run/build_1.sh llvm" "Build: allnoconfig, With: llvm"
tryTest ".github/workflows/build_and_run/run_1.sh"

tryTest ".github/workflows/build_and_run/build_2.sh llvm" "Build: defconfig, With: llvm"
tryTest ".github/workflows/build_and_run/run_2.sh" "Run: defconfig (llvm), With: qemu"

tryTest ".github/workflows/build_and_run/build_3.sh llvm" "Build: allyesconfig, With: llvm"
tryTest ".github/workflows/build_and_run/run_3.sh"

tryTest ".github/workflows/build_and_run/build_4.sh llvm" "Build: rv32_defconfig, With: llvm"
tryTest ".github/workflows/build_and_run/run_4.sh" "Run: rv32_defconfig (llvm), With: qemu"

tryTest ".github/workflows/build_and_run/build_5.sh llvm" "Build: custom config, With: llvm"
tryTest ".github/workflows/build_and_run/run_5.sh" "Run: custom config (llvm), With: qemu + rv32iasu_emulator"

exit 0
