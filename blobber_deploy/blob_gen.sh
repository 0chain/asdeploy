#!/bin/bash

source blobberconfig.sh

cli_input_deployment() {
  echo -e "\n Please input the following: \n"
  if [[ -f cfg/numblobbers.txt ]]
  then
    BLOBBER=$(cat cfg/numblobbers.txt)
  fi

  if [[ -f cfg/url.txt ]]
  then
    URL=$(cat cfg/url.txt)
  fi
  while [[ -z $URL ]]
  do
    read -p "Enter the URL or your domain name. Example: john.mydomain.com : " URL
  done

  if [[ -f cfg/email.txt ]]
  then
    EMAIL=$(cat cfg/email.txt)
  fi
  while [[ -z $EMAIL ]]
  do
    read -p "Enter your EMAIL ID: " EMAIL
  done

  if [[ -f cfg/blobbercap.txt ]]
  then
    BLOBCAPACITY=$(cat cfg/blobbercap.txt)
  fi
  while [[ -z $BLOBCAPACITY ]]
  do
    read -p "Enter your BLOBBERCAPACITY. Example (1TB): 1073741824 (1TB) : " BLOBCAPACITY
  done

  if [[ -f cfg/dns.txt ]]
  then
    DNS=$(cat cfg/dns.txt)
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
  if [ -d "blob" ]; then
    echo "Blob folder already exists. So backing up to blob_backup-$(date +"%Y_%m_%d_%H_%M_%S")"
    mv blob blob_backup-$(date +"%Y_%m_%d_%H_%M_%S")
  fi
}

set_binaries_and_config() {
  mkdir -p blob
  pushd blob
  echo -e "\n \e[93m ===================================== Creating blockworker config. ======================================  \e[39m"
  echo "---" > config.yaml
  if [ "$NETWORK" == "potato" ] || [ "$NETWORK" == "bcv1" ] ; then
    NETDOM="devnet-0chain.net"
  elif [ "$NETWORK" == "ex1" ] || [ "$NETWORK" == "as1" ] ; then
    NETDOM="testnet-0chain.net"
  elif [ "$NETWORK" == "x" ] ; then
    NETDOM="zcntest.net"
  elif [ "$NETWORK" == "beta" ] ; then
    NETDOM="zus.network"
  else
    NETDOM="0chain.net"
  fi  
  echo "block_worker: https://${NETWORK}.${NETDOM}/dns" >> config.yaml
  echo "signature_scheme: bls0chain" >> config.yaml
  echo "min_submit: 50" >> config.yaml
  echo "min_confirmation: 50" >> config.yaml
  echo "confirmation_chain_length: 3" >> config.yaml
  echo "max_txn_query: 5" >> config.yaml
  echo "query_sleep_time: 5" >> config.yaml

  echo -e "\n \e[93m ===================================== Downloading zwallet & zbox binaries. ======================================  \e[39m"
  wget https://github.com/0chain/zboxcli/releases/download/v1.3.11/zbox-linux.tar.gz
  tar -xvf zbox-linux.tar.gz
  rm zbox-linux.tar.gz
  wget https://github.com/0chain/zwalletcli/releases/download/v1.1.7/zwallet-linux.tar.gz
  tar -xvf zwallet-linux.tar.gz
  rm zwallet-linux.tar.gz
  popd
}

clean_up() {
  pushd blob
    rm zwallet zbox bridge.log cmdlog.log allocation_id.txt config.yaml auth.json || true
  popd
}

b_key() {
  pushd blob
  
  echo -e "\n \e[93m ===================================== Creating wallet to generate key b0$2node$1_keys.json. ======================================  \e[39m"
  ./zwallet getbalance --config config.yaml --wallet b0$2node$1_keys.json --configDir . --silent
  PUBLICKEY=$( jq -r '.keys | .[] | .public_key' b0$2node$1_keys.json )
  PRIVATEKEY=$( jq -r '.keys | .[] | .private_key' b0$2node$1_keys.json )
  CLIENTID=$( jq -r .client_id b0$2node$1_keys.json )
  echo $PUBLICKEY > b0$2node$1_keys.txt
  echo $PRIVATEKEY >> b0$2node$1_keys.txt
  echo $3 >> b0$2node$1_keys.txt
  echo $3 >> b0$2node$1_keys.txt
  if [[ $2 == "b" ]] && [[ $1 -gt 0 ]]; then
    echo 505$1 >> b0$2node$1_keys.txt
  else
   echo ""
  fi
  popd
}


b_delegate() {
  pushd blob
  
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
set_binaries_and_config

# Generating keys for blobbers
for n in $(seq 1 $BLOBBER); do
  b_key $n b $URL $EMAIL
  b_key $n v $URL $EMAIL
done

b_delegate
