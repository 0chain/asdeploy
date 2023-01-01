#!/bin/bash

export PATH=$PATH:/root/bin
source ~/.profile
source ./blob_func.sh

cd ~
mkdir -p ~/cfg

if [[ -f ~/cfg/numblobbers.txt ]] ; then
	BLOBBER=$(cat ~/cfg/numblobbers.txt)
fi
while [[ -z $BLOBBER ]]
do
	read -p "Enter the number of Blobbers: " BLOBBER
done
echo -n $BLOBBER > ~/cfg/numblobbers.txt

if [[ -f ~/cfg/blobbercap.txt ]] ; then
	BLOBBERCAP=$(cat ~/cfg/blobbercap.txt)
fi
while [[ -z $BLOBBERCAP ]]
do
	read -e -i 1073741824 -p "Enter Blobber Capacity (1073741824): " BLOBBERCAP
done
echo -n $BLOBBERCAP > ~/cfg/blobbercap.txt

if [[ -f ~/cfg/url.txt ]] ; then
	URL=$(cat ~/cfg/url.txt)
fi
while [[ -z $URL ]]
do
    read -p "Enter the PUBLIC_URL or your domain name. Example: john.mydomain.com : " URL
done
echo -n $URL > ~/cfg/url.txt

if [[ -f ~/cfg/email.txt ]] ; then
	EMAIL=$(cat ~/cfg/email.txt)
fi
while [[ -z $EMAIL ]]
do
    read -p "Enter your EMAIL ID: " EMAIL
done
echo -n $EMAIL > ~/cfg/email.txt

if [[ -f ~/cfg/dns.txt ]] ; then
	DNS=$(cat ~/cfg/dns.txt)
fi
while [[ -z $DNS ]]
do
    read -e -i "https://beta.zus.network/dns" -p "Enter the DNS url of the network. Example: https://test.zus.network/dns : " DNS
done
echo -n $DNS > ~/cfg/dns.txt
echo -n $DNS > ~/cfg/network.txt

echo "BLOBBERS: $BLOBBER"
echo "ENDPOINT: $PUBLIC_ENDPOINT"
echo "EMAIL: $EMAIL"
echo "DNS: $DNS"

echo -e "\n \e[93m =============================================== Installing some pre-requisite tools on the server =================================================  \e[39m"
install_tools_utilities parted
install_tools_utilities build-essential
install_tools_utilities dnsutils
install_tools_utilities git
install_tools_utilities vim
install_tools_utilities jq
install_tools_utilities htop
install_tools_utilities zip
install_tools_utilities unzip

install_tools_utilities docker.io
DOCKERCOMPOSEVER=v2.2.3 ; sudo apt install docker.io -y; sudo systemctl enable --now docker ; docker --version	 ; sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKERCOMPOSEVER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &> /dev/null; sudo chmod +x /usr/local/bin/docker-compose ; docker-compose --version
sudo chmod 777 /var/run/docker.sock

echo -e "\n \e[93m =============================================== Fetching other dependent scripts i.e. needed to deploy the blobbers. =================================================  \e[39m"
wget https://raw.githubusercontent.com/0chain/asdeploy/upgrade_blob_deploy/blob_nginx.sh -O nginx.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/upgrade_blob_deploy/blob_config.sh -O blob_config.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/upgrade_blob_deploy/blob_gen.sh -O blob_gen.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/upgrade_blob_deploy/blob_files.sh -O blob_files.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/upgrade_blob_deploy/blob_run.sh -O blob_run.sh
wget https://raw.githubusercontent.com/0chain/asdeploy/upgrade_blob_deploy/blob_del.sh -O blob_del.sh

#checking if ip is already added the to DNS & is it resolving or not.
check_dns
