#!/bin/bash
# Kickstart configuration aid
#
# Tool to interactively configure Redhat Kickstart scripts
# Keys on standards in MASTERFILE.00.cfg
# 
# Mon Jun 30 15:13:48 MDT 2008
# William Kennedy
# <william.kennedy@formerproject.com>
#
#######################################################
DATE=`date +%Y%m%d`
OSBUILDDATE=`date +%m\\\/%d\\\/%Y`

umask 0644

#set -x
##################################
# Define functions
############################



############################
# Get the basic kickstart configuration
# error exit code 201
GetKSFILE(){
if [ -f /kickstart/config/MASTERFILE-generic ]
then
    echo $0
	echo $OSBUILDDATE | sed 's/\\//g'
    echo "---------------------------------"
	echo "Using the default base file - /kickstart/config/MASTERFILE-generic"
	KSFILE="/kickstart/config/MASTERFILE-generic"
else
	echo "Where is the base kickstart file? [/kickstart/config/MASTERFILE-generic]"
	read KSFILE
		if [ -z $KSFILE ]
			then
			echo "Using the default - /kickstart/config/MASTERFILE-generic"
			KSFILE="/kickstart/config/MASTERFILE-generic"
		fi
fi
}
############################

############################
# get the hostname
GetHOSTNAME(){
echo -e "\n-What is the System hostname (new or old format) for the host to configure?"
read HOSTNAME
if [ -z $HOSTNAME ]
then
	echo "-- Hostname cannot be blank --"
	GetHOSTNAME
else
echo -e "\t$HOSTNAME"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")

	
		# check for new/old format
		CHARCOUNT=`echo $HOSTNAME | awk -F - '{ print $1 }' | wc -c`
		case $CHARCOUNT in
			"6")
				# do conversion
				NEWHOSTNAME=`echo $HOSTNAME | sed 's%\(..\)\(...-\)\(.\)\(..\)\(...\)%\1-\2\3-\4-\5%'| sed 's/0//g'| sed 's/73/703/g'`
				echo "Old hostname format entered - keeping and adding new format '$NEWHOSTNAME' to hosts file"
				# check for virtual
				echo "checking for RH virtual"
				echo $NEWHOSTNAME | grep "h\-v"
				if [ $? = "0" ]
					then
					echo -e "\t * Redhat virtual machine detected."
					VM="RH"
					VMHOSTNAME=`echo $NEWHOSTNAME | sed 's/-v/v-/'`
					NEWHOSTNAME=$VMHOSTNAME
				else
					echo "checking for SuSE"
					echo $NEWHOSTNAME | grep 'u\-v'
					if [ $? = "0" ]
						then
						echo "  * SuSE machine detected."
						echo "You need to use an AutoYaST file - not Kickstart!"
						exit 1
					fi
				fi
			;;
			
			"3")
				echo "New hostname format entered - keeping and using in place of old format to hosts file"
				NEWHOSTNAME=$HOSTNAME
			;;

			*)
				echo "Check the format of your hostname and re-enter."
				GetHOSTNAME
			;;
		esac	
				
		echo -e "\t $HOSTNAME accepted"
	;;
	"n"|"N")
		GetHOSTNAME
	;;
	
	#Default option
	*)
	# check for new/old format
		CHARCOUNT=`echo $HOSTNAME | awk -F - '{ print $1 }' | wc -c`
		case $CHARCOUNT in
			"6")
				# do conversion
				NEWHOSTNAME=`echo $HOSTNAME | sed 's%\(..\)\(...-\)\(.\)\(..\)\(...\)%\1-\2\3-\4-\5%'| sed 's/0//g'| sed 's/73/703/g'`
				echo "Old hostname format entered - keeping and adding new format '$NEWHOSTNAME' to hosts file"
				
				# check for virtual
				echo "checking for RH virtual"
				echo $NEWHOSTNAME | grep "h\-v"
				if [ $? = "0" ]
					then
					echo "  * Redhat virtual machine detected."
					VM="RH"
					VMHOSTNAME=`echo $NEWHOSTNAME | sed 's/-v/v-/'`
					NEWHOSTNAME=$VMHOSTNAME
				else
					echo "checking for SuSE"
					echo $NEWHOSTNAME | grep 'u\-v'
					if [ $? = "0" ]
						then
						echo "  * SuSE machine detected."
						echo "You need to use an AutoYaST file - not Kickstart!"
						exit 1
					fi
				fi		

			;;
			
			"3")
				echo "New hostname format entered - keeping and using in place of old format to hosts file"
				NEWHOSTNAME=$HOSTNAME
			;;

			*)
				echo "Check the format of your hostname and re-enter."
				GetHOSTNAME
			;;
		esac	
				
		echo -e "\t $HOSTNAME accepted"
	;;

