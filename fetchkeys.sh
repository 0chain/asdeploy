#!/bin/bash

source new_config.sh

FILES="./*_keys.json"

pushd keygen

allokay="false"
while [[ "$allokay" == "false" ]]
do  
  clear
  allokay="true"
    for f in $FILES
    do
      CLIENTID=$( jq -r .client_id $f )
      echo $CLIENTID
      if [ ! -f $CLIENTID.res ]
      then
        wget $SASSERVER/s/$CLIENTID -O $CLIENTID.res
        sleep 1
      fi
      res=$(cat $CLIENTID.res)
      
      if [[ "$res" == "" ]]
      then
        echo -e "\n \e[31m INVALID (no response from server) \e[0m"
        rm $CLIENTID.res
        allokay="false"
	  else
        if [[ "$res" == "invalid client_id" ]]
        then
          echo -e "\n \e[31m INVALID (still awaiting magicblock) \e[0m"
          rm $CLIENTID.res
          allokay="false"
	    else
          echo -e "\n \e[32m VALID  \e[0m"
          
          actualsize=$(wc -c <"$CLIENTID.res")
		  if [ $actualsize -lt 1000 ];                    
		  then
			json=$(echo $res | base64 -d)
			TARGETID=$( jq -r .client_id $f )
			if [[ "$CLIENTID" == "$TARGETID" ]]
			then
				echo "Match $CLIENTID"
			else
				echo "\n \e[31m Mismatch $CLIENTID $TARGETID \e[0m"
				allokay="false"
			fi
		  else
			echo "Large $CLIENTID - WholeFile?"
          fi
        fi
      fi
      #sleep 2	  
	done
  if [[ "$allokay" == "false" ]]
  then
    sleep 5	  
  fi
done

echo
echo "RESULTS"
for f in $FILES
do
  CLIENTID=$( jq -r .client_id $f )
  echo $f $CLIENTID
done


echo -e "\n \e[32m ========== EXTRACTING OUTPUT ==============  \e[0m"
mkdir res
mkdir config
for f in $FILES
do
  actualsize=$(wc -c <"$CLIENTID.res")
  if [ $actualsize -gt 1000 ];                    
  then
	echo $f
	CLIENTID=$( jq -r .client_id $f )
    t=${f:4:1}
    if [[ "$t" == "m" ]] ; then
		echo "MINER"
		ENCKEY=$( jq -r .keys[0].private_key $f )
	fi
    if [[ "$t" == "s" ]] ; then
		echo "SHARDER"
		ENCKEY=$( jq -r .client_id $f )
	fi
    echo -n $(cat $CLIENTID.res) > $CLIENTID.x.res
    openssl blowfish -a -A -d -k $ENCKEY -in $CLIENTID.x.res -out ./res/$CLIENTID.zip -iter 2
    echo $CLIENTID
    echo $CLIENTPRIVKEY
    echo "openssl blowfish -a -A -d -k $ENCKEY -in $CLIENTID.res -out ./res/$CLIENTID.zip -iter 2"
  else
	CLIENTID=$( jq -r .client_id $f )
	AUTH=$(cat $CLIENTID.res)
	./zwallet faucet --wallet $f --config config.yaml --methodName pour --input test --tokens 9 --configDir ./ --silent
	./zwallet faucet --wallet $f --config config.yaml --methodName pour --input test --tokens 9 --configDir ./ --silent
	./zbox rp-lock --wallet $f --config config.yaml --tokens 8 --configDir ./ --silent
	./zbox download --wallet $f --config config.yaml --localpath ./res --authticket $AUTH --configDir ./ --silent
  fi
  unzip -oP password res/$CLIENTID.zip -d ./config/
  cp $CLIENTID/nodes.yaml ./config/
done
cp *_keys.txt ./config/

popd


#end
