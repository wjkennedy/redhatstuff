#!/bin/bash
#===============================================================================
#
#         USAGE: sh $0
# 
#   DESCRIPTION: Basic Crash Reporting app - forensics finder 
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  Basic version
#        AUTHOR:  William Kennedy <william.kennedy@previouscompany.com>
#       COMPANY:  PreviousCompany 
#       VERSION:  1.0
#       CREATED:  9/12/2008 9:57:36 AM Mountain Daylight Time
#      REVISION:  ---
#===============================================================================
DATE=`date +%Y%m%d`
LOG="/var/log/SYS_CRASH_FORENSICS-$HOSTNAME-$DATE.txt"

clear
echo "SYS LNX Crash Forensics Tool"
echo "See log output at $LOG"
echo -e "---------------------------------\n"

echo "$HOSTNAME uptime" | tee -a $LOG
uptime | tee -a $LOG
echo -e "---------------------------------\n" | tee -a $LOG

echo "'who -r' output:" | tee -a $LOG
who -r | tee -a $LOG
echo -e "---------------------------------\n" | tee -a $LOG

echo "Getting 'last' output"
echo "'last' command output for $HOSTNAME" | tee -a $LOG
last | tee -a $LOG
echo -e "---------------------------------\n" | tee -a $LOG

echo "Recent reboots:" | tee -a $LOG
last | grep reboot | tee -a $LOG
echo -e "---------------------------------\n"  | tee -a $LOG

echo "Syslogd restarts:" | tee -a $LOG
grep "restart." /var/log/messages | tee -a $LOG
echo -e "---------------------------------\n" | tee -a $LOG

echo "Cluster Suite messages:" | tee -a $LOG
echo "CMAN:" | tee -a $LOG
dmesg | grep CMAN | tee -a $LOG
echo -e "---------------------------------\n" | tee -a $LOG

echo "clurgmgrd 'Cluster Manager Daemon':" | tee -a $LOG
dmesg | grep clurgmgrd | tee -a $LOG
echo -e "---------------------------------\n" | tee -a $LOG

echo "Grabbing messages..." | tee -a $LOG
echo "/var/log/messages for $HOSTNAME" | tee -a $LOG
cat /var/log/messages >> $LOG
echo -e "---------------------------------\n" | tee -a $LOG


###############################
# end of info gathering
echo -e "---------------------------------\n" | tee -a $LOG
echo "See log output at $LOG"

cp $LOG $LOG.out
bzip2 $LOG.out
echo "Compressed data at $LOG.out.bz2"

exit 0