esac
# Find the Datacenter based on the hostname - pd, od, etc
DC=`echo $HOSTNAME | head -c2`
case $DC in
	od)
		echo "Omaha Datacenter detected."
		echo "Setting timezone to Central"
		TIMEZONE="America\/Chicago"
		DCLOC="Omaha"
        NFSKSIP="10.201.3.36"
	;;

	pd)
		echo "Tempe Datacenter detected."
		echo "Setting timezone to Mountain"
		TIMEZONE="America\/Phoenix"
		DCLOC="Tempe"
        NFSKSIP="10.201.7.31"
	;;
esac
fi

echo -e "\n-What is the Customer hostname of $HOSTNAME?"
read CUSTHOSTNAME
echo -e "\tYou entered '$CUSTHOSTNAME'"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\tCustomer hostname '$CUSTHOSTNAME' accepted"
		
	;;
	"n"|"N")
		GetHOSTNAME
	;;
	*)
		echo -e "\tCustomer hostname '$CUSTHOSTNAME' accepted"
	;;

esac
}
############################


############################
# what's the IP for the internet-facing interface?
GetCFNIP(){
echo -e "\n-What is the CFN IP address of the host to configure?"
read CFNIP
if [ -z $CFNIP ]
then GetCFNIP
else
echo -e "\t$CFNIP"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\tCFN IP address '$CFNIP' accepted"
		
	;;
	"n"|"N")
		GetCFNIP
	;;
	*)
		echo -e "\tCFN IP address '$CFNIP' accepted"
	
	;;

esac
fi
}
############################

############################
# what's the netmask for the internet-facing interface?
GetCFNNM(){
echo -e "\n-What is the Netmask for the CFN interface of $HOSTNAME?"
read CFNNM
if [ -z $CFNNM ]
then GetCFNNM
else
echo -e "\t$CFNNM"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\tCFN Netmask '$CFNNM' accepted"
		
	;;
	"n"|"N")
		GetCFNNM
	;;
	*)
		echo -e "\tCFN IP Netmask '$CFNNM' accepted"
	
	;;

esac
fi
}
############################

############################
# what's the netmask for the Backup Network interface?
GetBRNNM(){
echo -e "\n-What is the Netmask for the BRN interface of $HOSTNAME?" 
read BRNNM
if [ -z $BRNNM ]
then GetBRNNM
else
echo -e "\t$BRNNM"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\tBRN Netmask '$BRNNM' accepted"
		
	;;
	"n"|"N")
		GetBRNNM
	;;
	*)
		echo -e "\tBRN IP Netmask '$BRNNM' accepted"
	
	;;

esac
fi
}
############################

