#checking if you have already added the to DNS & is it resolving or not.
check_dns() {
  echo -e "\n\e[37mChecking if you have already added the ip to DNS & is it resolving or not. \e[73m"
  URL=$(cat ~/cfg/url.txt)
  ipaddr=$(curl api.ipify.org)
  myip=$(dig +short $URL)
  if [[ "$myip" != "$ipaddr" ]]; then
    echo -e "\e[31m  $URL IP resolution mismatch $myip vs $ipaddr. \e[13m \n"
    exit 1
  else
    echo -e "\e[32m  SUCCESS $URL resolves to $myip.  \e[23m \n"
  fi
}

#please pass the argument to check_and_install_tools to check & install package or tool.
install_tools_utilities() {
  REQUIRED_PKG=$1
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
  echo -e "\e[37mChecking for $REQUIRED_PKG if it is already installed. \e[73m"
  if [ "" = "$PKG_OK" ]; then
    echo -e "\e[31m  No $REQUIRED_PKG is found on the server. \e[13m\e[32m$REQUIRED_PKG installed. \e[23m \n"
    sudo apt update &> /dev/null
    sudo apt --yes install $REQUIRED_PKG &> /dev/null
  else
    echo -e "\e[32m  $REQUIRED_PKG is already installed on the server/machine.  \e[23m \n"
  fi
}

#checking if $REQUIRED_PKG is running or not.
status_tools_utilities() {
  REQUIRED_PKG=$1
  if (systemctl is-active --quiet $REQUIRED_PKG) ; then
    echo -e "\e[32m  $REQUIRED_PKG is running fine. \e[23m \n"
  else
    echo -e "\e[31m  $REQUIRED_PKG is failing to run. Please check and resolve it first. You can connect with team for support too. \e[13m \n"
    exit 1
  fi
}

#To generate keys for blobber and validators.
gen_key() {
    echo -e "\n \e[93m ===================================== Creating wallet to generate key b0$2node$1_keys.json. ======================================  \e[39m"
    ./zwallet getbalance --config config.yaml --wallet b0$2node$1_keys.json --configDir . --silent
    PUBLICKEY=$( jq -r '.keys | .[] | .public_key' b0$2node$1_keys.json )
    PRIVATEKEY=$( jq -r '.keys | .[] | .private_key' b0$2node$1_keys.json )
    CLIENTID=$( jq -r .client_id b0$2node$1_keys.json )
    echo $PUBLICKEY > b0$2node$1_keys.txt
    echo $PRIVATEKEY >> b0$2node$1_keys.txt
    if [[ $2 == "b" ]] && [[ $1 -gt 0 ]]; then
      echo $3 >> b0$2node$1_keys.txt
      echo 505$1 >> b0$2node$1_keys.txt
    elif [[ $2 == "v" ]] && [[ $1 -gt 0 ]]; then
      echo $3 >> b0$2node$1_keys.txt
      echo 506$1 >> b0$2node$1_keys.txt
    fi
}

#To generate binaries of zwalletcli and zboxcli
set_binaries_and_config() {
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
}

append_logs() {
  local text=$1
  script_index=${script_index:-0}
  if [[ -z "$2" || "$2" != "skip_count" ]]; then
    echo "$script_index.$step_count) $text " $(date +"%Y-%m-%d %H:%M:%S") >>$log_path
    ((step_count++))
  else
    echo "$text " $(date +"%Y-%m-%d %H:%M:%S") >>$log_path
  fi
}
