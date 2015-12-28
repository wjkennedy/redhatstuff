#!/bin/bash
#
# QnD script to cycle Redhat cluster services
# - Method adapted from 'Configuring and Managing a Redhat Cluster' manual
#
# William Kennedy
# Mon Jul 28 12:27:29 PDT 2008
##############################

echo "* IFOX QnD RHCS cycle"

stop(){

		echo "Stopping cluster services"
		echo " - rgmanager"
		service rgmanager stop && \
		echo " - gfs"
		service gfs stop && \
		echo " - clvmd"
		service clvmd stop && \
		echo " - fenced"
		service fenced stop && \
		echo " - cman"
		service cman stop && \
		echo " - ccsd"
		service ccsd stop && \
		echo " ** Cluster services stopped"
}

start(){
		echo "Starting cluster services"
		echo " - ccsd"
		service ccsd start && \
		echo " - cman"
		service cman start && \
		echo " - fenced"
		service fenced start && \
		echo " - clvmd"
		service clvmd start && \
		echo " - gfs"
		service gfs start && \
		echo " - rgmanager"
		service rgmanager start && \
		echo " ** Cluster services started"

}

case $1 in

	"stop")
		stop
	;;

	"start")
		start
	;;

	"restart")
		echo "Performing full RHCS recycle"
			stop
			start
	;;

	*)
		echo "Re-run $0 with [start|stop|restart]"
		echo "For Cluster status, run 'clustat'"
		echo
	;;

esac