############################
GetBRNIP(){
echo -e "\n-What is the BRN IP address of the host to configure?"
read BRNIP
if [ -z $BRNIP ]
then GetBRNIP
else
echo -e "\t$BRNIP"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\t Backup network IP address '$BRNIP' accepted"
		BRNHEX=`printf '%02X' ${BRNIP//./ }; echo`
		echo -e "\n\t NOTE: BRN IP address in hex is: '$BRNHEX'\n\t This will be in /tmp/$HOSTNAME.cfg "
	;;
	"n"|"N")
		GetBRNIP
	;;

	*)
		echo -e "\t Backup network IP address '$BRNIP' accepted"
		BRNHEX=`printf '%02X' ${BRNIP//./ }; echo`
		echo -e "\n\t NOTE: BRN IP address in hex is: '$BRNHEX'\n\t This will be in /tmp/$HOSTNAME.cfg "
	;;
esac
fi
}
############################

############################
GetBRNGW(){
COMPUTEDGW=`echo $BRNIP | awk -F . 'BEGIN { OFS = "."} {print $1,$2,$3,"1"}'`
echo -e "\n-What is the IP address of the BRN gateway? [$COMPUTEDGW]"
read BRNGW
if [ -z $BRNGW ]
then
	echo -e "\t Using computed gateway for $BRNIP: '$COMPUTEDGW'"
	BRNGW=$COMPUTEDGW
else
echo -e "\t$BRNGW"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\t BRN gateway IP address '$BRNGW' accepted"
		
	;;
	"n"|"N")
		GetBRNGW
	;;

	*)
		echo -e "\t BRN gateway IP address '$BRNGW' accepted"
		
	;;

esac
fi
}
############################

############################
GetCFNGW(){
COMPUTEDGW=`echo $CFNIP | awk -F . 'BEGIN { OFS = "."} {print $1,$2,$3,"1"}'`
echo -e "\n-What is the IP address of the CFN gateway? [$COMPUTEDGW]"
read CFNGW
if [ -z $CFNGW ]
then
	echo -e "\t Using computed gateway for $CFNIP: '$COMPUTEDGW'"
	CFNGW=$COMPUTEDGW
else
echo -e "\t$CFNGW"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\t CFN gateway IP address '$CFNGW' accepted"
		
	;;
	"n"|"N")
		GetCFNGW
	;;

	*)
		echo -e "\t CFN gateway IP address '$CFNGW' accepted"
		
	;;

esac
fi
}
############################



############################
# Determine Redhat version (es4/es5)
GetVER(){
echo -e "\n-What RHEL version are you installing? (es4 - default, as4, es5) [es4]"
read ans
case $ans in
	"es4")
		VER="es4"
		echo -e "\t Using '$VER'"
	;;
	"as4")
		VER="as4"
		echo -e "\t Using '$VER'"
		
	;;
	"es5")
		VER="es5"
		echo -e "\t Using '$VER'"
        echo "Please enter the RHEL 5 software key:"
            read RHEL5KEY
            if [ -z $RHEL5KEY ]
            then
                echo "Key required."
                GetVER
            else
             echo -e "\t Using RHEL 5 key: $RHEL5KEY"
             # Get the RHEL 5 software key
             case $ans in
        	    "Y"|"y")
    	    	echo -e "\t RHEL 5 key: '$RHEL5KEY' accepted"
    	        ;;
           
             	"n"|"N")
	            GetVER
        	    ;;

	            *)
		        echo -e "\t RHEL 5 key: '$RHEL5KEY' accepted"
    	        ;;

            esac           
           fi
  	;;

    *)
   VER="es4"

   echo -e "\t Using default: '$VER'"
		
   ;;
esac
	
if [ -z $VER ]
then
	echo -e "\t Using default: RHEL es4" 
	VER="es4"
fi

echo -e "\t Using version '$VER'"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\t Version '$VER' accepted"
		
	;;
	"n"|"N")
		GetVER
	;;
	*)
		echo -e "\t Version '$VER' accepted"
		
	;;

esac
}
############################

