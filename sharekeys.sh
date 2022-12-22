#!/bin/bash

source new_config.sh

get_deployment() {
    SHARDER=$(cat cfg/numsharders.txt)
    MINER=$(cat cfg/numminers.txt)
    URL=$(cat cfg/url.txt)
    EMAIL=$(cat cfg/email.txt)
	echo "SHARDERS: $SHARDER"
	echo "MINERS: $MINER"
	echo "ENDPOINT: $URL"
	echo "EMAIL: $EMAIL"
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

	echo -e "\n Your Auth token is shared to $SASSERVER/upload/ ======> \n"
  curl -LX POST $SASSERVER/upload/ -d @$CLIENTID_auth.json
  echo -e "\n"

  # echo "zbox download"
  # ./zbox download --wallet saswata_wallet.json --config config.yaml --localpath ./ --authticket $AUTH --configDir . --silent
	popd
}



# Taking inputs from cli
get_deployment

# Generating keys for miners
for n in $(seq 1 $MINER); do
#  ms_key $n m $URL $EMAIL
#  add_node $n m $URL $EMAIL
#  end_node $n m
  share_node_file $n m $NETWORK $SASWALLETID $SASENCPUBKEY
done

# Generating keys for sharders
for n in $(seq 1 $SHARDER); do
#  ms_key $n s $URL $EMAIL
#  add_node $n s $URL $EMAIL
#  end_node $n s
  share_node_file $n s $NETWORK $SASWALLETID $SASENCPUBKEY
done
