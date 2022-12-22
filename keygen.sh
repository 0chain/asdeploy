#!/bin/bash

source new_config.sh

cli_input_deployment() {
  echo -e "\n Please input the following: \n"
  if [[ -f cfg/numsharders.txt ]]
  then
    SHARDER=$(cat cfg/numsharders.txt)
  fi
  while [[ -z $SHARDER ]]
  do
    read -p "Enter the number of Sharders: " SHARDER
  done

  if [[ -f cfg/numminers.txt ]]
  then
    MINER=$(cat cfg/numminers.txt)
  fi
  while [[ -z $MINER ]]
  do
    read -p "Enter the number of Miners: " MINER
  done

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

  echo "SHARDERS: $SHARDER"
  echo "MINERS: $MINER"
  echo "ENDPOINT: $URL"
  echo "EMAIL: $EMAIL"
}

# SHARDER=2
# MINER=3
# NETWORK=beta
# WALLET=shah
# PUBLIC_ENDPOINT=beta.0chain.net
# EMAIL=alishahnawaz17@gmail.com

backup_previous() {
  if [ -d "keygen" ]; then
    echo "Keygen folder already exists. So backing up to keygen_backup-$(date +"%Y_%m_%d_%H_%M_%S")"
    mv keygen keygen_backup-$(date +"%Y_%m_%d_%H_%M_%S")
  fi
}

set_binaries_and_config() {
  mkdir -p keygen
  pushd keygen
  rm nodes.yaml || true
  echo -e "\n \e[93m ===================================== Creating blockworker config. ======================================  \e[39m"
  echo "---" > config.yaml
  if [ "$NETWORK" == "potato" ] || [ "$NETWORK" == "bcv1" ] ; then
    NETDOM="devnet-0chain.net"
  elif [ "$NETWORK" == "ex1" ] || [ "$NETWORK" == "as1" ] ; then
    NETDOM="testnet-0chain.net"
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
  pushd keygen
    rm zwallet zbox bridge.log cmdlog.log allocation_id.txt config.yaml auth.json || true
  popd
}

ms_key() {
  pushd keygen
  
  echo -e "\n \e[93m ===================================== Creating wallet to generate key b0$2node$1_keys.json. ======================================  \e[39m"
  ./zwallet getbalance --config config.yaml --wallet b0$2node$1_keys.json --configDir . --silent
  PUBLICKEY=$( jq -r '.keys | .[] | .public_key' b0$2node$1_keys.json )
  PRIVATEKEY=$( jq -r '.keys | .[] | .private_key' b0$2node$1_keys.json )
  CLIENTID=$( jq -r .client_id b0$2node$1_keys.json )
  echo $PUBLICKEY > b0$2node$1_keys.txt
  echo $PRIVATEKEY >> b0$2node$1_keys.txt
  echo $3 >> b0$2node$1_keys.txt
  echo $3 >> b0$2node$1_keys.txt
  if [[ $2 == "m" ]] && [[ $1 -gt 0 ]]; then
    echo 707$1 >> b0$2node$1_keys.txt
  elif [[ $2 == "s" ]] && [[ $1 -gt 0 ]]; then
    echo 717$1 >> b0$2node$1_keys.txt
  else
   echo ""
  fi
  popd
}

