# !/bin/bash
# create new initrd

if [ -z $1 ]
then
    echo
    echo "Usage: $0 output_file NUM_BLOCKS."
    echo 
    echo "The NUM_BLOCKS / 10 roughly equals the size in MB."
    echo
    echo
    exit 1
fi


echo -e "Making new initrd: $1 of $2 blocks.\n"
dd if=/dev/zero of=$1 bs=1k count=$2
mke2fs -i 1024 -m 5 -Fv $1

echo;echo;echo
echo -e "Mount $1? (y/n)\n"
 read mount
 if [ "$mount" = "y" ]
 then
    if [ -d mount ]
    then
    mount -o loop $1 mount
    else
        mkdir mount
        mount -o loop $1 mount
        echo -e "$1 mounted at ./mount\n"
        echo -e "Remember to 'umount mount' when you're done.."
    fi
 else
    echo -e "Not mounting.  Mount with 'mount -o loop $1 your_mount_point'\n"
 fi
exit 0
