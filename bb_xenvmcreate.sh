#!/bin/bash
#
# Virt-install wrapper
#
# Install virtual machines on demand, per your requirement.
#
###########################################################


###############################
# Shell Options

# uncomment for debug
#set -x
###############################

###############################
# Set variables
# see virt-install(1)
###############################
DATE=$(date +%Y%m%d)
IMG_NAME="co5x64"
NAME="$IMG_NAME-$ID"
RAM=1024
VCPUS=2
DISKFILE=/var/lib/xen/images/$NAME.img
DISKSIZE=10
NETWORK0="network:default"
NETWORK1="bridge:tap0"
KERNEL_PATH="/"
OS_VARIANT="rhel5"
CDROM="/mnt/"

if [ -z $ID ]
then
    echo "Pass vm id"
    exit 1
fi

###############################
# check environment
###############################
# If the standard diskfile name is found, create a new diskfile
if [ -f $DISKFILE ]
then
	DISKFILENEW="${DISKFILE}.$$"
	echo "$DISKFILE exists..  Creating a new volume, $DISKFILENEW"
	DISKFILE=$DISKFILENEW
fi


###############################
# set virt-install command
###############################

#VIRTINSTALL_CMD="virt-install --sdl --hvm --os-type=linux --os-variant=$OS_VARIANT --location=$KERNEL_PATH --ram $RAM --file $DISKFILE --network $NETWORK0 --name=$NAME"

# Pull in the variables from above, crate virtual disk, and launch VM
VIRTINSTALL_CMD="virt-install --hvm --os-type=linux --os-variant=$OS_VARIANT --cdrom=$CDROM --vnc --file-size=$DISKSIZE --ram $RAM --file $DISKFILE --network $NETWORK0 --name=$NAME"


###############################
# Run virt-install command
###############################
$VIRTINSTALL_CMD

virt-viewer --direct $NAME