############################
# Determine Server architecture
GetARCH(){
echo -e "\n-What is the Server Architecture? i386, x86_64, ia64 [x86_64] "
read ans
case $ans in
	"i386")
		ARCH="i386"
		echo -e "\t Using '$ARCH'"
	;;
	"x86_64"|"x86-64")
		ARCH="x86_64"
		echo -e "\t Using '$ARCH'"
		
	;;
	"ia64")
		ARCH="ia64"
		echo -e "\t Using '$ARCH'"
	;;
	*)
		ARCH="x86_64"
		echo -e "\t Using default: '$ARCH'"
		
	;;
esac
	
if [ -z $ARCH ]
then
	echo -e "\t Using default: x86_64" 
	ARCH="x86_64"
fi

echo -e "\t Using system architecture '$ARCH'"
echo "Is this correct? [Y/n]"
read ans
case $ans in
	"Y"|"y")
		echo -e "\t Architecture '$ARCH' accepted"
		
	;;
	"n"|"N")
		GetARCH
	;;
	*)
		echo -e "\t Architecture '$ARCH' accepted"
		
	;;

esac
}
############################

############################
# where is the NFS mount for Kickstarting?
GetNFSKSIP(){
if [ -z NFSKSIP ]
    then
     echo -e "\n-What is the Kickstart Server's NFS IP address? [10.201.7.31]"
     read NFSKSIP 
        if [ -z $NFSKSIP ]
            then
            	echo -e "\t Using Tempe DC default - 10.201.7.31"
            	NFSKSIP="10.201.7.31"
            else
            	echo "Is this correct? [Y/n]"
            	read ans
                	case $ans in
                	"Y"|"y")
            		echo -e "\t NTP Kickstart source IP '$NFSKSIP' accepted"
	                ;;
                	"n"|"N")
            		GetNFSKSIP
                	;;
                	*)
            		echo -e "\t NTP Kickstart source IP '$NFSKSIP' accepted"
	                ;;
                    esac
        fi
    else
        echo "Using $DCLOC's default NFS kickstart IP: $NFSKSIP"
fi

}
############################


############################
# get the interface to use for DHCP configuration
GetETHIF(){
echo -e "\n-What is the Ethernet Interface to Kickstart with? [eth0]"
read ETHIF 
if [ -z $ETHIF ]
then
	echo -e "\t Using default - eth0"
	ETHIF="eth0"
else
	echo "Using '$ETHIF'"
	echo "Is this correct? [Y/n]"
	read ans
	case $ans in
	"Y"|"y")
		echo -e "\t Ethernet interface '$ETHIF' for use with Kickstart accepted"
		
	;;
	"n"|"N")
		GetETHIF
	;;
	*)
		echo -e "\t Ethernet interface '$ETHIF' for use with Kickstart accepted"
		
	;;

	esac
fi
}
############################

############################
# get the timezone information for this DC/Host
GetTIMEZONE(){ 
if [ -z $TIMEZONE ]
	then
	echo -e "\n-What is the Timezone of this host ($HOSTNAME) - [America/Tempe]" 
	echo -e "NOTE: You must escape the slash\n" 
	# NOTE: Is America/Tempe a valid timezone? 
	echo -e "\t Other choices are:\n\t 1. 'America/NewYork (Eastern)\n\t 2. 'America/Chicago (Central)\n\t 3. 'America/LosAngeles (Pacific)\n\t 4. 'America/Denver (Mountain)'\n--------------------------------" 
	read TIMEZONE
	if [ -z $TIMEZONE ]
	then
	        echo -e "\t Using default - America/Chicago (Central)"
	        TIMEZONE="America\/Central"
	else
	        echo "Is this correct? [Y/n]"
	        read ans
	        case $ans in
	        "1")
			TIMEZONE="America\/NewYork"
	                echo -e "\t Timezone '$TIMEZONE' accepted"
	                 
	        ;;
	        "2")
			TIMEZONE="America\/Chicago"
	                echo -e "\t Timezone '$TIMEZONE' accepted"
	        ;;
	 	
		"3")
			TIMEZONE="America\/LosAngeles"
	                echo -e "\t Timezone '$TIMEZONE' accepted"
	        ;; 
	 
		"4")
			TIMEZONE="America\/Denver"
	                echo -e "\t Timezone '$TIMEZONE' accepted"
	        ;; 
	
	        *) 
			TIMEZONE="America\/Chicago"
	                echo -e "\t Default timezone '$TIMEZONE' accepted"
	                 
	        ;; 
		esac 
	fi 
	else
		echo "Timezone set from Datacenter key $DCLOC: $TIMEZONE"
