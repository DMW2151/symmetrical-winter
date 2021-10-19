#! /bin/sh

sudo apt update &&\
sudo apt install -y \
    docker \
    docker.io

sudo docker swarm init --advertise-addr `(hostname -I | awk '{print $1}')`

token=`(sudo docker swarm join-token --quiet manager)`