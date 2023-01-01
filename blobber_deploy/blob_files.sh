#!/bin/bash

source ~/blob_config.sh
source ./blob_config.sh

get_blobber_repo() {
  # Creating directory structure for blobber deployment
  echo -e "\n \e[93m ===================================== Creating directory structure for blobber deployment. ======================================  \e[39m"

  mkdir -p ~/blobber_deploy/docker.local/bin/ ~/blobber_deploy/docker.local/keys_config/ ~/blobber_deploy/config/ ~/blobber_deploy/
  echo -e "\e[32mDirectory structure for blobber deployment is successfully created."

  pushd ~/blobber_deploy/

    # Install yaml query
    echo -e "\n \e[93m ===================================== Installing yq binaries. ======================================  \e[39m"
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod a+x /usr/local/bin/yq
    yq --version

    # create Cleanup script for blobbers & validators
    echo -e "\n \e[93m ===================================== Creating cleanup script file for blobbers & validators. ======================================  \e[39m"
    rm -rf ~/blobber_deploy/docker.local/bin/*
    wget_cleanup_script="$(wget https://raw.githubusercontent.com/0chain/blobber/staging/docker.local/bin/clean.sh -O ~/blobber_deploy/docker.local/bin/clean.sh 2>&1 | grep "HTTP" | awk '{print $6}')"
    if [[ $wget_cleanup_script == 200 ]]; then
      echo -e "\e[32m  clean.sh script file is successfully downloaded. \e[23m"
    else
      echo -e "\e[31m  Downloading clean.sh script failed. \e[13m"
      exit 1
    fi
    sudo chmod +x ~/blobber_deploy/docker.local/bin/clean.sh

    # create Init script for blobbers & validators
    echo -e "\n \e[93m ===================================== Creating Blobber Init script file for blobbers & validators. ======================================  \e[39m"
    wget_init_setup_script="$(wget https://raw.githubusercontent.com/0chain/blobber/staging/docker.local/bin/blobber.init.setup.sh -O ~/blobber_deploy/docker.local/bin/blobber.init.setup.sh 2>&1 | grep "HTTP" | awk '{print $6}')"
    if [[ $wget_init_setup_script == 200 ]]; then
      echo -e "\e[32m  blobber.init.setup.sh file is successfully downloaded. \e[23m"
    else
      echo -e "\e[31m  Downloading blobber.init.setup.sh failed. \e[13m"
      exit 1
    fi
    sudo chmod +x ~/blobber_deploy/docker.local/bin/blobber.init.setup.sh

    # create postgres entrypoint script for blobbers postgres
    echo -e "\n \e[93m ===================================== Creating postgres entrypoint script for blobbers postgres. ======================================  \e[39m"
    rm -rf ~/blobber_deploy/bin/*
    wget_pg_entry_script="$(wget https://raw.githubusercontent.com/0chain/blobber/staging/bin/postgres-entrypoint.sh -O ~/blobber_deploy/bin/postgres-entrypoint.sh 2>&1 | grep "HTTP" | awk '{print $6}')"
    if [[ $wget_pg_entry_script == 200 ]]; then
      echo -e "\e[32m  postgres-entrypoint.sh file is successfully downloaded. \e[23m"
    else
      echo -e "\e[31m  Downloading postgres-entrypoint.sh failed. \e[13m"
      exit 1
    fi
    sudo chmod +x ~/blobber_deploy/bin/postgres-entrypoint.sh

    # create 0chain_blobber.yaml file
    echo -e "\n \e[93m ===================================== Creating 0chain_blobber.yaml config file. ======================================  \e[39m"
    rm -rf ~/blobber_deploy/config/*
    wget_blobber_yaml="$(wget https://raw.githubusercontent.com/0chain/blobber/staging/config/0chain_blobber.yaml -O ~/blobber_deploy/config/0chain_blobber.yaml 2>&1 | grep "HTTP" | awk '{print $6}')"
    if [[ $wget_blobber_yaml == 200 ]]; then
      echo -e "\e[32m  0chain_blobber.yaml file is successfully downloaded. \e[23m"
    else
      echo -e "\e[31m  Downloading 0chain_blobber.yaml failed. \e[13m"
      exit 1
    fi

    # create sc.yaml file
    echo -e "\n \e[93m ===================================== Creating 0chain_validator.yaml config file. ======================================  \e[39m"
    wget_validator_yaml="$(wget https://raw.githubusercontent.com/0chain/blobber/staging/config/0chain_validator.yaml -O ~/blobber_deploy/config/0chain_validator.yaml 2>&1 | grep "HTTP" | awk '{print $6}')"
    if [[ $wget_validator_yaml == 200 ]]; then
      echo -e "\e[32m  0chain_validator.yaml file is successfully downloaded. \e[23m"
    else
      echo -e "\e[31m  Downloading 0chain_validator.yaml failed. \e[13m"
      exit 1
    fi

    # create postgresql.conf file
    echo -e "\n \e[93m ===================================== Creating postgresql.conf config file. ======================================  \e[39m"
    wget_pg_conf="$(wget https://raw.githubusercontent.com/0chain/blobber/staging/config/postgresql.conf -O ~/blobber_deploy/config/postgresql.conf 2>&1 | grep "HTTP" | awk '{print $6}')"
    if [[ $wget_pg_conf == 200 ]]; then
      echo -e "\e[32m  postgresql.conf file is successfully downloaded. \e[23m"
    else
      echo -e "\e[31m  Downloading postgresql.conf failed. \e[13m"
      exit 1
    fi

    # create docker-compose file for blobber & validator
    echo -e "\n \e[93m ===================================== Creating docker-compose file for blobber & validator. ======================================  \e[39m"
    rm -rf ~/blobber_deploy/docker.local/p0docker-compose.*
    wget_docker_compose="$(wget https://raw.githubusercontent.com/0chain/blobber/staging/docker.local/p0docker-compose.yml -O ~/blobber_deploy/docker.local/p0docker-compose.yml 2>&1 | grep "HTTP" | awk '{print $6}')"
    if [[ $wget_docker_compose == 200 ]]; then
      echo -e "\e[32m  p0docker-compose.yml file is successfully downloaded. \e[23m"
    else
      echo -e "\e[31m  Downloading p0docker-compose.yml failed. \e[13m"
      exit 1
    fi

    # create start script for blobber & validator.
    echo -e "\n \e[93m ===================================== Creating start script file for blobber & validator. ======================================  \e[39m"
    wget_docker_compose="$(wget https://raw.githubusercontent.com/0chain/blobber/staging/docker.local/bin/p0blobber.start.sh -O ~/blobber_deploy/docker.local/bin/p0blobber.start.sh 2>&1 | grep "HTTP" | awk '{print $6}')"
    if [[ $wget_docker_compose == 200 ]]; then
      echo -e "\e[32m  p0blobber.start.sh file is successfully downloaded. \e[23m"
    else
      echo -e "\e[31m  Downloading p0blobber.start.sh failed. \e[13m"
      exit 1
    fi
    sudo chmod +x ~/blobber_deploy/docker.local/bin/p0blobber.start.sh

    # create setup network for sharder
    echo -e "\n \e[93m ===================================== Creating network setup script file for sharder. ======================================  \e[39m"
    docker network create --driver=bridge --subnet=198.18.0.0/15 --gateway=198.18.0.255 testnet0 || true
    echo -e "\e[32m  network setup file is successfully created."

  popd

}

patch_configs() {
  pushd ~/blobber_deploy/
    #DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|--hostname 198.18.0.6\${BLOBBER}|--hosturl https://$DOMAINURL/blobber0\${BLOBBER} --hostname $DOMAINURL|g" ~/blobber/docker.local/b0docker-compose.yml
    #DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|--hostname 198.18.0.9\${BLOBBER}|--hosturl https://$DOMAINURL/blobber0\${BLOBBER} --hostname $DOMAINURL|g" ~/blobber/docker.local/b0docker-compose.yml
    #DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|./bin/blobber|./bin/blobber --hosturl https://$DOMAINURL/blobber0\${BLOBBER}|g" ~/blobber/docker.local/p0docker-compose.yml
    #DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|./bin/validator|./bin/validator --hosturl https://$DOMAINURL/blobber0\${BLOBBER}|g" ~/blobber/docker.local/p0docker-compose.yml
    DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|beta.zus.network|$DOMAINURL|g" ./docker.local/p0docker-compose.yml
    DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|<your-domain>|$DOMAINURL|g" ./docker.local/p0docker-compose.yml
    DOMAINURL=$( cat ~/cfg/url.txt ) ; sed -i "s|--hostname localhost|--hostname $DOMAINURL|g" ./docker.local/p0docker-compose.yml
    DNS=$( cat ~/cfg/network.txt ) ; sed -i "s|^block_worker: .*$|block_worker: $DNS|" ./config/0chain_blobber.yaml
    DNS=$( cat ~/cfg/network.txt ) ; sed -i "s|^block_worker: .*$|block_worker: $DNS|" ./config/0chain_validator.yaml
    DELID=$( cat ~/cfg/blobberdelegate.txt ) ; sed -i "s|^delegate_wallet: .*$|delegate_wallet: '$DELID'|" ./config/0chain_blobber.yaml
    DELID=$( cat ~/cfg/blobberdelegate.txt ) ; sed -i "s|^delegate_wallet: .*$|delegate_wallet: '$DELID'|" ./config/0chain_validator.yaml
    sed -i "s|rate_limit: 10 |rate_limit: 100 |g" ./config/0chain_blobber.yaml
    sed -i "s|price_in_usd: false|price_in_usd: true|g" ./config/0chain_blobber.yaml
    CAPACITY=$( cat ~/cfg/blobbercap.txt ) ; if [[ $CAPACITY -lt 1073741824 ]]; then CAPACITY=107374182400 ; fi ; sed -i "s|capacity: 1073741824 #|capacity: $CAPACITY #|g" ./config/0chain_blobber.yaml
    NUMBLOBBERS=$( cat ~/cfg/numblobbers.txt )
    for (( b = 1 ; b <= NUMBLOBBERS ; b++ )) ; do 
      echo "Blobber $b" ; cp ~/blobber_deploy/b0bnode"$b"_keys.txt ~/blobber_deploy/docker.local/keys_config/b0bnode"$b"_keys.txt
      echo "Validator $b" ; cp ~/blobber_deploy/b0vnode"$b"_keys.txt ~/blobber_deploy/docker.local/keys_config/b0vnode"$b"_keys.txt
    done
	popd
}


get_blobber_repo

patch_configs


# Generating keys for blobbers
#for n in $(seq 1 $BLOBBER); do
#  b_key $n b $URL $EMAIL
#done
