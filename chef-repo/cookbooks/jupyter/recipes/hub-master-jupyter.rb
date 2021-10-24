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

cookbook_file '/etc/nginx/nginx.conf' do
    source 'nginx/nginx.conf'
    owner 'ubuntu'
    group 'ubuntu'
    action :create
    notifies :run, 'execute[docker-nginx-restart]'
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
    aws ecr get-login-password --region $AWS__REGION | sudo docker login --username AWS --password-stdin $AWS__ACCOUNT_ID.dkr.ecr.$AWS__REGION.amazonaws.com
    "
    action :run
end

execute 'docker-pull' do 
    command "
    export AWS__REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
    export AWS__ACCOUNT_ID=$(aws sts get-caller-identity | jq '.Account' -r)
    sudo docker pull $AWS__ACCOUNT_ID.dkr.ecr.$AWS__REGION.amazonaws.com/jupyterhubserver:latest
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

## Push Jupyter Files as part of cookbook...
cookbook_file '/etc/jupyterhub/jupyterhub_config.py' do
    source 'hub/jupyterhub_config.py'
    action :create
    notifies :run, 'execute[docker-nginx-restart]'
end

cookbook_file '/etc/jupyterhub/dns.env' do
    source 'hub/dns.env'
    action :create
    notifies :run, 'execute[docker-nginx-restart]'
end

cookbook_file '/etc/jupyterhub/hub.env' do
    source 'hub/hub.env'
    action :create
    notifies :run, 'execute[docker-hub-start]'
end

# [WARN] image XXXX.dkr.ecr.region.amazonaws.com/hub:latest could not be accessed on a registry 
# to record its digest. Each node will access XXXX.dkr.ecr.region.amazonaws.com/hub:latest 
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
        --env-file /etc/jupyterhub/hub.env \
        --constraint 'node.role == manager' \
        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
        --mount type=bind,src=/etc/jupyterhub,dst=/srv/jupyterhub \
        --mount type=bind,src=/efs/hub,dst=/home/jovyan \
        $AWS__ACCOUNT_ID.dkr.ecr.$AWS__REGION.amazonaws.com/jupyterhubserver
    "
    action :run
    not_if 'sudo docker service ls | grep -E jupyterhubserver'
    notifies :run, 'execute[docker-nginx-restart]'
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
        --env-file /etc/jupyterhub/dns.env \
        -v nginx_volume:/config \
        --network hub \
        --mount type=bind,src=/etc/nginx/nginx.conf,dst=/config/nginx/site-confs/default \
        linuxserver/swag
    "
    action :run
    not_if 'sudo docker ps | grep -E nginx'
end

# [TODO] Need to check that this is stable w.o a restart...
execute 'docker-nginx-restart' do
    command "sudo docker restart nginx"
    action :run
end