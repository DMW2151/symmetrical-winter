#!/bin/sh 

sudo apt update &&\
sudo apt install -y \
    nginx \
    docker \
    docker.io 

docker volume create --driver local nginx_volume

sudo mkdir -p /etc/nginx/ &&\
sudo touch /etc/nginx/nginx.conf &&\
sudo chown ubuntu /etc/nginx/nginx.conf

sudo cat <<EOF > /etc/nginx/nginx.conf
server {
  listen 80;
  server_name _;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl default_server;
  server_name _;
  client_max_body_size 50M;

  ssl_certificate /config/keys/letsencrypt/fullchain.pem;
  ssl_certificate_key /config/keys/letsencrypt/privkey.pem;
  ssl_dhparam /config/nginx/dhparams.pem;
  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
  ssl_prefer_server_ciphers on;

  location / {
      proxy_pass http://localhost:8000;

      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header Host \$host;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-NginX-Proxy true;
  }

  location ~* /(user/[^/]*)/(api/kernels/[^/]+/channels|terminals/websocket)/? {
      proxy_pass http://localhost:8000;

      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header Host \$host;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

      proxy_set_header X-NginX-Proxy true;

      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_read_timeout 86400;
  }
}
EOF

sudo docker run \
  --name nginx \
  --network host \
  --mount type=bind,src=/etc/nginx/nginx.conf,dst=/config/nginx/site-confs/default \
  --cap-add=NET_ADMIN \
  -e EMAIL=dmw2151@columbia.edu \
  -e URL=notebooks.maphub.dev \
  -v nginx_volume:/config \
  --detach=true \
  linuxserver/letsencrypt