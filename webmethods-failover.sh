#!/bin/bash
#
# Migrate running webmethods broker service to other node
#
################

NODE=abprod23
SERVICE=WM

echo "* Moving $SERVICE service to $NODE" | tee -a /var/log/messages
clusvcadm -R $SERVICE -m $NODE
