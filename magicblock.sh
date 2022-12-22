#!/bin/bash

NETWORK="test"
SASSERVER="http://65.109.30.181:8081"
INCFAUCET="y"
ALLOWMULTI="n"
doenc="y"
doauth="n"

show_hash() {
    sha256sum new_magicblock.sh
}

curl_to_get_authtokens() {
  mkdir -p magicblock
  pushd magicblock
    rm auth_tokens.txt || true
    echo -e "\n \e[93m ===================================== Curl to get the auth tokens. ======================================  \e[39m"
    curl $SASSERVER/ > auth_tokens.txt
  popd
}

set_binaries_and_config() {
  pushd magicblock
  touch blacklist.txt
  echo -e "\n \e[93m ===================================== Creating blockworker config. ======================================  \e[39m"
  echo "---" > saswata.yaml
  NETDOM="0chain.net"
  if [ "$NETWORK" == "potato" ] || [ "$NETWORK" == "bcv1" ] ; then
    NETDOM="devnet-0chain.net"
  elif [ "$NETWORK" == "ex1" ] || [ "$NETWORK" == "as1" ] ; then
    NETDOM="testnet-0chain.net"
  else
    NETDOM="0chain.net"
  fi
  echo "block_worker: https://${NETWORK}.${NETDOM}/dns" >> saswata.yaml
  echo "signature_scheme: bls0chain" >> saswata.yaml
  echo "min_submit: 50" >> saswata.yaml
  echo "min_confirmation: 50" >> saswata.yaml
  echo "confirmation_chain_length: 3" >> saswata.yaml
  echo "max_txn_query: 5" >> saswata.yaml
  echo "query_sleep_time: 5" >> saswata.yaml

  cp saswata.yaml ~/.zcn/saswata.yaml
  
  echo -e "\n \e[93m ===================================== Downloading zwallet & zbox binaries. ======================================  \e[39m"
  wget https://github.com/0chain/zboxcli/releases/download/v1.3.11/zbox-linux.tar.gz
  tar -xvf zbox-linux.tar.gz
  rm zbox-linux.tar.gz
  wget https://github.com/0chain/zwalletcli/releases/download/v1.1.7/zwallet-linux.tar.gz
  tar -xvf zwallet-linux.tar.gz
  rm zwallet-linux.tar.gz
  popd
}

download_files_using_token() {
    pushd magicblock
    echo "Fauceting tokens.."
    i=1 ; while [ $i -le 2 ] ; do  ./zwallet faucet --methodName pour --input test --silent --wallet saswata_wallet.json --config saswata.yaml --tokens 9 ; ((i++)) ; done
    echo "Funding Read Pool.."
    ./zbox rp-lock --tokens 2 --silent --wallet saswata_wallet.json --config saswata.yaml
    
    mkdir -p downloads
    mkdir -p nodes
    mkdir -p processed
    cp /root/.zcn/saswata_wallet.json ./
    rm ./password.yaml
    touch ./password.yaml
    while read token; do
        authdata=$(echo "$token" | base64 --decode)
        client_id=$(echo "$authdata" | jq -r .owner_id)
        authhash=$(echo $token | sha256sum | cut -c 1-64)
        
        if [ -f processed/$authhash.txt ]
        then
            echo -e "\n \e[93m ===================================== Already Downloaded nodes.yaml file of $client_id ======================================  \e[39m"
        else
            client_id=`./zbox download --wallet saswata_wallet.json --config saswata.yaml --localpath ./ --authticket $token --silent | grep "Name = " | tail -1 | cut -d ' ' -f 9`
            client_id=$(echo $client_id | cut -c 1-64)
            #rm -rf ./downloads/$client_id/* || true

            unzip $client_id.zip -d ./nodes

            echo -e "\n \e[93m ===================================== Downloaded nodes.yaml file of $client_id ======================================  \e[39m"
            rm $client_id.zip
            zip -ej $client_id.zip "nodes/$client_id/nodes.yaml" -P password
            mv $client_id.zip nodes
            touch processed/$authhash.txt
            if [ -f nodes/$client_id.zip ] ; then
                echo "$client_id: password" >> ./password.yaml
            else
                echo "INVALID $client_id omitted" # omit invalid
            fi
            sleep 1s
        fi
    done <auth_tokens.txt  
    popd
}