add_nodes() {
  pushd keygen
  if [[ $2 == "m" ]] && [[ $1 -gt 0 ]]; then
    cat <<EOF >>./nodes.yaml
miners:
EOF
  elif [[ $2 == "s" ]] && [[ $1 -gt 0 ]]; then
    cat <<EOF >>./nodes.yaml
sharders:
EOF
  else
   echo ""
  fi
for i in $(seq 1 $1); do
  PUBLICKEY=$( jq -r '.keys | .[] | .public_key' b0$2node${i}_keys.json )
  PRIVATEKEY=$( jq -r '.keys | .[] | .private_key' b0$2node${i}_keys.json )
  CLIENTID=$( jq -r .client_id b0$2node${i}_keys.json )
  rm b0$2node${i}_keys.json
  if [[ $2 == "m" ]]; then
    cat <<EOF >>./nodes.yaml
- id: $CLIENTID
  public_key: $PUBLICKEY
  private_key: $PRIVATEKEY
  n2n_ip: $3
  public_ip: $3
  port: 707${i}
  path: miner0${i}
  description: $4
  set_index: $(($i - 1))
EOF
  elif [[ $2 == "s" ]]; then
    cat <<EOF >>./nodes.yaml
- id: $CLIENTID
  public_key: $PUBLICKEY
  private_key: ""
  n2n_ip: $3
  public_ip: $3
  port: 717${i}
  path: sharder0${i}
  description: $4
EOF
  else 
    echo ""
  fi
  done
  popd
}

add_node() {
  pushd keygen
    #rm nodes.yaml
    
    PUBLICKEY=$( jq -r '.keys | .[] | .public_key' b0$2node$1_keys.json )
    PRIVATEKEY=$( jq -r '.keys | .[] | .private_key' b0$2node$1_keys.json )
    CLIENTID=$( jq -r .client_id b0$2node$1_keys.json )
    mkdir $CLIENTID
    pushd $CLIENTID 

  if [[ $2 == "m" ]] && [[ $1 -gt 0 ]]; then
    cat <<EOF >>./nodes.yaml
miners:
EOF
  elif [[ $2 == "s" ]] && [[ $1 -gt 0 ]]; then
    cat <<EOF >>./nodes.yaml
sharders:
EOF
  else
   echo ""
  fi
#for i in $(seq 1 $1); do
  #rm b0$2node$1_keys.json
  if [[ $2 == "m" ]]; then
    cat <<EOF >>./nodes.yaml
- id: $CLIENTID
  public_key: $PUBLICKEY
  private_key: $PRIVATEKEY
  n2n_ip: $3
  public_ip: $3
  port: 707$1
  path: miner0$1
  description: $4
  set_index: $(($1 - 1))
EOF
  elif [[ $2 == "s" ]]; then
    cat <<EOF >>./nodes.yaml
- id: $CLIENTID
  public_key: $PUBLICKEY
  private_key: ""
  n2n_ip: $3
  public_ip: $3
  port: 717$1
  path: sharder0$1
  description: $4
EOF
  else 
    echo ""
  fi
  #done
    popd
  popd
}


end_nodes() {
  pushd keygen
    cat <<EOF >>./nodes.yaml
message: "Straight from development"
magic_block_number: 1
starting_round: 0
t_percent: 66
k_percent: 75
EOF
  popd
}

end_node() {
  pushd keygen
    CLIENTID=$( jq -r .client_id b0$2node$1_keys.json )
    pushd $CLIENTID 
    cat <<EOF >>./nodes.yaml
message: "Straight from development"
magic_block_number: 1
starting_round: 0
t_percent: 66
k_percent: 75
EOF
    popd
  popd
}

