#!/usr/bin/env bash
 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$(pwd)"
##----------------------------------------------------------##

# Device Name and Model
MODEL=Xiaomi
DEVICE=Chime

# Kernel Defconfig
DEFCONFIG=oldconfig

# Files
MODULE=$(pwd)/lib/modules/

# Verbose Build
VERBOSE=1

# Date and Time
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME="MODULE-${DEVICE}-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"

##----------------------------------------------------------##
function exports() {

# Export Configs
export KERNEL_CCOMPILE64_PATH="${KERNEL_DIR}/gcc64"
export KERNEL_CCOMPILE64="aarch64-linux-gnu-"
export PATH="$KERNEL_CCOMPILE64_PATH/bin:$PATH"
GCC_VERSION=$(aarch64-linux-gnu-gcc --version | grep "(GCC)" | sed 's|.*) ||')

export KERNEL_CCOMPILE32_PATH="${KERNEL_DIR}/gcc32"
export KERNEL_CCOMPILE32="arm-linux-gnueabihf-"
export PATH="$KERNEL_CCOMPILE32_PATH/bin:$PATH"

export ARCH=arm64
export SUBARCH=arm64

}

##----------------------------------------------------------##
# Compilation
function compile() {
		
	# Compile
	make ARCH=arm64 ${DEFCONFIG}
	
	if [ -d ${KERNEL_DIR}/gcc64 ];
	   then
	       make -j$(nproc --all) \
	       ARCH=arm64 \
           CROSS_COMPILE=$KERNEL_CCOMPILE64 \
           CROSS_COMPILE_ARM32=$KERNEL_CCOMPILE32 \
           CROSS_COMPILE_COMPAT=$KERNEL_CCOMPILE32 \
	       modules

    fi
}

##----------------------------------------------------------------##
function zipping() {

	# Copy Files To AnyKernel3 Zip	
	# find $MODULE -name "*.ko" -exec cat {} + > AnyKernel3/wtc2.ko
	find . -name '*wtc2.ko' -exec cp '{}' AnyKernel3/modules/system/lib/modules \;

	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${ZIPNAME} *
        MD5CHECK=$(md5sum "$ZIPNAME" | cut -d' ' -f1)
        echo "Zip: $ZIPNAME"
        curl --upload-file $ZIPNAME https://free.keep.sh
    cd ..
    
}

##----------------------------------------------------------##

exports
compile
zipping

##----------------*****-----------------------------##