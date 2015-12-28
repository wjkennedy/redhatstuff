#!/bin/bash
#===============================================================================
#
#          FILE:  if_clusfrz
# 
#         USAGE:  if_clusfrz  -s service(s) -m member_node freeze|unfreeze
#
#   DESCRIPTION:  Utility to migrate services onto a particular node
#                 and re-enable the services at a later time.
# 
#         NOTES:  ---
#        AUTHOR:  William Kennedy
#       COMPANY:   
#       VERSION:  1.0
#       CREATED:  8/8/2008 1:10:12 PM Mountain Daylight Time
#      REVISION:  ---
#===============================================================================
set -x

FOUND_NODES=`grep 'clusternode name' /etc/cluster/cluster.conf | awk -F\" '{print $2}'`
FOUND_SERVICES=`grep 'service' /etc/cluster/cluster.conf | grep name | awk -F\" '{print $6}' | sed '/^$/d'`

usage(){
echo "Utility to migrate services onto a particular node and re-enable the services at a later time."
echo "Usage: $0 [-i|--interactive] -s service(s) -m member_node freeze|unfreeze"
echo
}

# Check validity of nodes in cluster.conf
check_nodes(){
echo "Checking nodes: $nodes"
for node in $nodes
do
	grep $node /etc/cluster.conf
	if [ $? != 0]
	then
		echo "$node not found in cluster.conf"
	fi
done
}

# Perform interactive node/service query
do_interactive(){
echo "Interactive mode:"
echo "Services available:"
echo "----------------"
echo "$FOUND_SERVICES"
echo
echo "Nodes available:"
echo "----------------"
echo "$FOUND_NODES"
echo ; echo
echo "Nodes to act on?"
read nodes
	if [ -z $nodes ]
	then
		echo "No nodes entered."
		do_interactive
	else
		grep $nodes /etc/cluster/cluster.conf
		if [ $? = 0]
			then
				echo "Nodes: $nodes"
				echo "Correct?"
				read ans
				case $ans in
				"n"|"N")
					echo "Reconfiguring..."
					do_interactive
				;;
				"y"|"Y")
					check_nodes
					if [ $? != 0 ]
					then
						echo "Invalid nodes: $nodes"
						sleep 1 ; do_interactive
					fi
				;;
				esac
	

	fi
echo
#
# Houston, we have nodes...
#
echo "Services to freeze?"
read services
	if [ -z $services ]
	then
		echo "No services entered."
		do_interactive
	else
		grep $services /etc/cluster/cluster.conf
		if [ $? = 0]
			then
				echo "Services: $services"
				echo "Correct?"
				read ans
				case $ans in
				"n"|"N")
	                               	echo "Reconfiguring..."
                                        do_interactive
                                ;;
                                "y"|"Y")
                                        check_nodes
                                        if [ $? != 0 ]
                                        then
                                                echo "Invalid nodes: $nodes"
                                                sleep 1 ; do_interactive
                                        fi
                                ;;
                                esac


        fi

}
# End of functions
############################################################
do_interactive
