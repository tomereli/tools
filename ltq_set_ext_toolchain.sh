#!/bin/bash
# Following environment variables needs to be defined:
# TOOLCHAIN_MIPS, TOOLCHAIN_X86_GCC_72, TOOLCHAIN_X86_GCC_72_SPECS

usage() {
	echo "$0 - set external toolchain. paths must be defined as environment variables"
	echo "PATHS:"
	echo "  GCC_72 - TOOLCHAIN_X86_GCC_72=<path to i686-nptl-linux-gnu>, TOOLCHAIN_X86_GCC_72_SPECS=<path to specs-7.1.0-openwrt>"
	echo "  MIPS   - TOOLCHAIN_MIPS=<path to toolchain-mips_mips32_gcc-4.8-linaro_uClibc-0.9.33.2_linux_3_10>"
}

#default is TOOLCHAIN for MIPS (GRX350)
TOOLCHAIN="TOOLCHAIN_MIPS"
TOOLCHAIN_PATH="$TOOLCHAIN_MIPS"
TOOLCHAIN_SPECS_PATH="None"

[ -f .config ] || {
	echo ".config file not found!!";
	exit 1;
}

if [ -n "$(grep i686-nptl-linux-gnu .config)" ]; then
	TOOLCHAIN="TOOLCHAIN_X86_GCC_72"
	TOOLCHAIN_PATH="$TOOLCHAIN_X86_GCC_72"
	TOOLCHAIN_SPECS_PATH="$TOOLCHAIN_X86_GCC_72_SPECS"
	([ -n "$TOOLCHAIN_SPECS_PATH" ] && [ -f "$TOOLCHAIN_SPECS_PATH" ]) || {
		echo "TOOLCHAIN_X86_GCC_72_SPECS environment variable not defined or $TOOLCHAIN_X86_GCC_72_SPECS does not exist, skipping"
		exit 1
	}
elif [ -n "$(grep CONFIG_TARGET_x86=y .config)" ]; then
	echo "Original toolchain remains without modifications!"
	exit 1
fi

([ -n "$TOOLCHAIN_PATH" ] && [ -d "$TOOLCHAIN_PATH" ]) || {
	echo "$TOOLCHAIN environment variable not defined or $TOOLCHAIN_PATH does not exist, skipping"
	exit 1
}

echo "Setting toolchain to $TOOLCHAIN (path=$TOOLCHAIN_PATH)"
if [ "$TOOLCHAIN" == "TOOLCHAIN_X86_GCC_72" ]; then
	sed -i 's|<PATH_TO_I686_NPTL_LINUX_GNU>|'$TOOLCHAIN_PATH'|g' .config
	sed -i 's|<PATH_TO_SPECS_FILE>|'$TOOLCHAIN_SPECS_PATH'|g' .config
else
	sed -i '/.*CONFIG_EXTERNAL_TOOLCHAIN.*/d' .config
	sed -i '/.*CONFIG_TOOLCHAIN.*/d' .config
	sed -i '/.*_ROOT_DIR=.*/d' .config
	echo -en "CONFIG_EXTERNAL_TOOLCHAIN=y\n" >> .config
	echo -en "CONFIG_TOOLCHAIN_ROOT=\"$TOOLCHAIN_PATH\"\n" >> .config
fi
make defconfig
