#!/bin/bash

#checking if you have already added the to DNS & is it resolving or not.
check_dns() {
  URL=$(cat ~/cfg/url.txt)
  ipaddr=$(curl api.ipify.org)
  myip=$(dig +short $URL)
  if [[ "$myip" != "$ipaddr" ]]; then
    echo "\e[31m  $URL IP resolution mistmatch $myip vs $ipaddr. \e[13m"
    exit 1
  else
    echo -e "\e[32m  SUCCESS $URL resolves to $myip.  \e[23m"
  fi
}

# please pass the argument to check_and_install_tools to check & install package or tool.
check_and_install_tools() {
  REQUIRED_PKG=$1
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
  echo -e "\e[37mChecking for $REQUIRED_PKG if it is already installed and running fine. \e[73m"
  if [ "" = "$PKG_OK" ]; then
    echo -e "\e[31m  No $REQUIRED_PKG is found on the server. \e[13m\e[32mSetting up $REQUIRED_PKG. \e[23m"
    sudo apt update &> /dev/null
    sudo apt-get --yes install $REQUIRED_PKG &> /dev/null
  else
    echo -e "\e[32m  $REQUIRED_PKG is already installed on the server/machine.  \e[23m"
  fi
  #checking if $REQUIRED_PKG is running or not.
  if (systemctl is-active --quiet nginx) ; then
    echo -e "\e[32m  $REQUIRED_PKG is running fine. \e[23m \n"
  else
    echo -e "\e[31m  $REQUIRED_PKG is failing to run. Please check and resolve it first. You can connect with team for support too. \e[13m \n"
    exit 1
  fi
}

nginx_setup() {
  echo -e "\n \e[93m ================================================ Checking DNS resolving or not =================================================  \e[39m"
  check_dns
  echo -e "\n \e[93m =============================================== Installing nginx on the server =================================================  \e[39m"
  check_and_install_tools nginx
  echo -e "\n \e[93m ============================================== Adding proxy pass to nginx config ===============================================  \e[39m"
  pushd ${HOME}/blobber_deploy/
  cat <<\EOF >blobber.$DOMAIN
server {
   server_name subdomain;
   add_header 'Access-Control-Expose-Headers' '*';
   location / {
       # First attempt to serve request as file, then
       # as directory, then fall back to displaying a 404.
       try_files $uri $uri/ =404;
   }
EOF
  for l in $(seq 1 $BLOBBER)
    do
    echo "
    location /blobber0${l}/ {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_pass http://localhost:505${l}/;
    }
    location /validator0${l}/ {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_pass http://localhost:506${l}/;
    }" >> ./blobber.$DOMAIN
    done
  
  echo "}" >> ./blobber.$DOMAIN

  cat <<\EOF >>blobber.$DOMAIN
server {
    if ($host = subdomain) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
  server_name subdomain;
    listen 80;
    return 404; # managed by Certbot
}
EOF
  sed -i "s/subdomain/$DOMAIN/g" "./blobber.$DOMAIN"
  sudo mv blobber.$DOMAIN /etc/nginx/sites-available/
  sudo ln -s /etc/nginx/sites-available/blobber.$DOMAIN /etc/nginx/sites-enabled/blobber.$DOMAIN &> /dev/null
  popd
  check_and_install_tools certbot
  check_and_install_tools python3-certbot-nginx
  echo -e "\e[37mAdding SSL to $DOMAIN. \e[73m"
  sudo certbot --nginx -d $DOMAIN -m $EMAIL --agree-tos -n
}

BLOBBER=$(cat ~/cfg/numblobbers.txt)
DOMAIN=$(cat ~/cfg/url.txt)
EMAIL=$(cat ~/cfg/email.txt)

nginx_setup