fi
}
############################

############################
# Any packages to add?
GetADDPKG(){
echo -e "- Are you adding any additional kickstart-installable packages? [n]"
read ans 
	case $ans in
	"Y"|"y")
		echo -e "In progess.  Skipping for now, but see SelectNewPackages()"
		#SelectNewPackages
	;;
	"n"|"N")
		echo -e "Skipping for now"
	;;
	*)
		echo -e "Skipping for now"
	;;
	esac
}
############################



############################
# make the actual kickstart file
# substituting our values for the placeholders in the generic config
# copy from base to $HOSTNAME.cfg
MakeFinalKickstart(){
echo -e "\n*** Creating kickstart ***"
cp $KSFILE /tmp/$HOSTNAME.cfg
# if we have problems copying the kickstart, throw 202
if [ $? != "0" ]
then
	echo "Error 202: Errors encountered copying Kickstart base file."
	exit 202
fi
# all clear to sed
sed -i "s/_DATE/$DATE/g" /tmp/$HOSTNAME.cfg

sed -i "s/_BRNHEX/$BRNHEX/g" /tmp/$HOSTNAME.cfg

sed -i "s/_HOSTNAME/$HOSTNAME/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set hostname to $HOSTNAME - check _HOSTNAME in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_CUSTHOSTNAME/$CUSTHOSTNAME/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set customer hostname to $CUSTHOSTNAME - check for _CUSTHOSTNAME in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_NEWHOSTNAME/$NEWHOSTNAME/g" /tmp/$HOSTNAME.cfg

sed -i "s/_HOSTNAME.dmz.i-structure.com/$HOSTNAME.dmz.i-structure.com/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set hostname to $HOSTNAME - check _HOSTNAME in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_CFNIP/$CFNIP/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set CFN interface IP to $CFNIP - check _IFNIP in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_BRNIP/$BRNIP/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set BRN interface IP to $BRNIP - check _BRNIP in /tmp/$HOSTNAME.cfg"
fi

# Set the RHEL 5 key if applicable
if [ ! -z $RHELKEY ]
then
    sed -i "s/key --skip/key $RHEL5KEY" /tmp/$HOSTNAME.cfg
    if [ $? != "0" ]
    then
        echo "Could not set RHEL 5 key to '$RHEL5KEY' - setting to ask during Anaconda phase."
    fi
fi

sed -i "s/_ARCH/$ARCH/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set architecture to $ARCH - check _ARCH in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_ETHIF/$ETHIF/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set ethernet interface to $ETHIF - check _ETHIF in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_BRNGW/$BRNGW/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set BRN gateway to $BRNGW - check _BRNGW in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_CFNGW/$CFNGW/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set CFN gateway to $CFNGW - check _CFNGW in /tmp/$HOSTNAME.cfg"
fi


sed -i "s/_NFSKSIP/$NFSKSIP/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set NFS Kickstart IP to $NFSKSIP - check _NFSKSIP in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_TIMEZONE/$TIMEZONE/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set Timezone to $TIMEZONE - check _TIMEZONE in /tmp/$HOSTNAME.cfg"
fi


#Altiris specific stuff
sed -i "s/_OSBUILDDATE/$OSBUILDDATE/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set Altiris OS Build Date to $OSBUILDDATE - check _OSBUILDDATE in /tmp/$HOSTNAME.cfg"
fi

sed -i "s/_DCLOC/$DCLOC/g" /tmp/$HOSTNAME.cfg
if [ $? != "0" ]
then
	echo "Warning: Could not set Altiris Datacenter location to '$DCLOC' - check _DCLOC in /tmp/$HOSTNAME.cfg"
fi

echo -e "\n*** Created /kickstart/config/$HOSTNAME.cfg ***"
cp /tmp/$HOSTNAME.cfg /kickstart/config/
chmod 644 /kickstart/config/$HOSTNAME.cfg
dos2unix /kickstart/config/$HOSTNAME.cfg
echo "Please verify manually."
}
######################################################################

