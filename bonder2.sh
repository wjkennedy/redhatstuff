#set -x
for i in eth0 eth1 eth2 eth3 eth4 eth5 eth6 

do
echo "Checking $i..."
ethtool $i 1>2&> /dev/null
if [ $? = 0 ]
	then
		#echo -e "$i \c"
		ifconfig $i | grep HWaddr| grep HWaddr | cut -d: -f 3-8
fi
done | sort -k2 | tee > /tmp/INTERFACES.$$

while read MAC
do
	for ifcfg in /etc/sysconfig/network-scripts/ifcfg-*
	do
		grep $MAC $ifcfg
		if [ $? = 0 ]
			then
				echo "$MAC found in $ifcfg"
		fi
	done

done < /tmp/INTERFACES.$$


#for i in eth0 eth1 eth2 eth3 eth4 eth5 ; do echo -e "$i \c" ; ifconfig $i 2>/dev/null | grep HWaddr | cut -d: -f 3-8 ; done | sort -k 2

