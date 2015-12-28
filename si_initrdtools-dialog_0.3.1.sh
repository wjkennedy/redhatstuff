#!/bin/bash
# si_initrdtools
#
# A dialog/bash utility to manipulate a SystemImager initrd image
# Sun Jun 15 01:00:26 CDT 2008
# William J Kennedy
# <wjkennedy@openlpos.org>
#############################################

#set -x

trap 'umount $TMPDIR/mount; $VIEWER $LOG; echo "INT caught - exiting si_initrdtools"; rm *.$$; exit $USER_INTERRUPT' TERM INT

#############################################
# BEGIN VARIABLES
VERSION="20080615"
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./lib
GREET_STATEMENT="Systemimager initrd tools $VERSION"
GO_STATEMENT="Choose a SystemImager initrd to modify."
ALT_STATEMENT="Sure to quit?"
SELECT_FILE="Choose file to modify"
USER_INTERRUPT="99"
DATE=`date +%Y%m%d`
KERN_VER=`uname -a`
#INITRDUP="`basename $WORKING_INITRD`.$DATE"
#TMPDIR="/tmp/$INITRDUP.$$.d"
DIALOG="dialog --cr-wrap --backtitle `basename $0`"

if [ -z $DISPLAY ]
then
    VIEWER="less"
else
    VIEWER="xmessage -file"
fi

# logging
LOG=$0.$DATE.$$.log
touch $LOG
exec 2>$LOG

#################################################
# check mount and unmount
CheckMount(){
if [ ! -z $INITRD_MOUNTED ]
then
	$DIALOG --msgbox "An initrd is mounted: $TMPDIR/mount" 0 0
	umount $TMPDIR/mount
fi
}
#################################################


#############################
DumpEnv(){
echo -e "#######################\nVariables:\n \
VERSION=$VERSION\n\
DIALOG=$DIALOG\n\
GREET_STATEMENT=$GREET_STATEMENT\n\
GO_STATEMENT=$GO_STATEMENT\n\
ALT_STATEMENT=$ALT_STATEMENT\n\
SELECT_FILE=$SELECT_FILE\n\
USER_INTERRUPT=$USER_INTERRUPT\n\
DATE=$DATE\n\
DIALOG= $DIALOG\n\
LOG= $LOG\n\
EDITOR=$EDITOR\n\
VIEWER=$VIEWER\n\
KERN_VER=$KERN_VER\n\
########################
">> $LOG
}
#############################


# Find editor
EDITOR=`which gvim`
	if [ -z $EDITOR ]
		then
			EDITOR=`which gedit`
			if [ -z $EDITOR ]
				then
				EDITOR=`which vi`
			fi
	fi


# END VARIABLES
############################################

#############################################
# BEGIN FUNCTIONS
#
# UTILITY MENU
#################################################
# initrd modification functions
# AddModules
# incorporate modules from currently running kernel
AddModules(){
MODULES_TO_ADD=`$DIALOG --stdout --title "Select modules - Tab to move, Space to select, Enter to confirm" --fselect /lib/modules/ 10 80`
case $? in
	0)
        file $MODULES_TO_ADD | grep "LSB relocatable"
        if [ $? != "0" ]
            then
                # issue warning that the thing we selected is not a valid kernel module
                $DIALOG --msgbox "Hmm..  That doesn't look like a 2.6 kernel module.\n\nMake sure the modules you select end with .ko\n\nAlso, be aware that what you select needs to match the kernel in the RAM disk.\n\n  FYI, you're running $KERN_VER." 0 0
                # return to module selection
                AddModules
            else
            # our selected file should be an LSB relocatable ELF object
		    $DIALOG --msgbox "Adding $MODULES_TO_ADD" 0 0
        	# copy modules into duplication directory
            # and add entry to INSMOD_COMMANDS to get it loaded
	    	cp $MODULES_TO_ADD $TMPDIR/$INITRDUP/my_modules/
                if [ $? != "0" ]
                 then
                     $DIALOG --msgbox "Errors copying $MODULES_TO_ADD.." 0 0
                 else
                     $DIALOG --msgbox "Adding your module to INSMOD_COMMANDS\nIf you require ay special options, you'll have to add them to\n$TMPDIR/mount/my_modules/INSMOD_COMMANDS " 0 0
                    if [ -f $TMPDIR/$INITRDUP/my_modules/INSMOD_COMMANDS ]
                    then
                        echo "insmod `basename $MODULES_TO_ADD`" >> $TMPDIR/$INITRDUP/my_modules/INSMOD_COMMANDS
                    else
                       $DIALOG --msgbox "Something's wrong.. I can't find your INSMOD_COMMANDS file.."
                    fi

                 fi
            ###################
            # Add some more modules... 
	        ADDMORE=`$DIALOG --stdout --yesno "Add more modules?" 0 0`
			    case $? in
    			0)
         			#return to add more modules
         			AddModules
           		;;
    			1)
    	    		modify_initrd
    			;;
    			esac
        fi
   	    ;;
	1)
		$DIALOG --msgbox "Heading back to the menu." 0 0
		modify_initrd
		;;
	255)
		$DIALOG --msgbox "Heading back to the menu." 0 0
		modify_initrd
		;;
