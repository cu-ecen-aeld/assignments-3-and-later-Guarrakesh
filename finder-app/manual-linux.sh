#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u
CURDIR=$(pwd)
OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.6
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(${CROSS_COMPILE}gcc --print-sysroot)
if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout tags/${KERNEL_VERSION}
    echo "Building Kernel for QEMU"
    make clean
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} defconfig
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image 
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    make -j 4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
   
fi

echo "Adding the Image in outdir"
if [ -e ${OUTDIR}/Image ]
then
	rm ${OUTDIR}/Image
fi
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/Image
echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir ${OUTDIR}/rootfs
cd "$OUTDIR/rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
if [ ! -d "${OUTDIR}/busybox" ]
then
cd $OUTDIR
git clone git://busybox.net/busybox.git
cd ${OUTDIR}/busybox
git checkout ${BUSYBOX_VERSION}
else
    cd ${OUTDIR}/busybox
fi

# TODO: Make and install busybox
    make distclean
    make defconfig
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
    make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
echo "Library dependencies"
cd $OUTDIR/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp -a $SYSROOT/lib64/libm.so.6 lib64
cp -a $SYSROOT/lib64/libm-2.31.so lib64
cp -a $SYSROOT/lib64/libresolv.so.2 lib64
cp -a $SYSROOT/lib64/libresolv-2.31.so lib64
cp -a $SYSROOT/lib64/libc.so.6 lib64
cp -a $SYSROOT/lib64/libc-2.31.so lib64
cp -a $SYSROOT/lib/ld-linux-aarch64.so.1 lib
cp -a $SYSROOT/lib64/ld-2.31.so lib64 

# TODO: Make device nodes 
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1
# TODO: Clean and build the writer utility
cd $CURDIR
make clean && make writer CROSS_COMPILE=$CROSS_COMPILE
# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -L -r $CURDIR/conf $OUTDIR/rootfs/home/conf
cp $CURDIR/finder-test.sh $OUTDIR/rootfs/home
cp $CURDIR/writer $OUTDIR/rootfs/home
cp $CURDIR/autorun-qemu.sh $OUTDIR/rootfs/home
cp $CURDIR/finder.sh $OUTDIR/rootfs/home
# TODO: Chown the root directory
sudo chown root:root -R $OUTDIR/rootfs
cd $OUTDIR/rootfs
# TODO: Create initramfs.cpio.gz
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip initramfs.cpio
mkimage -A arm -O linux -T ramdisk -d initramfs.cpio.gz uRamdisk