PrepareKICKSTART(){

# if we made it this far, things are good.
# show what we've come up with
echo -e "\n*************************************"
echo "You are going to configure a new kickstart file $HOSTNAME.cfg"
echo "based on $KSFILE :"
echo -e "*************************************"
echo -e "OS Build Date: \t\t $OSBUILDDATE" | sed 's/\\//g'
echo -e "System hostname:\t\t $HOSTNAME"
echo -e "New System hostname:\t $NEWHOSTNAME"
echo -e "Customer hostname:\t $CUSTHOSTNAME"
echo -e "CFN IP address:\t\t $CFNIP"
echo -e "CFN Gateway IP address:\t $CFNGW"
echo -e "BRN IP address:\t\t $BRNIP"
echo -e "BRN IP in HEX for PXE:\t $BRNHEX"
echo -e "BRN Gateway IP address:\t $BRNGW"
#echo -e "(actual) BRN MAC:\t `echo $MAC | sed 's/-/:/'`"

# virtual machine
if [ ! -z $VM ]
then
	echo -e "Virtual machine:\t $VM"
fi

echo -e "RHEL version:\t\t $VER"
# display the RHEL5 software key if present
if [ ! -z $RHEL5KEY ]
then
	echo -e "RHEL 5 software key:\t $RHEL5KEY"
fi

echo -e "Architecture:\t\t $ARCH"
echo -e "Loading via interface:\t $ETHIF"
echo -e "Kickstart NFS mount:\t $NFSKSIP"
echo -e "Timezone:\t\t $TIMEZONE"
echo -e "Datacenter:\t\t $DCLOC"
echo -e "*************************************"
echo -e "\nIs this information correct? [Y/n]"
# give an opportunity to verify and reconfigure
read ans
case $ans in
	"n"|"N")
		echo "Reconfiguring $HOSTNAME.cfg.."
		# run through configuration again
		main
		;;
	"y"|"Y")
		echo "Generating kickstart file $/tmp/#HOSTNAME.cfg..."
		MakeFinalKickstart
		;;
	*)
		echo "Generating kickstart file $KSFILE..."
		MakeFinalKickstart
		;;
esac

}
############################