assess_files() {
    pushd magicblock
    pushd nodes
    mkdir -p ../invalid
    nodes=0
    blacklisted=0
    invalids=0
    miners=0
    sharders=0
    invalidlist=""
    blacklistlist=""
    for d in ./* ; do
        if [ -d $d ]
        then
            if [ -f $d/nodes.yaml ]
            then
                ontype="null"
                pubip="null"
                id="null"
                invalid=""
                minercount=0
                shardercount=0
                while read yaml ; do
                    if [ "$yaml" == "miners:" ] ; then
                    ontype="miner"
                    fi
                    if [ "$yaml" == "sharders:" ] ; then
                    ontype="sharder"
                    fi
                    subyaml=${yaml:0:5}
                    if [ "$subyaml" == "- id:" ] ; then
                        id=${yaml:6}
                        if [ "$ontype" == "miner" ] ; then
                            minercount=$(($minercount+1))
                        fi
                        if [ "$ontype" == "sharder" ] ; then
                            shardercount=$(($shardercount+1))
                        fi
                    fi
                    subyaml=${yaml:0:10}
                    #echo $subyaml
                    if [ "$subyaml" == "public_ip:" ] ; then
                        pubip=${yaml:11}
                    fi                
                done <$d/nodes.yaml
                
				if [ "$ALLOWMULTI" == "n" ] ; then
	                if [ $minercount -gt 1 ] ; then
	                    invalid="MULTIPLE MINERS:"
	                fi	
	                if [ $shardercount -gt 1 ] ; then
	                    invalid="MULTIPLE SHARDERS:"
	                fi
                fi
                while read blacklist ; do
                    if [ "$blacklist" == "$pubip" ] ; then
                        invalid="BLACKLISTED URL:"
                    fi
                    if [ "$blacklist" == "$id" ] ; then
                        invalid="BLACKLISTED ID: "
                    fi
                done <../blacklist.txt
                
                if [ "$invalid" == "" ] ; then
                    sharders=$(($sharders+$shardercount))
                    miners=$(($miners+$minercount))
                    nodes=$(($nodes+1))
                    echo -e "$id\t$ontype\t$pubip"
                else
                    blacklisted=$(($blacklisted+1))
                    blacklistlist="$blacklistlist\n$invalid\t$id\t$pubip"
                fi                    

            else
                #echo "INVALID: $d: nodes.yaml missing"
                invalid="yes"
                invalids=$(($invalids+1))
                invalidlist="$invalidlist\n$d nodes.yaml missing"
            fi
            
            if [ ! -z "$invalid" ] ; then            
                mv $d ../invalid
            fi
        fi
    done
    popd
    popd
    echo -e "\n \e[93m ===================================== Invalids ======================================  \e[39m"
    echo -e $invalidlist
    echo -e $blacklistlist
    echo -e "\n \e[93m ===================================== Current Node Set ======================================  \e[39m"
    echo "NODES: $nodes"
    echo "BLACKLISTED: $blacklisted"
    echo "INVALIDS: $invalids"
    echo "MINERS: $miners"
    echo "SHARDERS: $sharders"
}

create_allocation() {
  if [ "$doauth" == "y" ]
  then 
  pushd magicblock
        ./zwallet getbalance --config saswata.yaml --wallet saswata_wallet.json --silent

        databits=2
        paritybits=2
        MB=100

        echo "Fauceting tokens.."
        i=1 ; while [ $i -le 2 ] ; do  ./zwallet faucet --methodName pour --input test --silent --wallet saswata_wallet.json --config saswata.yaml --tokens 9 ; ((i++)) ; done

        echo "Creating Allocation.."
        ./zbox newallocation --size $MB"000000" --lock 5 --data $databits --parity $paritybits --silent --wallet saswata_wallet.json --config saswata.yaml | awk -F": " '{ print $2 }' > ./allocation_res.txt
		#ALLOC=$(cut -c 21-<<< $(cat allocation_res.txt))
		ALLOC=$(cat allocation_res.txt)
		#rm allocation_res.txt
		echo -n $ALLOC > allocation_id.txt
		echo "Allocation: $ALLOC"
		
        echo "Getting Balance.."
        ./zwallet getbalance --silent --wallet saswata_wallet.json --config saswata.yaml
  popd
  fi
}

prepare_files_to_send_back() {
#   NETWORK="beta"
  wallet=saswata_wallet.json
  ALLOC=$(cat magicblock/allocation_id.txt) 
  mkdir -p magicblock/uploads
  pushd magicblock/nodes
  echo "ALLOCATION: " $ALLOC
    FILES="./*.zip"
    valids=""
    fails=""
    for f in $FILES
      do
        f=${f:2}
        clientid=${f::-4}
        echo "Processing $clientid file..."
        mkdir ../uploads/$clientid
        cp ../magicblock_output/output/$clientid.zip ../uploads/$clientid/
        #cat ../../magicblock_output/output/nodes.yaml > ../$clientid/nodes.yaml
        #cat ../../magicblock_output/output/initial-states.yaml > ../$clientid/initial-states.yaml
        #cd ../nodes/$clientid
        #unzip -oP password $f
        #rm $f
        cd ../
        pwd

             #$( jq -r .client_id saswata_wallet.json )
        # mkdir $CLIENT
        # mv nodes.yaml $CLIENT
        #./zbox getwallet --silent --wallet saswata_wallet.json --config saswata.yaml --configDir ./ --json | jq -r .encryption_public_key > sas_encrypt_pub_key.txt
        # mv sas_encrypt_pub_key.txt ./downloads/${f::-4}

        #Creating zip file to share
        #zip -r $clientid.zip ./downloads/$clientid

        #ls
        # echo "Uploading Encrypted File.."
        #clientnodes=$(cat ./nodes/$clientid/nodes.yaml)
        
        AUTH="null"
        if [ "$doenc" == "y" ]
        then
            clientprivkey=$(grep -E "^#1:|private_key: " ./nodes/$clientid/nodes.yaml | cut -c 16-)
            if [ "$clientprivkey" == "\"\"" ] ; then
                clientprivkey="$clientid"
            fi
            echo "PRV: $clientid: $clientprivkey"
            openssl blowfish -a -A -e -iter 2 -k $clientprivkey -in ./uploads/$clientid/$clientid.zip -out ./uploads/$clientid/$clientid.zip.enc
            AUTH=$(cat ./uploads/$clientid/$clientid.zip.enc)
            echo "ENC: $clientid:" $(echo -n $AUTH | sha256sum)
        fi
        
        if [ "$doauth" == "y" ]
        then
            encpubkey=$(cat ./nodes/$clientid/shareauthkey.txt)
            echo "EncPubKey: " $encpubkey

            ./zbox upload --wallet saswata_wallet.json --config saswata.yaml --encrypt --allocation $ALLOC --localpath ./uploads/$clientid/$clientid.zip --remotepath /$clientid.zip --silent 
            #encrypt_0chain_pub_key=$(cat ./downloads/${f::-4}/encrypt_pub_key.txt)
            #id_0chain=$( jq -r .client_id saswata_wallet.json )
            # echo "Generating Share.."
            ./zbox share --wallet saswata_wallet.json --config saswata.yaml --clientid $clientid --encryptionpublickey $encpubkey --allocation $ALLOC --remotepath /$clientid.zip --silent > authticket.txt
            echo ./zbox share --wallet saswata_wallet.json --config saswata.yaml --clientid $clientid --encryptionpublickey $encpubkey --allocation $ALLOC --remotepath /$clientid.zip --silent
            AUTH=$(cut -c 13-<<< $(cat authticket.txt))
            rm authticket.txt
            echo "AUTHTICKET: " $AUTH
        fi
        #./downloads/$clientid

          cat <<EOF >./auth.json
{"client_id":"$clientid", "token":"$AUTH"}
EOF

        res=$(curl -LX POST $SASSERVER/s/upload/ -d @auth.json)
        if [ "$res" == "{\"status\":true}" ] ; then
            echo -e "\n \e[32m VALID - $clientid Your Auth token is shared to $SASSERVER/s/upload/ ======> \e[0m\n"
            valids="$valids\e[32m$clientid\e[0m\n"
        else
            echo -e "\n \e[31m FAIL - $clientid \e[0m"
            fails="$fails\e[31m$clientid\e[0m\n"
        fi
        echo -e "\n"

        # echo "zbox download"
        # ./zbox download --wallet saswata_wallet.json --config saswata.yaml --localpath ./ --authticket $AUTH --configDir . --silent
        #rm $f
        cd nodes
      done
    cd ../
    #rm -rf magicblock_output nodes_zip
  popd
  
  echo -e $valids
  echo -e $fails
}

create_magicblock() {
  pushd magicblock
    mkdir -p magicblock_output
    mkdir -p config/input
    echo -e "\n \e[93m ===================================== Creating magic block. ======================================  \e[39m"
    cat <<EOF >./docker-compose.yaml
version: '3'
services:
  magicblock:
    image: 0chaindev/magic-block:activeset
    environment:
      - DOCKER=true
    volumes:
      - ./config:/config
    command: ./bin/magicBlock --mainnet --config_file nodes
EOF
    cp -rf ./nodes/*.zip ./config/input/
    cat ./password.yaml > ./config/input/password.yaml
    echo "MAGIC BLOCK PROCESS STARTING.."
    docker-compose up -d
    echo "MAGIC BLOCK PROCESS FINISHED.."
    sleep 20s
    cp -rf ./config/output/ ./magicblock_output
  popd
}

patch_initial_states() {
    echo "PATCHNG INITIAL STATES (FAUCET).."
    pushd magicblock
    pushd magicblock_output
    pushd output
      FILES="./*.zip"
      for f in $FILES
      do
        unzip -oP password $f initial-states.yaml
        echo "- id: 6dba10422e368813802877a85039d3985d96760ed844092319743fb3a76712d3" >> initial-states.yaml
        echo "  tokens: 20000000000000000" >> initial-states.yaml
        zip $f initial-states.yaml
        rm initial-states.yaml
      done
    popd
    popd
    popd
}

clean_up() {
  pushd magicblock
    rm -rf zwallet zbox cmdlog.log auth_tokens.txt saswata.yaml password.yaml magic-block allocation_id.txt auth.json bridge.log docker-compose.yaml saswata_wallet.json password.yaml saswata.yaml || true
  popd
}

# Show hash of this file
show_hash

# Get all the uploaded auth tokens
curl_to_get_authtokens

# Setting up binaries
set_binaries_and_config

# Download nodes.yaml files
download_files_using_token

# Assess Files.
assess_files


read -p "Do you want to proceed with magic block creation? (y/n) : " proceed

if [ "$proceed" == "y" ] ; then

    # Create Magicblock & other files
    create_magicblock

    if [ "$INCFAUCET" == "y" ] ; then
        patch_initial_states
    fi
    
    read -p "Do you want to send magicblock and secrets back now? (y/n) : " send

    if [ "$send" == "y" ] ; then

        # Create Allocation
        create_allocation
        #echo -n "cc8287c49e8327417c3b562ff3a9c99aaf05346330ca876eb3d7b82fca3e5ef1" > magicblock/allocation_id.txt

        # Creating nodes.yaml dkg & magicblock block file share it back to client id.
        prepare_files_to_send_back

        # Cleanup 
        #clean_up
    else
        echo "Magic Block sending skipped"
    fi
else
    echo "Magic Block creation process skipped"
fi
