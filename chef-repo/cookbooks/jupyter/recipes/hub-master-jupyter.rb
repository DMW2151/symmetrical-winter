#
# Cookbook:: jupyter
# Recipe:: Hub Master Install Nginx
#
# Copyright:: 2021, The Authors, All Rights Reserved.

# Create Mount Directories...
directory '/etc/jupyterhub/hub' do
    owner 'ubuntu'
    group 'ubuntu'
    mode '0755'
    recursive true
    action :create
end

# [TODO]: Test Host vs Overlay Network
execute 'create_network_overlay' do
    command "sudo docker network create \
        --driver overlay \
        --attachable jupyterhub"
    action :run
    not_if 'sudo docker network ls | grep -E  jupyterhub'
end

execute 'docker-start' do
    command "sudo docker service create \
        --name jupyterhubserver \
        --network host \
        --constraint 'node.role == manager' \
        --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
        --mount src=nfsvolume,dst=/efs \
        --detach=true \
        jupyterhub/jupyterhub:1.4.2"
    action :run
    not_if 'sudo docker service ls | grep -E jupyterhubserver'
end