share_node_file() {
	
	network=$3
	saswalletid=$4
	sasencpubkey=$5
	pushd keygen

	echo -e "\n \e[93m ===================================== Creating wallet to generate key ${1}_network.json. ======================================  \e[39m"
	./zwallet getbalance --config config.yaml --wallet b0$2node$1_keys.json --configDir ./ --silent

    CLIENTID=$( jq -r .client_id b0$2node$1_keys.json )

	databits=2
	paritybits=2
	MB=10

	echo "Fauceting tokens.."
	i=1 ; while [ $i -le 2 ] ; do  ./zwallet faucet --methodName pour --input test --silent --wallet b0$2node$1_keys.json --config config.yaml --configDir ./ --tokens 9 ; ((i++)) ; done

	echo "Creating Allocation.."
	./zbox newallocation --size $MB"000000" --lock 5 --data $databits --parity $paritybits --silent --wallet b0$2node$1_keys.json --config config.yaml --configDir ./ > allocation_res.txt
	ALLOC=$(cut -c 21-<<< $(cat allocation_res.txt))
    echo -n $ALLOC > "$CLIENTID"_allocation.txt
    rm allocation_res.txt

	echo "Creating Read Pools.."
	./zbox rp-lock --tokens 2 --silent --wallet b0$2node$1_keys.json --config config.yaml --configDir ./

	echo "Getting Balance.."
	./zwallet getbalance --silent --wallet b0$2node$1_keys.json --config config.yaml --configDir ./

  #mkdir $CLIENT
  #mv nodes.yaml $CLIENT
  ./zbox getwallet --silent --wallet b0$2node$1_keys.json --config config.yaml --configDir ./ --json > getwallet.json
  SHAREAUTHKEY=$(jq -r .encryption_public_key getwallet.json)
  echo -n $SHAREAUTHKEY > $CLIENTID/shareauthkey.txt

  #Creating zip file to share
  zip -r $CLIENTID.zip $CLIENTID/*

	# echo "Uploading Encrypted File.."
	./zbox upload --wallet b0$2node$1_keys.json --config config.yaml --encrypt --allocation $ALLOC --localpath ./$CLIENTID.zip --remotepath /$CLIENTID.zip --configDir ./ --silent 
    
	# echo "Generating Share.."
	#ALLOC=$(cat "$CLIENTID"_allocation.txt)
	echo "ALLOC: "$ALLOC
	./zbox share --wallet b0$2node$1_keys.json --config config.yaml --clientid $saswalletid --encryptionpublickey $sasencpubkey --allocation $ALLOC --remotepath /$CLIENTID.zip --configDir ./ --silent > auth_res.txt
	AUTH=$(cut -c 13-<<< $(cat auth_res.txt))
	echo "AUTH: "$AUTH
	echo -n $AUTH > "$CLIENTID"_authticket.txt
	rm auth_res.txt

    cat <<EOF >./auth.json
{"client_id":"$CLIENTID", "token":"$AUTH"}
EOF
	mv auth.json $CLIENTID_auth.json

	echo -e "\n Your Auth token is shared to http://65.109.30.181:8080/upload/ ======> \n"
  curl -LX POST $SASSERVER/upload/ -d @$CLIENTID_auth.json
  echo -e "\n"

  # echo "zbox download"
  # ./zbox download --wallet saswata_wallet.json --config config.yaml --localpath ./ --authticket $AUTH --configDir . --silent
	popd
}



# Taking inputs from cli
cli_input_deployment

# Backup Previous
backup_previous

# Setting up binaries
set_binaries_and_config

# SPLIT OUT FOLLOWING FUNCTIONALITY TO sharekeys script

# Generating keys for miners
for n in $(seq 1 $MINER); do
  ms_key $n m $URL $EMAIL
  add_node $n m $URL $EMAIL
  end_node $n m
#  share_node_file $n m $NETWORK $SASWALLETID $SASENCPUBKEY
done

# Generating keys for sharders
for n in $(seq 1 $SHARDER); do
  ms_key $n s $URL $EMAIL
  add_node $n s $URL $EMAIL
  end_node $n s
#  share_node_file $n s $NETWORK $SASWALLETID $SASENCPUBKEY
done

#Generating nodes.yaml
#echo -e "\n \e[93m ================================================= Creating Nodes.yaml. =================================================  \e[39m"
#add_nodes $MINER m $PUBLIC_ENDPOINT $EMAIL
#add_nodes $SHARDER s $PUBLIC_ENDPOINT $EMAIL
#end_nodes

# Sharing Nodes.yaml via proxy-reecncryption
#echo -e "\n \e[93m ================================================= Sharing Nodes.yaml via proxy re-encryption. =================================================  \e[39m"
#share_node_file $NETWORK $WALLET $ID_0CHAIN $ENCRYPT_0CHAIN_PUB_KEY

#Cleaning up intermediate files
#clean_up
