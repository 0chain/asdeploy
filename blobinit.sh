#!/bin/bash

source blobberconfig.sh

get_blobber_repo() {
	git clone https://github.com/0chain/blobber.git -b docker-deploy-fix
}

patch_configs() {
	#DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|--hostname 198.18.0.6\${BLOBBER}|--hosturl https://$DOMAINURL/blobber0\${BLOBBER} --hostname $DOMAINURL|g" ~/blobber/docker.local/b0docker-compose.yml
	#DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|--hostname 198.18.0.9\${BLOBBER}|--hosturl https://$DOMAINURL/blobber0\${BLOBBER} --hostname $DOMAINURL|g" ~/blobber/docker.local/b0docker-compose.yml
	#DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|./bin/blobber|./bin/blobber --hosturl https://$DOMAINURL/blobber0\${BLOBBER}|g" ~/blobber/docker.local/p0docker-compose.yml
	#DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|./bin/validator|./bin/validator --hosturl https://$DOMAINURL/blobber0\${BLOBBER}|g" ~/blobber/docker.local/p0docker-compose.yml
	DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|beta.zus.network|$DOMAINURL|g" ~/blobber/docker.local/p0docker-compose.yml
	DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|<your-domain>|$DOMAINURL|g" ~/blobber/docker.local/p0docker-compose.yml
	DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|--hostname localhost|--hostname $DOMAINURL|g" ~/blobber/docker.local/p0docker-compose.yml
	DNS=$( cat ~/cfg/network.txt ) ; sed -i "s|^block_worker: .*$|block_worker: $DNS|" ~/blobber/config/0chain_blobber.yaml
	DNS=$( cat ~/cfg/network.txt ) ; sed -i "s|^block_worker: .*$|block_worker: $DNS|" ~/blobber/config/0chain_validator.yaml
	DELID=$( cat ~/cfg/blobberdelegate.txt ) ; sed -i "s|^delegate_wallet: .*$|delegate_wallet: '$DELID'|" ~/blobber/config/0chain_blobber.yaml
	DELID=$( cat ~/cfg/blobberdelegate.txt ) ; sed -i "s|^delegate_wallet: .*$|delegate_wallet: '$DELID'|" ~/blobber/config/0chain_validator.yaml
	sed -i "s|rate_limit: 10 |rate_limit: 100 |g" ~/blobber/config/0chain_blobber.yaml
	sed -i "s|price_in_usd: false|price_in_usd: true|g" ~/blobber/config/0chain_blobber.yaml
	CAPACITY=$( cat ~/cfg/blobbercap.txt ) ; if [[ $CAPACITY -lt 1073741824 ]]; then CAPACITY=107374182400 ; fi ; sed -i "s|capacity: 1073741824 #|capacity: $CAPACITY #|g" ~/blobber/config/0chain_blobber.yaml
	NUMBLOBBERS=$( cat ~/cfg/numblobbers.txt )
	for (( b = 1 ; b <= NUMBLOBBERS ; b++ )) ; do 
		echo "Blobber $b" ; cp ~/blob/b0bnode"$b"_keys.txt ~/blobber/docker.local/keys_config/b0bnode"$b"_keys.txt
		echo "Validator $b" ; cp ~/blob/b0vnode"$b"_keys.txt ~/blobber/docker.local/keys_config/b0vnode"$b"_keys.txt
	done
}


get_blobber_repo

patch_configs


# Generating keys for blobbers
#for n in $(seq 1 $BLOBBER); do
#  b_key $n b $URL $EMAIL
#done
