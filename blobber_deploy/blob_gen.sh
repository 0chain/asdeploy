#!/bin/bash

export PATH=$PATH:/root/bin
source ~/.profile
source ~/blob_func.sh
source ~/blob_config.sh

cli_input_deployment() {
  echo -e "\n Please input the following: \n"
  if [[ -f ~/cfg/numblobbers.txt ]]
  then
    BLOBBER=$(cat ~/cfg/numblobbers.txt)
  fi

  if [[ -f ~/cfg/url.txt ]]
  then
    URL=$(cat ~/cfg/url.txt)
  fi
  while [[ -z $URL ]]
  do
    read -p "Enter the URL or your domain name. Example: john.mydomain.com : " URL
  done

  if [[ -f ~/cfg/email.txt ]]
  then
    EMAIL=$(cat ~/cfg/email.txt)
  fi
  while [[ -z $EMAIL ]]
  do
    read -p "Enter your EMAIL ID: " EMAIL
  done

  if [[ -f ~/cfg/blobbercap.txt ]]
  then
    BLOBCAPACITY=$(cat ~/cfg/blobbercap.txt)
  fi
  while [[ -z $BLOBCAPACITY ]]
  do
    read -p "Enter your BLOBBERCAPACITY. Example (1TB): 1073741824 (1TB) : " BLOBCAPACITY
  done

  if [[ -f ~/cfg/dns.txt ]]
  then
    DNS=$(cat ~/cfg/dns.txt)
  fi
  while [[ -z $DNS ]]
  do
    read -p "Enter your DNS: " DNS
  done

  echo "BLOBBERS: $BLOBBER"
  echo "ENDPOINT: $URL"
  echo "EMAIL: $EMAIL"
  echo "BLOBCAPACITY: $BLOBCAPACITY"
  echo "DNS: $DNS"
}

backup_previous() {
  if [ -d "blobber_deploy" ]; then
    echo "blobber_deploy folder already exists. So backing up to blobber_deploy_backup-$(date +"%Y_%m_%d_%H_%M_%S")"
    mv blobber_deploy blobber_deploy_backup-$(date +"%Y_%m_%d_%H_%M_%S")
  fi
}

clean_up() {
  pushd blobber_deploy
    rm zwallet zbox bridge.log cmdlog.log config.yaml || true
  popd
}

b_delegate() {
  pushd blobber_deploy
    echo -e "\n \e[93m ===================================== Creating delegate.json. ======================================  \e[39m"
    ./zwallet getbalance --config config.yaml --wallet delegate.json --configDir . --silent
    DELEGATEID=$( jq -r .client_id delegate.json )
    echo $DELEGATEID > ~/cfg/delegate.txt
    echo $DELEGATEID > ~/cfg/blobberdelegate.txt
  popd
}

# Taking inputs from cli
cli_input_deployment

# Backup Previous
if [[ "$1" == "keep" ]] ; then
  echo "KEEPING SAME KEYS"
else
  backup_previous
fi

# Setting up binaries
mkdir -p blobber_deploy
pushd blobber_deploy
  set_binaries_and_config
popd

# Generating keys for blobbers
for n in $(seq 1 $BLOBBER); do
  pushd blobber_deploy
    gen_key $n b $URL $EMAIL
    gen_key $n v $URL $EMAIL
  popd
done

#Creating delegate wallet.json
b_delegate

#Cleanup Binaries
clean_up
