#!/bin/bash
#
# oracle-infograb-rhel - Q-n-D tool to analyze the state of a RHEL BOX
#  - specifically to determine Oracle Grid Control compatibility
# 
# W.J. Kennedy 
# Thu Jun  5 12:14:31 CDT 2008
###################################

# set vars
DATE=`date +%Y%m%d`
FILE="/tmp/$0.$DATE-$$.log"
HOSTNAME=`hostname`
BONDZERO=`/sbin/ifconfig bond0 | grep "inet addr:" | awk -F : '{print $2}' | awk -F " " '{print $1}'`

# set header in output file
echo -e "$0 - $HOSTNAME $DATE " |tee $FILE


#####################################
# Get module and kernel information
	echo -e "System information for $HOSTNAME" | tee -a $FILE
	cat /etc/redhat-release
	uname -a | tee -a $FILE
	cat /etc/modules.conf | tee -a $FILE
	echo -e "****************************" | tee -a $FILE

#####################################
# Get Oracle account info

echo -e "Oracle account info " | tee -a $FILE
	echo -e "Oracle account info " | tee -a $FILE
	echo "/etc/passwd:"
    grep oracle /etc/passwd | tee -a $FILE
	echo "Oracle user environment (/opt/oracle/.profile):"
	if [ -f /opt/oracle/.profile ]
	then
		cat /opt/oracle/.profile | tee -a $FILE
	else
		echo "/opt/oracle/.profile not found." | tee -a $FILE
	fi

echo -e "****************************" | tee -a $FILE

#####################################
# NFS-specific stuff
echo -e "NFS-specific Filesystem information for $HOSTNAME " | tee -a $FILE
	echo "     NFS mounts for /etc/fstab"
    grep nfs /etc/fstab | tee -a $FILE
	echo "     NFS options in modules.conf"
    grep "options nfs" /etc/modules.conf | tee -a $FILE
echo -e "****************************" | tee -a $FILE


#####################################
# Get filesystem information
echo -e "Generic Filesystem information for $HOSTNAME " | tee -a $FILE
    cat /etc/fstab | tee -a $FILE
echo -e "****************************" | tee -a $FILE

#####################################
# Get interface information
	echo -e "Network and interface information for $BONDZERO " | tee -a $FILE
	/sbin/ifconfig | tee -a $FILE
	cat /etc/sysctl.conf | tee -a $FILE
	cat /etc/sysconfig/network-scripts/ifcfg-bond0 | tee -a $FILE

# nslookup for bond0 and hostname
	echo -e "nslookup information for $HOSTNAME" | tee -a $FILE
	nslookup $HOSTNAME | tee -a $FILE

	echo -e "nslookup information for $BONDZERO" | tee -a $FILE
	nslookup $BONDZERO

	echo -e "****************************" | tee -a $FILE

#####################################
