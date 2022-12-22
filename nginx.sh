#!/bin/bash

nginx_setup() {
  echo -e "\n \e[93m ============================================== Installing nginx on the server ===============================================  \e[39m"
  sudo apt update
  sudo apt install nginx -y
  echo -e "\n \e[93m ============================================== Adding proxy pass to nginx config ===============================================  \e[39m"
  #pushd ${HOME}/miner_deploy/
  cat <<\EOF >nginx_default
server {
   server_name subdomain;
   add_header 'Access-Control-Expose-Headers' '*';
   location / {
       # First attempt to serve request as file, then
       # as directory, then fall back to displaying a 404.
       try_files $uri $uri/ =404;
   }
EOF
  for l in $(seq 1 $MINER)
    do
    echo "
    location /miner0${l}/ {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_pass http://localhost:707${l}/;
    }" >> ./nginx_default
    done

  for l in $(seq 1 $SHARDER)
    do
    echo "
    location /sharder0${l}/ {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_pass http://localhost:717${l}/;
    }" >> ./nginx_default
    done

  for l in $(seq 1 $BLOBBER)
    do
    echo "
    location /blobber0${l}/ {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_pass http://localhost:505${l}/;
    }" >> ./nginx_default
    done

  if [[ "$ZDNS" == "y" ]] ; then
    echo "
    location /dns/ {
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_pass http://localhost:9091/;
    }" >> ./nginx_default
  fi
  
  echo "}" >> ./nginx_default
  sed -i "s/subdomain/$DOMAIN/g" "./nginx_default"
  cat ./nginx_default > /etc/nginx/sites-available/default
  rm nginx_default
  #popd
  sudo apt-get install certbot -y
  apt-get install python3-certbot-nginx -y
}

MINER=$(cat ~/cfg/numminers.txt)
SHARDER=$(cat ~/cfg/numsharders.txt)
BLOBBER=$(cat ~/cfg/numblobbers.txt)
ZDNS=$(cat ~/cfg/zdns.txt)
DOMAIN=$(cat ~/cfg/url.txt)
EMAIL=$(cat ~/cfg/email.txt)

nginx_setup

echo -e "\n\n \e[93m Create a record in your dns to map server ip with domain. \e[39m"
echo -e "\n \e[93m Run the following command: \n  sudo certbot --nginx -d $DOMAIN -m $EMAIL --agree-tos -n \e[39m"
