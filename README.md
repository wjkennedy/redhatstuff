# Red Hat Stuff

This is a sample of scripts developed over the last several years used in the deployment, management and support of Red Hat Linux systems.

- Linux_QA_v1.0.sh

A simple validation script to ensure a Red Hat system meets internal standards

- bb_si_imagepackage.sh

A script to package a SystemImager image for replication to another datacenter or facility.

- bb_xenvmcreate.sh

A script to programmaticaly provision a Xen VM. This has been expanded for use in 'geer', a centralized systems management tool written in PHP.

- bonder2.sh

A simple script to bond two known ethernet interfaces

- change_kern_syms_to_match.sh

A bodge to modify Linux kernel symbols to match the available kernel version. **This is dangerous**.

- if_clusfrz.sh

A script to freeze a Red Hat Cluster, as for maintenance.

- if_crash_report.sh

A simple forensics utility.

- ifox-rhcs-cycle.sh

A script to cycle the state of a Red Hat Cluster.

- ks_pxe_configurator_0.5-1.sh

A script to configure and populate the parameters of a Kickstart script.

- makeinitrd.sh

Simple script to create an initial ramdisk.

- mountinitrd.sh

Simple script to mount an initial ramdisk, accounting for filesystem offset.

- oracle-infograb-rhel.sh

Dump Oracle RAC/RHEL system configuration

- si_initrdtools-dialog_0.3.1.sh

Interactive installation for SystemImager.

- webmethods-failback.sh

Utilize RHCS to failback a Webmethods J2EE Server.

- webmethods-failover.sh

Utilize RHCS to failover a Webmethods J2EE Server.

- webmethods-failovertest.sh

Utilize the scripts above to test the failover/failback performance of a Red Hat Cluster Suite.

- wmhandler.sh

Utilize the scripts above to test the failover/failback performance of a Red Hat Cluster Suite.
