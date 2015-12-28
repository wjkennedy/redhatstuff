#!/bin/bash
#===============================================================================
#
#          FILE:  wmhandler.sh
# 
#         USAGE:  ./wmhandler.sh
# 
#   DESCRIPTION: Webmethods broker handler script - specifically for use with
#                Redhat Cluster Suite 
# 
#         NOTES:  Uses /opt/ab mount for Webmethods
#        AUTHOR:  William Kennedy
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  7/29/2008 5:11:48 PM Mountain Daylight Time
#      REVISION:  ---
#===============================================================================

WM_BROKER_DIR="/var/opt/ab/wmbroker"

case $1 in
start)
    echo "* Starting Webmethods broker" | tee -a /var/log/messages
    if [ -d /$WM_BROKER_DIR ]
	then
	    $WM_BROKER_DIR/S45broker65 start
	else
        echo "* Broker directory: $WM_BROKER_DIR Not available." | tee -a /var/log/messages
        exit 1
    fi
;;

stop)
    echo "* Stopping Webmethods broker" | tee -a /var/log/messages
    $WM_BROKER_DIR/S45broker65 stop
;;

status)
    echo "* Checking Webmethods broker status" | tee -a /var/log/messages
    ps -ef | grep -v grep | grep awbrokermon
;;

esac
