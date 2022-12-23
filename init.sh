#!/bin/bash

cd ~
mkdir -p cfg


if [[ -f cfg/numsharders.txt ]] ; then
	SHARDER=$(cat cfg/numsharders.txt)
fi
while [[ -z $SHARDER ]]
do
	read -p "Enter the number of Sharders: " SHARDER
done
echo -n $SHARDER > cfg/numsharders.txt

if [[ -f cfg/numminers.txt ]] ; then
	MINER=$(cat cfg/numminers.txt)
fi
while [[ -z $MINER ]]
do
	read -p "Enter the number of Miners: " MINER
done
echo -n $MINER > cfg/numminers.txt

if [[ -f cfg/numblobbers.txt ]] ; then
	BLOBBER=$(cat cfg/numblobbers.txt)
fi
while [[ -z $BLOBBER ]]
do
	read -p "Enter the number of Blobbers: " BLOBBER
done
echo -n $BLOBBER > cfg/numblobbers.txt

if [[ -f cfg/blobbercap.txt ]] ; then
	BLOBBERCAP=$(cat cfg/blobbercap.txt)
fi
while [[ -z $BLOBBERCAP ]]
do
	read -e -i 1073741824 -p "Enter Blobber Capacity (1073741824): " BLOBBERCAP
done
echo -n $BLOBBERCAP > cfg/blobbercap.txt

if [[ -f cfg/url.txt ]] ; then
	URL=$(cat cfg/url.txt)
fi
while [[ -z $URL ]]
do
    read -p "Enter the PUBLIC_URL or your domain name. Example: john.mydomain.com : " URL
done
echo -n $URL > cfg/url.txt

if [[ -f cfg/email.txt ]] ; then
	EMAIL=$(cat cfg/email.txt)
fi
while [[ -z $EMAIL ]]
do
    read -p "Enter your EMAIL ID: " EMAIL
done
echo -n $EMAIL > cfg/email.txt

if [[ -f cfg/dns.txt ]] ; then
	DNS=$(cat cfg/dns.txt)
fi
while [[ -z $DNS ]]
do
    read -e -i "https://beta.zus.network/dns" -p "Enter the DNS url of the network. Example: https://test.zus.network/dns : " DNS
done
echo -n $DNS > cfg/dns.txt
echo -n $DNS > cfg/network.txt

echo "SHARDERS: $SHARDER"
echo "MINERS: $MINER"
echo "BLOBBERS: $BLOBBER"
echo "ENDPOINT: $PUBLIC_ENDPOINT"
echo "EMAIL: $EMAIL"
echo "DNS: $DNS"
    
sudo apt install parted build-essential dnsutils git nano jq htop zip unzip -y

DOCKERCOMPOSEVER=v2.2.3 ; sudo apt install docker.io -y ; sudo systemctl enable --now docker ; docker --version	 ; sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKERCOMPOSEVER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose ; sudo chmod +x /usr/local/bin/docker-compose ; docker-compose --version

sudo chmod 777 /var/run/docker.sock
    
if [[ ! -d z ]]
then
	apt install zip unzip -y
#	wget https://zcdn.uk/wp-content/uploads/2022/11/zdeployment-docker-deploy.zip
#	unzip zdeployment-docker-deploy.zip
#	rm zdeployment-docker-deploy.zip
#	mv zdeployment-docker-deploy z
fi

wget https://raw.githubusercontent.com/0chain/asdeploy/main/config.sh -O config.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/keygen.sh -O keygen.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/fetchkeys.sh -O fetchkeys.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/sharekeys.sh -O sharekeys.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/minerdeploy.sh -O minerdeploy.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/sharderdeploy.sh -O sharderdeploy.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/nginx.sh -O nginx.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/blobberconfig.sh -O blobberconfig.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/blobgen.sh -O blobgen.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/blobinit.sh -O blobinit.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/blobrun.sh -O blobrun.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/main/blobdel.sh -O blobdel.sh

URL=$(cat cfg/url.txt)
ipaddr=$(curl api.ipify.org)
myip=$(dig +short $URL)
if [[ "$myip" != "$ipaddr" ]]
then
  echo "$URL IP resolution mistmatch $myip vs $ipaddr"
else
  echo "SUCCESS $URL resolves to $myip"
fi

