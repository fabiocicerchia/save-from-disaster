#!/bin/sh

IP=$1

rsync -e "ssh -vi $HOME/.ssh/id_rsa" -auv --progress /etc/letsencrypt/ syncertls@$IP:/etc/letsencrypt
