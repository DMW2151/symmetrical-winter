#
# Cookbook:: jupyter
# Recipe:: Hub Master Install Nginx
#
# Copyright:: 2021, The Authors, All Rights Reserved.

# Create Mount Directories...
directory '/etc/nginx/' do
    owner 'ubuntu'
    group 'ubuntu'
    mode '0755'
    action :create
end

file '/etc/nginx/nginx.conf' do
    content <<-EOF.gsub(/^\s+/, '')
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
    mode '0755'
    owner 'ubuntu'
    group 'ubuntu'
end

# Create Volume for nginx letsencrypt container!
execute 'docker_nginx_volume' do
    command 'sudo docker volume create --driver local nginx_volume'
end

execute 'docker_nginx_rm' do
    command "sudo docker rm nginx --force"
    only_if 'sudo docker image ls | grep -E linuxserver/letsencrypt'
    action :run
end

# Start Nginx Container w. Automatic SSL from Certbot
execute 'docker_nginx_start' do
    command "docker run \
    --cap-add=NET_ADMIN \
    --name nginx \
    -p 443:443 \
    -p 80:80 \
    --detach \
    -e EMAIL=dmw2151@columbia.edu \
    -e URL=notebooks.maphub.dev \
    -v nginx_volume:/config \
    --network host \
    --mount type=bind,src=/etc/nginx/nginx.conf,dst=/config/nginx/site-confs/default \
    linuxserver/swag"
    action :run
end