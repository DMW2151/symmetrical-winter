#! /bin/bash

# Update Apt
sudo apt-get update &&\
    sudo apt-get -y upgrade

# Create Docker Network - JupyterHub Overlay
sudo docker network create \
    --driver overlay \
    --attachable jupyterhub

# Touch
sudo mkdir -p /etc/jupyterhub/hub

# Launch Docker Service - JupyterHub Main Server
# NOTE - Create Custom Container!
sudo docker service create \
  --name jupyterhubserver \
  --network host \
  --constraint 'node.role == manager' \
  --mount type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
  --mount src=nfsvolume,dst=/efs \
  --detach=true \
  jupyterhub/jupyterhub:1.4.2
