#!/bin/bash
#===============================================================================
#
#          FILE:  Linux_QA_v1.0.sh
# 
#         USAGE:  ./Linux_QA_v1.0.sh 
# 
#   DESCRIPTION:  Functions to test and report on Linux Build QA requirements
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  William Kennedy (Ben Short provided QA reqs.) 
#       COMPANY:   
#       VERSION:  1.0
#       CREATED:  7/21/2008 10:46:11 AM Mountain Daylight Time
#      REVISION:  ---
#===============================================================================

LOG=/var/tmp/$HOSTNAME.$DATE.QAREPORT.log

if [ -f /etc/redhat-release ]
then

	# Verify that the build server or another BRN (promiscuous) server can be pinged - see below
	BRNPROMISC="10.201.7.31"
else
    # Check to see if we're on SuSE
	if [ -f /etc/suse-release ]
	then
        # and if we are, use the SuSE build server in Omaha
		BRNPROMISC="10.201.0.0"
    fi
fi

################
WRITERR(){
`echo -e "*********************************\n**** ERROR RUNNING '$TASK'*********************************\n"`
}
##################

##################
WRITELOG(){
echo "Executing $TASK\n" >> $LOG
}

#########################
VerifyRPM(){
# Run "rpm -Va | grep -v"
# awk statement here to digest the number of packages that have bad checksums, etc
echo "Verifying RPM database"
TASK="rpm -Va"
$TASK >> $LOG
if [ $? != "0" ]
then
	WRITERR
fi

# Make sure that output is sensible
# Files flagged only "T"can probably be ignored
# Possible flags:
#        S file Size differs
#        M Mode differs (includes permissions and file type)
#        5 MD5 sum differs
#        D Device major/minor number mismatch
#        L readLink(2) path mismatch
#        U User ownership differs
#        G Group ownership differs
#        T mTime differs
}

#########################
VerifyTSM()
# Run "dsmc"
TASK="dsmc"
$TASK >> $LOG
if [ $? != "0" ]
then
	WRITERR
fi
DSMCLOC=`which dsmc`
echo $DMCLOF | grep "Not found"
case $? in
	"1")
		echo "'dsmc' is installed" | tee -a $LOG
		echo "Checking execution.." | tee -a $LOG
		echo "===== dsmc output =====" >> $LOG
		$TASK | tee -a LOG 
	;;
	"0")
		WRITERR
		grep 'glibc++' $LOG
		if [ $? = "0" ]
			then
				echo "compat-glibc is not installed.\nInstall it?"
				read ans
					case $ans in
					"Y" | "y")
						TASK="up2date -i compat-glibc"
						$TASK >> $LOG
						if [ $? != "0" ]
							then
								WRITERR
						fi
					;;
					
					"N" | "n")
						echo "dsmc will not work."
					;;
esac

# If it is not found, then the TSM installation portion of the build did not run
# If it throws missing library errors then compat-glibc is not installed
}


#########################
VerifyETH(){
TASK="ifconfig -a | grep bond0 | awk '{ print $2}'"
$TASK >> $LOG
if [ $? != "0" ]
then
	WRITERR
fi
# Verify that for non-VMware machines the front-end IP address is applied to a bond device
# Verify that for VMware machines the front-end IP address is applied to a normal eth device

# Run "netstat -rn"
# Verify that the default route is present and that it can be pinged
DEFAULTROUTE=`route | grep default | awk ' {print $2}'`
TASK=$DEFAULTROUTE
if [ $? != "0" ]
then
	WRITERR >> $LOG

else
	ping $DEFAULTROUTE >> $LOG
fi

# Verify that the build server or another BRN (promiscuous) server can be pinged
TASK="ping -c5 $BRNPROMISC"
$TASK >> $LOG
if [ $? != "0" ]
then
	WRITERR >> $LOG

else
	ping $DEFAULTROUTE >> $LOG
fi

# Use ethtool or another utility to verify that all real Ethernet adapters are running at one of the following: 100/FDX, 1000/FDX, 10000/FDX
	ethtoolDevs(){	
	for DEV in eth0 eth1 eth2 eth3 eth4 eth5 bond0
		do
			ethtool $DEV | grep 
	}

$TASK >> $LOG
if [ $? != "0" ]
then
	WRITERR >> $LOG

else
	ping $DEFAULTROUTE >> $LOG
f


# Verify that all bond devices are set in modprobe.conf (modprobe.conf.local, modules.conf, etc.) to miimon=100 and mode=1

# Verify that all real Ethernet adapters are set to a hard-coded speed and duplex if possible in modprobe.conf (modprobe.conf.local, modules.conf, etc)
}

#########################
VerifyUSERS(){
# Check for existence of netiq (id=46382) and sysadmin (id=1400) groups
# Check for existence of UNIX, Storage and Backup team users
# Check for existence of  appmgr (uid=46382) and iadmin (uid=1994) users
}

#########################
VerifyFS(){
# Check for existence of /usr/netiq and /sahome filesystems
# Check for existence of /home, /usr/local, /var and /tmp filesystems
# Check for presence of LVM for everything except /boot
# Check that OS and data are on different volume groups
# Check for active paging space (swapon -s)
}

#########################
VerifyMOUNTS(){
# Make sure automatic mounts of cdrom and floppy disks are not enabled in /etc/fstab
}


#########################
VerifyADMIN(){
# Make sure that root login is disabled and X forwarding is enabled in /etc/sshd_config
# Verify that root .bash_profile is in place
# Verify that /usr/local/scripts/* scripts are in place to preempt reboots
# Verify that /usr/local/admin/bin/* are in place with correct permissions
# Verify sudoers has been pushed out from the admin server
# Verify that isd has been configured on the admin server
# Verify that the host is in /etc/hosts on the admin server
# Verify that /etc/ssh/isd_config has the proper IP address for the admin server
# Verify that the isd key is in place and has the right permissions
# Verify that isd started on reboot
# Verify that sshd started on reboot
}

##########################
VerifyNETIQ(){
# Verify that syslog entries are correct for netiq
# Check for snmpd.conf configuration
# Verify host is being placed into netiq monitoring
# Verify host is being placed in Spectrum monitoring
}

##########################
VerifyINTREQS(){
# Check for legalese in /etc/issue
# Verify time zone
# Verify ntp configuration works
# Verify xinetd is disabled
# Verify cups is disabled
# Verify DNS is reachable and is set to local then bind.
# Check for unnecessary services in inittab and chkconfig
# Verify host has all of its own IP addresses in /etc/hosts with unique names
# Verify host has admin server in /etc/hosts
}
