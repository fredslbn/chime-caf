#!/usr/bin/env bash
 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

##----------------------------------------------------------##
# Device Name and Model
MODEL=POCO
DEVICE=chime

# Kernel Defconfig
DEFCONFIG=${DEVICE}_defconfig

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/out/arch/arm64/boot/dts/vendor/qcom

# Verbose Build
VERBOSE=0

# Date and Time
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME="SUPER.KERNEL-CHIME-(neutron)-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
FINAL_ZIP=${ZIPNAME}-${DEVICE}-${TANGGAL}.zip

##----------------------------------------------------------##
# Specify compiler.

COMPILER=neutron

##----------------------------------------------------------##
# Specify Linker
LINKER=ld.lld

##----------------------------------------------------------##

##----------------------------------------------------------##
# Clone ToolChain
function cloneTC() {
        
    if [ $COMPILER = "neutron" ];
    then
    
    mkdir Neutron
	cd Neutron
	curl -LO "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman" || exit 1
	chmod -x antman
	
	echo 'Setting up toolchain in $(PWD)/Neutron'
	bash antman -S || exit 1

	echo 'Patch for glibc'
	bash antman --patch=glibc
	
	export KERNEL_CLANG="clang"
    export KERNEL_CLANG_PATH="${KERNEL_DIR}/Neutron"
    export PATH="$KERNEL_CLANG_PATH/bin:$PATH"
   
   fi
	
}

##------------------------------------------------------##
# Export Variables
function exports() {

        # Export ARCH and SUBARCH
        export ARCH=arm64
        export SUBARCH=arm64
        
        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=Pancali
        export KBUILD_BUILD_USER="unknown"
        
	    export PROCS=$(nproc --all)
	    export DISTRO=$(source /etc/os-release && echo "${NAME}")
	    
	}
        
##----------------------------------------------------------------##

# Speed up build process
MAKE="./makeparallel"

##----------------------------------------------------------##
# Compilation
function compile() {
START=$(date +"%s")
			       
	# Compile
	make O=out ARCH=arm64 ${DEFCONFIG}
	       
	if [ -d ${KERNEL_DIR}/Neutron ];
	   then
	       make -j$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=$KERNEL_CLANG \
	       CROSS_COMPILE=aarch64-linux-gnu- \	       
	       LD=${LINKER} \
	       LLVM=1 \
	       LLVM_IAS=1 \
	       V=$VERBOSE 2>&1 | tee error.log
	       
    fi
    	
}

##----------------------------------------------------------------##
function zipping() {
	# Copy Files To AnyKernel3 Zip
	cp $IMAGE AnyKernel3
	cp $DTBO AnyKernel3
	find $DTB -name "*.dtb" -exec cat {} + > AnyKernel3/dtb.img
	
	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${ZIPNAME} *
        MD5CHECK=$(md5sum "$ZIPNAME" | cut -d' ' -f1)
        echo "Zip: $ZIPNAME"
        # curl -T $ZIPNAME temp.sh; echo
        curl -T $ZIPNAME https://oshi.at
        # curl --upload-file $ZIPNAME https://free.keep.sh
    cd ..
    
}

    
##----------------------------------------------------------##

cloneTC
exports
compile
zipping

##----------------*****-----------------------------##