############################
# make a pxelinux config file
MakePXECONFIG(){
if [ -f /tftpboot/pxelinux.cfg/00_PXEFILE,v1_00-generic.cfg ]
then
	echo "Using the default base file - /tftpboot/pxelinux.cfg/00_MASTERFILE,v1_00-generic.cfg"
	PXEFILE="/tftpboot/pxelinux.cfg/00_PXEFILE,v1_00-generic.cfg"
else
	echo "Where is the base PXE configuration file? [/tftpboot/pxelinux.cfg/00_PXEFILE,v1_00-generic.cfg]"
	read PXEFILE
		if [ -z $PXEFILE ]
			then
			echo "Using the default - /tftpboot/pxelinux.cfg/00_PXEFILE,v1_00-generic.cfg"
			PXEFILE="/tftpboot/pxelinux.cfg/00_PXEFILE,v1_00-generic.cfg"
		fi
fi

echo -e "\n*** Creating PXE Configuration ***"
cp $PXEFILE /tmp/$HOSTNAME.pxe
# if we have problems copying the kickstart, throw 202
if [ $? != "0" ]
then
	echo "Error 202: Errors encountered copying PXE base file."
	exit 202
fi
# all clear
sed -i "s/_DATE/$DATE/g" /tmp/$HOSTNAME.pxe
sed -i "s/_VER/$VER/g" /tmp/$HOSTNAME.pxe
sed -i "s/_BRNHEX/$BRNHEX/g" /tmp/$HOSTNAME.pxe
#required information from here down
sed -i "s/_HOSTNAME/$HOSTNAME/g" /tmp/$HOSTNAME.pxe
	if [ $? != "0" ]
	then
		echo "Warning: Could not set hostname to $HOSTNAME - check _HOSTNAME in /tmp/$HOSTNAME.pxe"
	fi

sed -i "s/_BRNIP/$BRNIP/g" /tmp/$HOSTNAME.pxe
	if [ $? != "0" ]
	then
		echo "Warning: Could not set BRN interface IP to $BRNIP - check _BRNIP in /tmp/$HOSTNAME.pxe"
	fi

sed -i "s/_ETHIF/$ETHIF/g" /tmp/$HOSTNAME.pxe
	if [ $? != "0" ]
	then
		echo "Warning: Could not set load interface to $ETHIF - check _ETHIF in /tmp/$HOSTNAME.pxe"
	fi

sed -i "s/_ARCH/$ARCH/g" /tmp/$HOSTNAME.pxe
	if [ $? != "0" ]
	then
		echo "Warning: Could not set architecture to $ARCH - check _ARCH in /tmp/$HOSTNAME.pxe"
	fi

sed -i "s/_NFSKSIP/$NFSKSIP/g" /tmp/$HOSTNAME.pxe
	if [ $? != "0" ]
	then
		echo "Warning: Could not set NFS Kickstart IP to $NFSKSIP - check _NFSKSIP in /tmp/$HOSTNAME.pxe"
	fi

echo -e "\n***  Created /tmp/$HOSTNAME.pxe ***"
echo "Please verify manually, and move to /tftpboot/pxelinux.cfg"

# Get the MAC and create a link to the new config file
echo -e "\nIf available, enter the MAC Address for $HOSTNAME, separated with dashes\nprefaced with a'01-' e.g. 01-00-11-22-33-44-55"
echo -e "\nIf it's NOT available, leave MAC blank, and press Enter to skip."
echo "You will need to manually link $HOSTNAME.pxe to MAC address, prefaced with 01."
read MAC
if [ -z $MAC ]
then
	echo "BRN interface MAC not available."
	echo "Copy manually and add link from $HOSTNAME.pxe to MAC address"
else
    REALMAC=`echo $MAC | sed 's/-/:/g'`
    sed -i "s/_MAC/$REALMAC/g" /tmp/$HOSTNAME.pxe
	echo -e "\n Copying /tmp/$HOSTNAME.pxe to /tftpboot/pxelinux.cfg"
	cp /tmp/$HOSTNAME.pxe /tftpboot/pxelinux.cfg/$HOSTNAME
	chmod 644 /tftpboot/pxelinux.cfg/$HOSTNAME
	dos2unix /tftpboot/pxelinux.cfg/$HOSTNAME
	if [ $? != "0" ]
		then
			echo "Error copying /tmp/$HOSTNAME.pxe"
		else
			echo "Creating link from /tftpboot/pxelinux.cfg/$HOSTNAME.pxe to /tftpboot/pxelinux.cfg/$MAC"
			if [ -f /tftpboot/pxelinux.cfg/`echo $MAC| tr [A-Z] [a-z]` ]
			then
				echo "Removing old link for `echo $MAC| tr [A-Z] [a-z]`"
				echo -e "\n*** Backing up existing /tftpboot/pxelinux.cfg/$HOSTNAME ***"
				acp /tftpboot/pxelinux.cfg/$HOSTNAME
				rm /tftpboot/pxelinux.cfg/`echo $MAC| tr [A-Z] [a-z]`
			fi
			cd /tftpboot/pxelinux.cfg
			echo "Creating new link for `echo $MAC| tr [A-Z] [a-z]`"
			ln -s $HOSTNAME `echo $MAC| tr [A-Z] [a-z]`
			cd /kickstart
				if [ $? != "0" ]
					then
					echo "Error linking /tftpboot/pxelinux.cfg/$HOSTNAME to $MAC"
					echo "Manually create link from /tftpboot/pxelinux.cfg/$HOSTNAME to /tftpboot/pxelinux.cfg/$MAC"
				fi
	fi
fi
}
############################

