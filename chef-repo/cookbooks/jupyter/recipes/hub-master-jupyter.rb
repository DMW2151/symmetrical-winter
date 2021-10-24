#
# Cookbook:: jupyter
# Recipe:: Hub Master Install Nginx
#
# Copyright:: 2021, The Authors, All Rights Reserved.

# Create Mount Directories for JuyterHub Configs
directory '/etc/jupyterhub/' do
    owner 'ubuntu'
    group 'ubuntu'
    mode '0755'
    recursive true
    action :create
end

# Create Mount Directories for Nginx Configs
directory '/etc/nginx/' do
    owner 'ubuntu'
    group 'ubuntu'
    mode '0755'
    recursive true
    action :create
    not_if ' ls /etc/nginx | grep -E *'
end


# [TODO] - Tidy - Write in the Nginx Config ==> 
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
            proxy_pass http://jupyterhubserver:8000;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-NginX-Proxy true;
        }

        location ~* /(user/[^/]*)/(api/kernels/[^/]+/channels|terminals/websocket)/? {
            proxy_pass http://jupyterhubserver:8000;

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
    notifies :run, 'execute[docker-hub-start]'
end


# [TODO]: Test Host vs Overlay Network - May not Need Designated Network!
execute 'create_network_overlay' do
    command "
        sudo docker network create \
            --driver overlay \
            --attachable hub
    "
    action :run
    not_if 'sudo docker network ls | grep -E  hub'
end


execute 'ecr_repo_login' do
    command "
    export AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
    export AWS__ACCOUNT_ID=$(aws sts get-caller-identity | jq '.Account' -r)
    aws ecr get-login-password --region $AWS__REGION | sudo docker login --username AWS --password-stdin $AWS__ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
    "
    action :run
end

execute 'docker-pull' do 
    command "
    export AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
    export AWS__ACCOUNT_ID=$(aws sts get-caller-identity | jq '.Account' -r)
    sudo docker pull $AWS__ACCOUNT_ID.dkr.ecr.$AWS__REGION.amazonaws.com/hub:latest
    "
    action :run
end

# Create Volume for nginx letsencrypt container if & only if there isn't a nginx volume available
execute 'docker_nginx_volume' do
    command "
        sudo docker volume create \
            --driver local nginx_volume
    "
    only_if 'sudo docker volume ls | grep -E nginx_volume'
    action :run
end


# [WARN] image XXXX.dkr.ecr.us-east-1.amazonaws.com/hub:latest could not be accessed on a registry 
# to record its digest. Each node will access XXXX.dkr.ecr.us-east-1.amazonaws.com/hub:latest 
# independently, possibly leading to different nodes running different versions of the image.
execute 'docker-hub-start' do
    command "
    export AWS__ACCOUNT_ID=$(aws sts get-caller-identity | jq '.Account' -r)
    export AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
    sudo docker service create \
        --name jupyterhubserver \
        --detach \
        -p 8000:8000 \
        --network hub \
        --constraint 'node.role == manager' \
        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
        --mount type=bind,src=/etc/jupyterhub,dst=/srv/jupyterhub \
        --mount type=bind,src=/efs/hub,dst=/home/jovyan \
        $AWS__ACCOUNT_ID.dkr.ecr.$AWS__REGION.amazonaws.com/hub
    "
    action :run
    not_if 'sudo docker service ls | grep -E jupyterhubserver'
    notifies :run, 'execute[docker-hub-start]'
end

# Start Nginx Container w. Automatic SSL from Certbot
execute 'docker-nginx-start' do
    command "
    sudo docker run \
        --cap-add=NET_ADMIN \
        --name nginx \
        -p 443:443 \
        -p 80:80 \
        --detach \
        --restart always\
        -e EMAIL=dmw2151@columbia.edu \
        -e URL=notebooks.maphub.dev \
        -v nginx_volume:/config \
        --network hub \
        --mount type=bind,src=/etc/nginx/nginx.conf,dst=/config/nginx/site-confs/default \
        linuxserver/swag
    "
    action :run
    not_if 'sudo docker service ls | grep -E nginx'
end