esac

modify_initrd
}
#################################################


#################################################
# Create action log
CreateLog(){
if [ -f SELECTED.$$ ]
then
	cat SELECTED.$$ NEW.$$ ACTION.$$ MODULES.$$ FILE_INFO.$$ >> activity_log.`date +%Y%m%d`
else
	$DIALOG --title "$0 Log" --msgbox "No actions performed, logfile is empty." 0 0
fi
}
#################################################

#################################################
# CreateFromSystem 
# create new filesystem using binaries and libraries from running system
CreateFromSystem(){
$DIALOG --title CreateFromSystem --msgbox "CreateFromSystem" 0 0

# create a new initrd based on the system we are running on (or a chroot of your selection)
$DIALOG --title "Create a new SI initrd filesystem" --msgbox "Select a filesystem to use for the base.  The applications and libraries from the system you select will be included in this image." 0 0

$DIALOG --fselect / 0 0

#for item in /tmp/initrd.img.20080908.10419.d/mount/bin/* ; do ITEM=`basename $item` ; SYSITEM=`which $ITEM` ; LOCALITEM=`ldd $SYSITEM 2>/dev/null |sort -u | awk -F"=>" '{ print $2}' | cut -d"(" -f1 | sed 's/^ //'` ; echo $SYSITEM | dialog --progressbox "Copying..." 5 80 ; done

# do /bin on the RAMDISK
for item in $TMPDIR/mount/bin/*
do
	ITEM=`basename $item`
	SYSITEM=`which $ITEM`
	LOCALITEM=`ldd $SYSITEM 2>/dev/null |sort -u | awk -F"=>" '{ print $2}' | cut -d"(" -f1 | sed 's/^ //'`
	# Copy this thing into the local copy
	echo $SYSITEM | $DIALOG --progressbox "Copying..." 0 0
done

# do /sbin on the RAMDISK
for item in $TMPDIR/mount/sbin/*
do
	ITEM=`basename $item`
	SYSITEM=`which $ITEM`
	LOCALITEM=`ldd $SYSITEM 2>/dev/null | sort -u | awk -F"=>" '{ print $2}' | cut -d"(" -f1 | sed 's/^ //'`
	# Copy this thing into the local copy
	echo $SYSITEM | $DIALOG --progressbox "Copying..." 0 0
done

# do /usr/bin on the RAMDISK
for item in $TMPDIR/mount/usr/bin/*
do
	ITEM=`basename $item`
	SYSITEM=`which $ITEM`
	LOCALITEM=`ldd $SYSITEM 2>/dev/null |sort -u | awk -F"=>" '{ print $2}' | cut -d"(" -f1 | sed 's/^ //'`
	# Copy this thing into the local copy
	echo $SYSITEM | $DIALOG --progressbox "Copying..." 0 0
done

# do /usr/sbin on the RAMDISK
for item in $TMPDIR/mount/usr/sbin/*
do
	ITEM=`basename $item`
	SYSITEM=`which $ITEM`
	LOCALITEM=`ldd $SYSITEM 2>/dev/null |sort -u | awk -F"=>" '{ print $2}' | cut -d"(" -f1 | sed 's/^ //'`
	# Copy this thing into the local copy
	echo $SYSITEM | $DIALOG --progressbox "Copying..." 0 0
done


}
#################################################

#################################################
# ModifyInsmodCommands
# modify INSMOD_COMMANDS
ModifyInsmodCommands(){
$DIALOG --title ModifyInsmodCommands --yesno "Modify the INSMOD_COMMANDS file for module loading?" 0 0
if [ $? = "0" ]
then
    SELECTED_INSMODCOMMANDS=`$DIALOG --stdout --title "Select your INSMOD_COMMANDS file: Tab to move, Space to select, Enter to confirm." --fselect $TMPDIR/$INITRDUP/my_modules/ 0 0` 
    case $? in
    0)
        #$DIALOG --msgbox "We think you want to edit '$SELECTED_FUNCTIONS'" 0 0
  	    $EDITOR $SELECTED_INSMODCOMMANDS
        ;;
    1)
        $DIALOG --msgbox "Couldn't figure out what to edit.  Did you select 'INSMOD_COMMANDS'?" 0 0
        ;;
    esac
else
  modify_initrd
fi
modify_initrd
}
#################################################

#################################################
# ModifyFuctions 
# modify functions incorporated in initrd
ModifyFunctions(){
$DIALOG --title ModifyFunctions --yesno "Modify the built-in Functions?" 0 0
if [ $? = "0" ]
then
    SELECTED_FUNCTIONS=`$DIALOG --stdout --title "Select the functions script to edit - Tab to move, Space to select, Enter to confirm." --fselect $TMPDIR/$INITRDUP/etc/init.d/functions 0 0` 
    case $? in
    0)
        #$DIALOG --msgbox "We think you want to edit '$SELECTED_FUNCTIONS'" 0 0
  	    $EDITOR $SELECTED_FUNCTIONS
        ;;
    1)
        $DIALOG --msgbox "Couldn't figure out what to edit.  Did you select 'functions?" 0 0
        ;;
    esac
else
  modify_initrd
fi
modify_initrd
}
#################################################

#################################################
# ModifyRCS
# modify rcs incorporated in initrd
ModifyRCS(){
$DIALOG --title ModifyRCS --yesno "Modify the built-in RCS?" 0 0
if [ $? = "0" ]
then
 SELECTED_RCS=`$DIALOG --stdout --title "Select the /etc/init.d/rcS file to edit - Tab to move, Space to select, Enter to confirm." --fselect $TMPDIR/$INITRDUP/etc/init.d/rcS 0 0`
  case $? in
    0)
        #$DIALOG --msgbox "We think you want to edit '$SELECTED_RCS'" 0 0
        $EDITOR $SELECTED_RCS
        ;;
    1)
        $DIALOG --msgbox "Couldn't figure out what to edit.  Did you select 'rcS'?" 0 0
        ;;
    esac
else
  modify_initrd
fi
modify_initrd
}
#################################################

#################################################
# CompressNewInitrd  
# compress newly created ramdisk for inclusion in bootable media
CompressNewInitrd(){
# get new initrd name
NEW_INITRD_NAME=`$DIALOG --stdout --title CompressNewInitrd --inputbox "Enter name for a new RAM disk.  The date and this session ID '$$' will be appended" 0 0`
# create new blank filesystem
case $? in
    0)
        $DIALOG --msgbox "New ramdisk name $NEW_INITRD_NAME" 0 0
        ###########################################################
         #establish new ramdisk name
         NEW_RD="$TMPDIR/$NEW_INITRD_NAME.$DATE.$$"
         #select size for new ramdisk
         NEW_RD_SIZE=`$DIALOG --stdout --radiolist "Select new RAM disk size:"\
         30 40 40\
         5MB "5 Megabyte RAM disk (ext2)" on \
         10MB "10 Megabyte RAM disk (ext2)" off \
         15MB "15 Megabyte RAM disk (ext2)" off`
        ################################
     # if we're successful in getting a new ram disk name...
         case $NEW_RD_SIZE in
         # Create 5MB ramdisk
         5MB)
            dd if=/dev/zero of=$NEW_RD bs=1024 count=5000 | $DIALOG --progressbox "Creating $NEW_RD - 1024K blocksize, 10000 blocks" 0 0
             $DIALOG --msgbox "Created $NEW_RD - 1024K block size, 10000 blocks" 0 0
             yes | mkfs.ext2 -bs 1024 -q $NEW_RD | $DIALOG --progressbox "Formatting $NEW_RD as ext2" 0 0
             #$DIALOG --msgbox "Created  ext2 filesystem on $NEW_RD" 0 0
             mkdir -p $TMPDIR/$INITRDUP/$NEW_INITRD_NAME.$DATE.$$-mount
             if [ $? != "0" ]
             then
                $DIALOG --msgbox "Couldn't create $TMPDIR/$INITRDUP/$NEW_RD.mounted" 0 0
             fi
             mount -o loop $NEW_RD $TMPDIR/$INITRDUP/$NEW_INITRD_NAME.$DATE.$$-mount
             if [ $? != "0" ]
             then
                 $DIALOG --msgbox "There was an error mounting $NEW_RD on $TMPDIR/$INITRDUP/$NEW_INITRD_NAME.$DATE.$$-mount " 0 0
             else 
                 $DIALOG --msgbox "$NEW_RD mounted on $TMPDIR/$INITRDU/$NEW_RD.mounted" 0 0
             fi
         ;;
    
          10MB)
             dd if=/dev/zero of=$NEW_RD bs=1024 count=10000 | $DIALOG --progressbox "Creating $NEW_RD - 1024K blocksize, 20000 blocks" 0 0
             $DIALOG --msgbox "Created $NEW_RD - 1024K block size, 20000 blocks" 0 0
             yes | mkfs.ext2 -bs 1024 -q $NEW_RD | $DIALOG --progressbox "Formatting $NEW_RD as ext2" 0 0
             #$DIALOG --msgbox "Created  ext2 filesystem on $NEW_RD" 0 0
             mkdir $TMPDIR/$NEW_RD.mounted
             mount -o loop $NEW_RD $TMPDIR/$NEW_RD.mounted
             if [ $? != "0" ]
             then
                 $DIALOG --msgbox "There was an error mounting $NEW_RD on $TMPDIR/$NEW_RD.mounted" 0 0
             else 
                 $DIALOG --msgbox "$NEW_RD mounted on $TMPDIR/$NEW_RD.mounted" 0 0
             fi
         ;;
         15MB)
             dd if=/dev/zero of=$NEW_RD bs=1024 count=15000 | $DIALOG --progressbox "Creating $NEW_RD - 1024K blocksize, 25000 blocks" 0 0
             $DIALOG --msgbox "Created $NEW_RD - 1024K block size, 25000 blocks" 0 0
             yes | mkfs.ext2 -bs 1024 -q $NEW_RD | $DIALOG --progressbox "Formatting $NEW_RD as ext2" 0 0
             #$DIALOG --msgbox "Created  ext2 filesystem on $NEW_RD" 0 0
             mkdir $TMPDIR/$NEW_RD.mounted
             mount -o loop $NEW_RD $TMPDIR/$NEW_RD.mounted
             if [ $? != "0" ]
             then
                 $DIALOG --msgbox "There was an error mounting $NEW_RD on $TMPDIR/$NEW_RD.mounted" 0 0
             else 
                 $DIALOG --msgbox "$NEW_RD mounted on $TMPDIR/$NEW_RD.mounted" 0 0
             fi
         ;;
        esac
    ;;
    # end creation size section
    ###################    
    1)
        $DIALOG --msgbox "Invalid name." 0 0
        CompressNewInitrd
    ;;
esac
    # copy contents into new filesystem
    # unmount
    # compress and present for copying out
    
}
#################################################
#
# END UTILITY MENU
#################################################

#################################################
show_help(){
echo "Usage - as root: $0 [-h|-x]"
echo "The '-h' option will display this help message."
echo "Run $0 with '-x' to use X-based dialog, 'Xdialog'."
exit 0
}

#################################################
do_file_selection(){

WORKING_INITRD=`$DIALOG --stdout --title "Select an initrd.img - Tab to move, Space to select, Enter to confirm." --fselect "/usr/share/systemimager/boot/i386/standard/initrd.img" 10 80`

case $? in
  0)
  #$DIALOG --msgbox "You chose \"$WORKING_INITRD\"" 0 0
  # get initrd file information
  $DIALOG --msgbox "Checking validity of \"$WORKING_INITRD\"" 40 20
  file -z $WORKING_INITRD > FILE_INFO.$$
    INITRD_NAME=`basename $WORKING_INITRD`
    INITRDUP="`basename $WORKING_INITRD`.$DATE"
    TMPDIR="/tmp/$INITRDUP.$$.d"
    #INITRDUP="/tmp/$INITRD_NAME.`date+%Y%m%d`"
    $DIALOG --msgbox "Checking validity of $WORKING_INITRD ..." 0 0
    # fix the format of the file info output file
    sed -i -e 's/:/\n\n/' -e 's/,/\n\n/' -e 's/(/\n\n/' -e 's/)//' FILE_INFO.$$
    # check the file type to see that it's a compressed rom filesystem
    # we don't care if it ends in gz or not at this phase - but it may be an issue later..
   grep "Linux Compressed ROM File System data" FILE_INFO.$$
    if [ $? != "0" ]
     # if it's not, then issue a warning and do file selection again.
      then
  		$DIALOG --msgbox "You did not select a valid initrd file." 0 0
		if [ $? = "1" ]
			then
	 			main
			else
				do_file_selection
		fi
      else
        $DIALOG --title "initrd: $INITRD_NAME file information" --textbox FILE_INFO.$$ 0 0
        # display successful file information
    fi
  ;;

  1)
  $DIALOG --msgbox "Cancel." 0 0
  modify_initrd
  ;;

  255)
    echo "Escape!"
	modify_initrd
	;;
esac
}
#################################################

#################################################
mount_initrd(){
if [ ! -d $TMPDIR/mount ]
    then
	mkdir -p $TMPDIR/mount
fi
# copy actual initrd.img to temporary directory
cp $WORKING_INITRD $TMPDIR
RAW_INITRD=`basename $WORKING_INITRD .img`
# extract initrd from .img
gunzip -S .img $TMPDIR/$RAW_INITRD
# mount initrd on loop device
mount -o loop $TMPDIR/$RAW_INITRD $TMPDIR/mount
# set flag to indicate that a disk is mounted.
if [ $? = "0" ]
then
	INITRD_MOUNTED="0"
else
	$DIALOG --msgbox "Could not mount using 'mount -o loop $TMPDIR/$RAW_INITRD $TMPDIR/mount'" 0 0
fi
# if the directory for the duplication doesn't exist, create it
if [ ! -d $TMPDIR/$INITRDUP ]
 then 
 mkdir $TMPDIR/$INITRDUP
fi
# copy the contents of the mounted image to the duplication directory with progress indicator
cp -aR $TMPDIR/mount/* $TMPDIR/$INITRDUP/ | $DIALOG --progressbox "Copying the contents of the initrd to $INITRDUP" 0 0
# notify that we've finished copying and the thing is ready to modify.
mount | grep $TMPDIR/$RAW_INITRD
if [ $? = "0" ]
then
	$DIALOG --msgbox "Your initrd '$RAW_INITRD' is mounted at $TMPDIR/mount in it's original form, and duplicated for editing at $TMPDIR/$INITRDUP" 10 60
    else
	$DIALOG --msgbox "Your initrd '$RAW_INITRD' is not mounted. <sad face>" 0 0

fi
}

#################################################

#################################################
# unmount mounted loop device
unmount_initrd(){
$DIALOG --yesno "Finished with initrd mounted at $TMPDIR/mount?" 0 0
if [ $? = "0" ]
    then
    umount $TMPDIR/mount
    gzip -9 -S .img $TMPDIR/initrd
    $DIALOG --msgbox "initrd unmounted."
    $DIALOG --entry --msgbox "Choose a new filename for your initrd" --entry-text "initrd.new.`date +%Y%m%d`.img" 1> NEW_FILENAME.$$
    mv $TMPDIR/initrd.img `cat NEW_FILENAME.$$`
    $DIALOG --msgbox "Your initrd is created as `cat NEW_FILENAME.$$` in $TMPDIR"
    else
    $DIALOG --msgbox "Create a function to do something more with initrd." 0 0
fi
exit 0
}
#################################################

#################################################
# modify initrd
modify_initrd(){
$DIALOG --msgbox "Using $INITRDUP" 0 0

ACTION=`$DIALOG --stdout --radiolist "Select action to perform on $INITRDUP" 0 0 0 \
AddModules "Add kernel modules" on \
ModifyFunctions "Modify etc/init.d/functions" off \
ModifyRCS "Modify etc/init.d/rcS" off \
ModifyInsmodCommands "Modify INSMOD_COMMANDS for $INITRDUP" off \
CreateFromSystem "Create a ramdisk based on this system" off \
CompressNewInitrd "Compress $INITRDUP" off`

case $? in
  0)
    #echo "You chose \"$ACTION\""
		case $ACTION in
			AddModules)
				$DIALOG  --msgbox "Adding modules to pre-existing RAM disk." 0 0
				AddModules
				;;
			ModifyInsmodCommands)
				$DIALOG  --msgbox "Editing/verifying INSMOD_COMMANDS" 0 0
				ModifyInsmodCommands
				;;
			ModifyFunctions)
				#$DIALOG --msgbox "Modifying included Functions" 0 0
				ModifyFunctions
				;;
			ModifyRCS)
				#$DIALOG --msgbox "Modifying included /etc/init.d/rcS" 0 0
				ModifyRCS
				;;
        	CreateFromSystem)
				$DIALOG  --msgbox "Creating new RAM disk from this system" 0 0
				CreateFromSystem
				;;
			CompressNewInitrd)
				$DIALOG --msgbox "Compressing working RAM disk" 0 0
				CompressNewInitrd
				;;
		esac
		;;
  1)
    $DIALOG --msgbox "Cancelled.. Viewing $LOG" 0 0
	echo "Actions dialog cancelled - exiting $USER_EXIT" >> $LOG
	# check for and unmount initrd at $TMPDIR/mount
	CheckMount
	# open the log
	DumpEnv
	$VIEWER $LOG
	exit $USER_EXIT
	#	modify_initrd
	;;
  255)
    echo "User exit..";;
esac


# execute chosen menu option
}
#################################################

#################################################
# do the other thing
do_alternate(){
$DIALOG --msgbox "$ALT_STATEMENT" 0 0
DumpEnv
exit 1
}
# END FUNCTIONS 
############################################


##################################################
# Main function
main(){

# see if we really want to run this thing..
$DIALOG --yesno "Ready to load and modify a SystemImager initrd image?" 0 0

if [ $? = "0" ]
    then
        do_file_selection
        mount_initrd
        modify_initrd
    else
		echo "Quitting."
		DumpEnv
		exit 1
        #do_alternate
fi
}
#################################################

##################################################
# DO THE WORK

case $1 in
-h)
	show_help
;;

-x)
	DIALOG="Xdialog --cr-wrap --backtitle=`basename $0`"
;;

-c)
	DIALOG="dialog --ascii-lines --cr-wrap --backtitle=`basename $0`"
;;
esac

# we have to be root to do the mounting tricks..
whoami | grep root
case $? in
0)
    main
;;

1)
    echo "You must be root to run this app."
    exit 1
;;
esac

# clean up
#rm SELECTED* NEW* ACTION* MODULES* FILE_INFO*
# unmount mounted ramdisk
CheckMount
