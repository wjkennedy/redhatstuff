#!/bin/bash

WATCH=2
ITERATIONS=50

echo "This will display the cluster status every $WATCH seconds"
echo "Crtl-C to exit 'watch'."
sleep 3

watch --interval $WATCH clustat &

while [ "$ITERATIONS" -ge 1 ]
do
	sh /usr/local/admin/bin/webmethods-failover.sh
	if [ $? != 0 ]
	then
		echo "Failover script failed."
		break
	else
		echo "** Failover successful. Waiting to fail back"
		sleep 400
		sh /usr/local/admin/bin/webmethods-failback.sh
		if [ $? = 0 ]
			then
				echo "** Failback successful."
				echo "  $ITERATIONS iterations remaining."
			else
			     	echo "Failover script failed."
				break
		fi
			
	fi
	ITERATIONS=$(($ITERATIONS -1))
done
killall watch
