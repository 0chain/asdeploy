#!/bin/bash

source config.sh
pushd blob
echo "Fauceting tokens.."

NUMBLOBBERS=$( cat ~/cfg/numblobbers.txt )

for (( b = 1 ; b <= NUMBLOBBERS ; b++ )) ; do 
	i=1 ; while [ $i -le 3 ] ; do  ./zwallet faucet --methodName pour --input test --silent --wallet delegate.json --config config.yaml --configDir ./ --tokens 9 ; ((i++)) ; done
	CLIENTID=$( jq -r .client_id b0bnode"$b"_keys.json )
	./zwallet getbalance --wallet delegate.json --config config.yaml --configDir ./
	echo "Delegating Tokens to $CLIENTID.."
	./zbox sp-lock --blobber_id $CLIENTID --tokens 16 --fee 0 --wallet delegate.json --config config.yaml --configDir ./ 
done
popd
