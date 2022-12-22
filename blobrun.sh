#!/bin/bash

source new_config.sh

cd blobber
./docker.local/bin/blobber.init.setup.sh
exists=$(docker network ls --filter name=testnet0 -q)
if [[ ! $exists ]] ; then
	sudo docker network create --driver=bridge --subnet=198.18.0.0/15 --gateway=198.18.0.255 testnet0
fi
cd ..

NUMBLOBBERS=$( cat ~/cfg/numblobbers.txt )
for (( b = 1 ; b <= NUMBLOBBERS ; b++ )) ; do 
	cd ~/blobber/docker.local/blobber$b ; sudo ../bin/p0blobber.start.sh ; cd ~
done
