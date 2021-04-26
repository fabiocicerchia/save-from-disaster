#!/bin/sh

IP=$1

ionice -c2 -n4 rsync -e "ssh -vi $HOME/.ssh/id_rsa" -auv --progress /var/www/ syncer@$IP:/var/www