######################################################################
# BEGIN MAIN ROUTINE
######################################################################
main(){

clear

GetKSFILE
if [ $? -ne "0" ]
then
	echo "Error 201: Errors encountered getting Kickstart base file."
	exit 201
fi
GetHOSTNAME
if [ $? -ne "0" ]
then
	echo "Error 301: Errors encountered getting System hostname."
	exit 301
fi
GetCFNIP
if [ $? -ne "0" ]
then
	echo "Error 401: Errors encountered getting CFN IP address."
	exit 401
fi
GetCFNGW
if [ $? -ne "0" ]
then
	echo "Error 402: Errors encountered getting CFN Gateway IP address."
	exit 402
fi

GetBRNIP
if [ $? -ne "0" ]
then
	echo "Error 501: Errors encountered getting BRN IP address."
	exit 501
fi
GetBRNGW
if [ $? -ne "0" ]
then
	echo "Error 502: Errors encountered getting BRN Gateway IP address."
	exit 502
fi

GetVER
if [ $? -ne "0" ]
then
	echo "Error 601: Errors encountered getting RHEL version."
	exit 601
fi

GetARCH
if [ $? -ne "0" ]
then
	echo "Error 602: Errors encountered getting system architecture."
	exit 602
fi
GetETHIF
if [ $? -ne "0" ]
then
	echo "Error 701: Errors encountered getting ethernet device to perform kickstart."
	exit 701
fi
GetNFSKSIP
if [ $? -ne "0" ]
then
	echo "Error 801: Errors encountered getting IP of Kickstart NFS mount."
	exit 801
fi
GetTIMEZONE
if [ $? -ne "0" ]
then
	echo "Error 901: Errors encountered getting timezone information."
	exit 901
fi
GetADDPKG
if [ $? -ne "0" ]
then
	echo "Error 1001: Errors encountered getting add'l packages."
	exit 1001
fi

PrepareKICKSTART

# Offer to create the PXELINUX configuration
echo -e "\n---------------------------"
echo "Create and link the PXE configuration for $HOSTNAME? [Y/n]"
read ans
case $ans in

	"Y"|"y")
			echo "Creating PXE configuration..."
			MakePXECONFIG
	;;

	"N"|"n")
			echo "Follow the procedure for creating and providing a PXE configuration."
	;;

	*)	
			echo "Creating PXE configuration..."
			MakePXECONFIG
	;;
esac
}

######################################################################
######################################################################
# END GET CONFIGURATION
######################################################################
######################################################################

# Here's where the real work gets done
#  1. Call the main configuration function
#     - this function incorporates all the sub-functions to gather data
#       * this should really be re-factored to source the functions from a file
#  2. After main completes, we see if we should go around again, and again...
# 
main

# One more time? One more time? One more time? One more...
# AKA - "the Merry-Go-Round" or "The Kickstart Hoedown"
echo -e "*************************************"
echo "Generate another kickstart file? [Y/n]"
read ans
case $ans in
	
	"y"|"Y")
		echo "  - Creating another kickstart file."
		main
	;;
	
	"n"|"N")
		echo "  - Done"
	;;

	*)
		echo "  - Creating another kickstart file."
		main
	;;
esac

# out of the loop
exit 0
