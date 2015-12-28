#!/bin/bash
#
# extract and mount initrd in tmp directory (./mount)
###########################

gunzip -S .img $1
  mkdir mount 2> /dev/null
mount -o loop initrd mount
echo "Decompressing and mounting $1 at ./mount"
echo "Running 'umountinitrd `basename $1 .img`' will unmount and re-compress this initrd image."
